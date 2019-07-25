require(tidyverse, quietly = T)
require(extrafont)
# Assuming R Studio as IDE, auto locate this script's working directory via R studio API
loadfonts(device = "win") # To use specific fonts for windows
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('..') # set working directory just above current folder
detach(package:extrafont, unload = T)

# Defining credentials for DB connection ----
svr = "fsbsql8.it.muohio.edu"
dbn = "KwonwTransInfo"
uid = "leonarr"

require(dbplyr)
require(odbc)
# Connect to FSB SQL Data Base server
con <- dbConnect(odbc(),
                 Driver = "SQL Server",
                 Server = svr,
                 Database = dbn,
                 UID = uid,
                 PWD = rstudioapi::askForPassword("my-password"),
                 Port = 1433)

#rmse <- vector("numeric", 100)
tsType = 'cryptos'
modelMethod = 'auto.arima'
evalMethod = 'cv'
h = 1

source('Code/fcaster.R')
if (tsType == 'cryptos'){
  db_pull(con, tsType) %>%
    count(symbol) %>%
    arrange(desc(n)) %>%
    filter(n >= (24*30*4)) -> symCounts # only using currencies > 4 months in
}                                       #      length so w/ 1 month to test we
                                        #      have at least 3 months to train
symbols <- symCounts$symbol

#s=9
metrics <- tibble()
for (s in 1:10){#length(symbols)){
  start <- Sys.time()
  db_pull(con, tsType, symbols[s]) %>% 
    select(date, close) %>% 
    #group_by(date) %>%
    #summarise(close = mean(close)) %>%   # compress hr2hr into day2day
    arrange(date) -> ts
  #ungroup(ts)
  #trainStart = ts$date[1]
  trainStart = ts$date[nrow(ts) - (30*5*24)] # start training 4 months prior to training
  splitDate = ts$date[nrow(ts) - (30*1*24)]  # start testing w/ 1 month remaining
  testEnd = ts$date[nrow(ts)]
  # library(lubridate)
  # query = ts %>%
  #   group_by(year(date), month(date), day(date)) %>%
  #   summarize(close=mean(close))
  # col2Use = 'return'; h = 1
  # modelMethod = 'auto.arima'; evalMethod = 'cv';
  # trainStart='2013-04-28'
  # trainStart = '2016-01-01; splitDate='2018-02-06'; testEnd='2018-02-20';
  metrics <- c(data = tsType, symbol = symbols[s], step = h,
               trainLength = splitDate - trainStart,
               testLength = testEnd - splitDate,
               modelMethod = modelMethod, evalMethod = evalMethod,
               col2Use = col2Use,
               fcaster(ts, col2Use = 'return', h,
                     modelMethod = modelMethod, evalMethod = evalMethod,
                     trainStart = trainStart,
                     splitDate = splitDate,
                     testEnd = testEnd)) %>% bind_rows(metrics)
  time <- Sys.time() - start
  print(time)
}

