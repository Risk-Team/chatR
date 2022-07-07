common_dates <- function(data) {
  # list of models
  dates.all = c()

  for (imodel in 1:length(data)) {
    dates.all = c(dates.all, substr(data[[imodel]]$Dates$start, 1, 10))
  }

  dates.common = substr(data[[1]]$Dates$start, 1, 10)
  for (imodel in 2:length(data)) {
    aux = intersect(substr(data[[imodel - 1]]$Dates$start, 1, 10),
                    substr(data[[imodel]]$Dates$start, 1, 10))
    dates.common = intersect(dates.common, aux)
  }
  for (imodel in 1:length(data)) {
    ind = which(!is.na(match(
      substr(data[[imodel]]$Dates$start, 1, 10), dates.common
    )))
    data[[imodel]] = subsetDimension(data[[imodel]], dimension = "time", indices = ind)
  }

  return(bindGrid(data, dimension = "member"))

}
