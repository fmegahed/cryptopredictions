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

# Data step ----
nasdaq <- readRDS('Data/nasdaq.RDS')
nyse <- readRDS('Data/nyse.RDS')
sse <- readRDS('Data/sse.RDS')
tse <- readRDS('Data/tse.RDS')

# combine stocks data into one data set
stocks <- bind_rows(list(nasdaq = nasdaq, nyse = nyse, sse = sse, tse = tse),
                    .id = 'id')
head(stocks)
#saveRDS(stocks, 'Data/stocks.RDS')
#dbWriteTable(con, 'stocks', stocks) # run when needed

# insert names column into cryptocurrency data set using cryptotable file
cryps <- readRDS('Data/crypto.RDS')
crypName <- readRDS('Data/cryptotable.RDS') %>% select(Name)

for (i in 1:length(cryps)){
  cryps[[i]] <- c(cryps[[i]], name = list(rep(crypName[i,], length(cryps[[1]]$time))))
}
cryps <- bind_rows(cryps)
cryps <- cryps %>%
  mutate(date = time %>% as.POSIXct(origin = '1970-01-01'),
         volume = volumeto - volumefrom) %>% 
  select(symbol = name, date, open, high, low, close, volume) %>% 
  arrange(symbol, date) %>% 
  filter(rowSums(.[,3:7])!=0) %>% 
  mutate(symbol = str_extract(symbol,'^.*[^\\n]')) %>% 
  unique
head(cryps)
#saveRDS(cryps, 'Data/cryptos.RDS')
#dbWriteTable(con, 'cryptos', cryps, overwrite=T) # run when needed

# Reference code for working with MS SQL Database ----
#dbListObjects(con)
#dbWriteTable(con, 'crashData2016', cdat)

# example write/delete df as table to db
#deleteMe <- data_frame(trial = 1:3, who = c("Mo", "Curly", "Larry"))
#dbWriteTable(con, 'deleteMe', deleteMe)
#dbExistsTable(con, "deleteMe")
#dbRemoveTable(con, 'deleteMe')

# Other functions
#res <- dbSendQuery()         # use to pull using blocks rather than all at once
#dbFetch(res)                 # run query
#dbClearResult(res)           # clear out object that holds the query

dbDisconnect(con)
