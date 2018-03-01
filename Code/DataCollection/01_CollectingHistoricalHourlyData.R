# Code: Written to Extract Hourly Prices and Volumes for our five cryptocurrencies
# Using the Crypto Compare API: https://min-api.cryptocompare.com/

# Loading Needed Libraries
library(jsonlite)


# API Inputs
coins <- c("BTC","ETH","XRP","BCH","LTC") # he cryptocurrency symbol of interest [Max length: 10]
measured.in <- "USD" # The currency symbol to convert into [Max length: 10]
exchange <- "CCCAGG" # Default (thus, not used): CCCAG, which is Cryptocurrency compare's aggregation of exchanges
baseurl <- "https://min-api.cryptocompare.com/data/histohour?fsym="
num.data.points <- as.character(2000) # We were limited to 2001 when I tried it on 2/28/18
# Creating the inputs needed for the for loop to extract the data
first.Ts.time <- as.numeric(as.POSIXct("2016-01-01 0:00", tz="GMT"))+ (3600*2000)
TimeTs <- seq(first.Ts.time,1519858800,(3600*2000)) # Unix Time Stamps; second input is 23 pm 2-28-2018 UTC;
# and third input is to incrument it by 2000 hours)
TimeTs.include.current.time <- c(TimeTs,1519858800)

# ----------------------Two Nested for Loops for extracting the data needed-----------------------------------
# Outer loop is for each coin and the
# inner loop is to iterate through the API so we have the data from January 1, 2016 to Feb 28, 2018 (UTC Times)
results <- list() # initializing the results list (made of five sub lists; one for each coin)
for (counter in 1:length(coins)) {
  data.holder <- {} # place holder for data, which we will overwrite
  for (id in 1:length(TimeTs.include.current.time)) {
    api.call <- paste(baseurl,coins[counter],"&tsym=",measured.in,"&limit=",
                      num.data.points,"&aggregate=1&toTs=",
                      TimeTs.include.current.time[id],sep="") # api call with prespecified parameters
    data.holder <- rbind(data.holder,fromJSON(api.call)$Data) # R Binding the data (to create one large df per coin)
    Sys.sleep(1) # Pause 1 second
  }
  results[[counter]] <- data.holder # A list of results time, close, high, open, volume
}
# Checking the time of the last observations
print(as.POSIXct(data.holder$time[nrow(data.holder)],origin="1970-01-01"))
# investigating how the API handled the Release of BCH (i.e. values before the release on August 1, 2017)
table(results[[4]][1:100,'close']) # We know for sure that the first 100 values should either be NA or zeros.
# Output showed that they were treated as zeros by the API
save(results,
     file="C:/Users/megahefm/Google Drive/Miami/Research/2018/cryptopredictions/Code/DataCollection/Data/HourlyPrices-28-2-2018.RData")