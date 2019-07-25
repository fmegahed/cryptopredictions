# functions used to pull data using SQL (db_pull) and apply forecasting method
# to this selected data (fcaster)

# try <- db_pull(con, 'stocks', 'nasdaq', 'DWAQ')
db_pull <- function(con, type, subset1 = NULL, subset2 = NULL){
  # Create remote data base objects
  dbo <- tbl(con, type)
  # process request
  if(type=='stocks'){
    query <- dbo %>%
      filter(id %like% paste0('%', subset1, '%')) %>% 
      filter(symbol %like% paste0('%', subset2, '%')) %>%
      #select(date, close, id, symbol) %>%
      arrange(date) %>% 
      as_tibble
  }
  if(type=='cryptos'){
    query <- dbo %>%
      filter(symbol %like% paste0('%', subset1, '%')) %>%
      #select(date, close, symbol) %>%
      arrange(date) %>% 
      as_tibble
  }
  
  
  require(anytime, quietly = T)
  query <- mutate(query, date = date %>% anytime)# %>% as.Date)
  detach(package:anytime, unload = T)
  
  return(query)
}

reTurns <- function(x) {
  return((x - lag(x))/lag(x))
}

fcaster <- function(query, col2Use = 'return', h = 1,
                    modelMethod = 'auto.arima', evalMethod = 'cv',
                    trainStart, splitDate, testEnd){
  
  if(col2Use=='return'){
    query <- mutate(query, return = reTurns(close))
    query <- query[-1, ] # if return, 1st row NA, so drop
  }
  
  # split train/test sets & rename chosen y column as 'ts' for uniformity hereafter
  if(evalMethod=='split'){
    train <- query[ , c('date', col2Use)] %>%
      filter(date <= splitDate)
    names(train) <- c('date', 'ts')
    test <- query[, c('date', col2Use)] %>%
      filter(date > splitDate)
    names(test) <- c('date', 'ts')
    focus <- dim(train)[1]
  }
  
  # Setup f_n for t.s. cross validate routine
  require(forecast)
  if(evalMethod=='cv'){
    subQuery <- query %>%
      filter(date >= trainStart, date <= testEnd)# %>% 
      #select(date, col2Use) 
    focus <- which(subQuery$date==splitDate)
    #if(length(focus)>1)
  }
  
  if(modelMethod=='auto.arima'){
    fautoarima <- function(x, h){forecast(auto.arima(x, seasonal = F, num.cores = 3), h)}
    innos <- tsCV(ts(subQuery[ , col2Use]),
                  fautoarima, h = h, initial = focus) %>% as.numeric
    errors = innos[!is.na(innos)]
    if(h==1) {
      out <- tibble(RMSE = mean(errors^2) %>% sqrt,
                    MAPE = mean(abs(errors / (errors + 
                                              unlist(subQuery[ , col2Use])[!is.na(innos)] +
                                              1e-10)
                                    )
                                ),
                    errors = list(errors)
                    )
                     
    } else {
      out <- tibble(RMSE = colMeans(errors^2) %>% sqrt,
                    MAPE = colMeans(abs(errors / (errors + 
                                                    unlist(subQuery[ , col2Use])[!is.na(innos)] +
                                                    1e-10)
                                        )
                                    ),
                    errors = list(errors)
                    )
    }
  }
  return(out)
  #detach(package:forecast, unload = T)
}
