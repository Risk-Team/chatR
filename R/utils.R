#' Date selection
#'
#' automatically select common dates among C4R objects
#' @export
#' @importFrom transformeR bindGrid subsetDimension
#' @import dplyr
#' @param data list containing C4R objects, which are the outputs of the loadGridata function
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

#' Climate change signal agreement
#'
#' function to find models members sign agreement. Input is a 3d array with first dimension being members


sign.prop <- function(array3d) {
  message("first dimension needs to be model member")

  if (length(dim(cl4.object$Data)) != 3)
    stop(
      "Your data needs to be a 3d array, with first dimension being model member. Check dimension"
    )
  find.sign = function(x) {
    signs = c(length(x[x < 0]) / length(x),
              length(x[x == 0]) / length(x),
              length(x[x > 0]) / length(x))
    names(signs) = c(-1, 0, 1)
    signs
  }

  #apply the find.sign function to the array
  array1_sign = apply(array3d, c(2, 3), find.sign)

  #####
  #create a function to find out which sign is the highest proportion, if there are ties, return NA
  find.most.sign = function(x) {
    if (length(x[x == max(x)]) == 1) {
      as.numeric(names(x[x == max(x)])) * max(x) #use this line if interested in sign of change with most agreement and proportion of agreement
    } else{
      0
    }
  }

  #apply the find.most.sign function to the array
  array1_most_sign = apply(array1_sign, c(2, 3), find.most.sign)

  return(array1_most_sign)

}

#' Date selection
#'
#' automatically select common dates among C4R objects

find.agreement = function(x, threshold) {
  #calculate proportion of models predicting each sign of change (negative(-1), no change(0), positive(+1))
  sign.proportion = c(length(x[x < 0]) / length(x),
                      length(x[x == 0]) / length(x),
                      length(x[x > 0]) / length(x))
  names(sign.proportion) = c(-1, 0, 1)
  #compare the set threshold to the maximum proportion of models agreeing on any one sign of change
  #if the max proportion is higher than threshold, return 1 (meaning there is agreement in signs among model)
  #otherwise return 0 (no agreement meeting the set threshold)
  if (max(sign.proportion) > threshold) {
    return(1)
  } else{
    return(0)
  }
}

agreement = function(array3d, threshold) {
  array1_agreement = apply(array3d, c(2, 3), find.agreement, threshold)
}

