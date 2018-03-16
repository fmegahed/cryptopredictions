# Data wrangling routines
coins <- c("BTC","ETH","XRP","BCH","LTC")
library(tidyverse)
library(anytime)      # use anytime() for converting UTC to Date-Time form

#### CryptoCompare Hourly Prices ####
load("~/GitHub/cryptopredictions/Code/DataCollection/Data/HourlyPrices-28-2-2018.RData") # only one dataset to load
datHP <- results; rm(results)
for (i in 1:length(coins)){
  datHP[[i]] <- datHP[[i]] %>% 
    .[(!rowSums(.[ ,2:7]) == 0), ] %>%  # remove zeroed rows (only necessary for BCH)
    mutate(Coin = coins[i]) %>%         # add coin names to list elements
    mutate(time = anytime(time))        # convert UTC to Date-Time form
}

#### GitHub coin version & posting dates ####
fpath <- "~/GitHub/cryptopredictions/Code/DataCollection/Data/"
dir <- paste0(fpath,
              c("BitcoinGitHub-26-2-2018.RData",
                "EthereumGitHub-2018-03-15.RData"))
datVer <- {}
for (i in 1:length(dir)) {
  load(dir[i])
  if (i == 1) datVer[[i]] <- unverified.btc
  if (i == 2) datVer[[i]] <- release.ethereum
  colnames(datVer[[i]]) <- c('time', 'version')    # rename columns
  datVer[[i]] <- datVer[[i]] %>%
    if (i==1){ # Bitcoin, to clean up end of string
      datVer[[i]] <- datVer[[i]] %>% 
        mutate(time = anytime(str_sub(as.character(time), 2, -6))) %>%  # clean-up date
        arrange(time) %>%                                               # sort decending to match other datasets
        mutate(timeH = lubridate::ceiling_date(time, unit = 'hours'))   # round times up to nearest hour
    } else {
      datVer[[i]] <- datVer[[i]] %>% 
        mutate(time = anytime(time)) %>%  # clean-up date
        arrange(time) %>%                                               # sort decending to match other datasets
        mutate(timeH = lubridate::ceiling_date(time, unit = 'hours'))
    }
}

#### Combine datasets ####
datComb <- {}
# for (i in 1:length(coins)) {
for (i in match(c('BTC', 'ETH'), coins)) { #match as index is temporary until all data collected
  idc <- data.frame(which(outer(datHP[[i]]$time, 
                                datVer[[i]]$timeH, '=='),
                          arr.ind = T))                   # get indices matching dates b/w datasets
  colnames(idc) = c('price', 'ver')
  nRow <- datHP[[i]] %>% nrow
  repTimes <- nRow %>% c(idc$price, .) %>% diff
  repTimes[1] <- repTimes[1] + 1                          # replace first instance, gone due to diff()
  repIdc <- rep(idc$ver, repTimes)                        # create indices for repeating versions
  datComb[[i]] <- datHP[[i]] %>% mutate(version = NA)     # allocate space for partial replacement 
  datComb[[i]]$version[idc$price[1]:nRow] = as.character(datVer[[i]]$version[repIdc])
} 

#### Stack modified list elements for currently scraped coins ####
datFinal <- datComb %>%
  reduce(function(df1, df2) full_join(df1, df2,
                                      by = names(.[[1]])))