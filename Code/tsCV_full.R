tsCV_full <- function (y, forecastfunction, h = 1, window = NULL, xreg = NULL, 
          initial = 0, ...) 
{
  y <- as.ts(y)
  n <- length(y)
  #e <- ts(matrix(NA_real_, nrow = n, ncol = h))
  
  fcOUT <- {} # create basket
  
  if (initial >= n) 
    stop("initial period too long")
  #tsp(e) <- tsp(y)
  if (!is.null(xreg)) {
    xreg <- ts(as.matrix(xreg))
    tsp(xreg) <- tsp(y)
  }
  if (is.null(window)) 
    indx <- seq(1 + initial, n - 1L)
  else indx <- seq(window + initial, n - 1L, by = 1L)
  for (i in indx) {
    y_subset <- subset(y, start = ifelse(is.null(window), 
                                         1L, ifelse(i - window >= 0L, i - window + 1L, stop("small window"))), 
                       end = i)
    if (is.null(xreg)) {
      fc <- try(suppressWarnings(forecastfunction(y_subset, 
                                                  h = h, ...)), silent = TRUE)
    }
    else {
      xreg_subset <- as.matrix(subset(xreg, start = ifelse(is.null(window), 
                                                           1L, ifelse(i - window >= 0L, i - window + 1L, 
                                                                      stop("small window")))))
      fc <- try(suppressWarnings(forecastfunction(y_subset, 
                                                  h = h, xreg = xreg_subset, ...)), silent = TRUE)
    }
    if (!is.element("try-error", class(fc))) {
      #e[i, ] <- y[i + (1:h)] - fc$mean
      fcOUT[[i]] <- fc
    }
  }
  if (h == 1) {
    #return(e[, 1L])
    return(fcOUT)
  }
  else {
    #colnames(e) <- paste("h=", 1:h, sep = "")
    #return(e)
    return(fcOUT)
  }
}