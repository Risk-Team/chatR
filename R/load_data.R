#' Automatically load climate models (netCDF/NcML) in a tidy format.
#' @export
#' @import stringr
#' @import purrr
#' @importFrom loadeR loadGridData
#' @import furrr
#' @import dplyr
#' @importFrom sp proj4string
#' @importFrom raster raster getData
#'
#' @param path.to.rcps Absolute path to the directory containing the RCPs/SSPs folders and historical simulations. For example,
#' home/user/data/. data would contain subfolders with the climate models. Historical simulations have to be contained in a folder called historical
#' @param country A character string, in english, indicating the country of interest. To select a bounding box,
#' set country to NULL and define arguments xlim and ylim
#' @param variable  A character string indicating the variable to be loaded
#' @param xlim Vector of length = 2, with minimum and maximum longitude coordinates, in decimal degrees, of the bounding box selected.
#' @param ylim Same as xlim, but for the selection of the latitudinal range.
#' @param path.to.obs Default to NULL, if not, indicate the absolute path to the directory containing a reanalysis dataset, for example W5E5 or ERA5.
#' @param years Numerical range, years to select. Default (NULL)
#' @param n.cores Integer, number of cores to use in parallel processing
#' @param buffer Integer, default to zero. Buffer to add when selecting a country or a bounding box
#' @return Tibble with list column
#' @examples
#'fpath <- system.file("extdata/", package="CHAT")
#' exmp <- load_data(country = "Moldova", variable="hurs", n.cores=6,
#'               path.to.rcps = fpath)




load_data <- function(
                      path.to.rcps,
                      country,
                      variable,
                      xlim=NULL,
                      ylim=NULL,
                      years = 2010:2099,
                      path.to.obs=NULL,
                      n.cores,
                      buffer=0) {

options(warn=-1)

if(str_detect(path.to.rcps, "^\\.")) stop("please use absolute paths")

if (!is.null(country) & !is.null(xlim)) {
  stop("Either select a country or a region of interest, not both")
} else {
  country_shp = if (!is.null(country))
    getData("GADM", country = country, level = 1)
  else
    as(extent(min(xlim), max(xlim), min(ylim), max(ylim)), "SpatialPolygons")
  proj4string(country_shp) = "+proj=longlat +datum=WGS84 +no_defs"
  xlim <-
    c(round(country_shp@bbox[1, 1] - buffer),
      round(country_shp@bbox[1, 2] + buffer))  # longitude boundaries for the region of seasonerest
  ylim <-
    c(round(country_shp@bbox[2, 1] - buffer),
      # latitude boundaries for the region of seasonerest
      round(country_shp@bbox[2, 2] + buffer))
}

range.x <- max(xlim) - min(xlim)
range.y <-  max(ylim) - min(ylim)

options(warn=1)

if(range.x > 10 | range.y > 10) warning("Please make sure your bounding box is not too big. You might run out of memory")

if(!is.null(path.to.obs)) {

  obs.file <- list.files(path.to.obs, full.names = TRUE)
  if (length(obs.file) > 1) stop("Please check your directory. More than 1 file are present")

  dataInventory(obs.file)


} else {warning("if you do not specify a reanalysis/observational gridded dataset, bias-correction cannot be performed \n")}

if (!any(str_detect(list.files(path.to.rcps), "stor"))) {

  stop("Please add the historical simulations rounds of your model. The folder name needs to contain the letters stor")
}

if (length(list.files(path.to.rcps)) >= 3) message("Your directory contains the following folders: \n", paste(list.files(path.to.rcps), "\n"), "all files within the listed folders will be uploaded \n")

# building the dataset

files <- list.files(path.to.rcps, full.names = TRUE) %>%
  map(., ~ list.files(.x, full.names = TRUE))

future::plan(
  list(
    future::tweak(
      future::multisession,
      workers = length(list.files(path.to.rcps))),
    future::tweak(
      future::multisession,
      workers = n.cores - length(list.files(path.to.rcps)))
  )
)

message(paste(Sys.time(), "Data loading \n"))

message("Considered time frame for historical simulation is 1976:2005.
Default time frame for projections is 2010:2099.
Ensure this matches your data \n")

df1 <-
  tibble(
    path = files,
    RCP =list.files(path.to.rcps)
  ) %>%
  mutate(
    models = future_map(path,  ~ future_map(.x, function(x)  {

      if (str_detect(x, "historical")) {

        suppressMessages(
          loadGridData(
            dataset = x,
            var = variable,
            years = 1976:2005,
            lonLim = xlim,
            latLim = ylim,
            season = 1:12
          )
        )

      }

      else {

        suppressMessages(
          loadGridData(
            dataset = x,
            var = variable,
            years = years,
            lonLim = xlim,
            latLim = ylim,
            season = 1:12
          )
        )

      }

    })))

message(paste(Sys.time(), "Done \n"))

message(paste(Sys.time(), "Aggregating members \n"))

df2 <- df1 %>%
  mutate(models_mbrs = lapply(models, function(x)
    common_dates(x))) %>%
  {if (!is.null(path.to.obs)) {

    mutate(., obs = list(suppressMessages(
      loadGridData(
        obs.file,
        var = variable,
        years = 1981:2010,
        lonLim = xlim,
        latLim = ylim,
        season = 1:12
      )
    )))

  } else {.}} %>%
  select(-models)

models <- df1 %>%
  select(path)

message(paste(Sys.time(), "Done"))
rm(df1)
gc()

return(list(df2, country_shp, models, "C4R.dataframe"))

} # end of function
