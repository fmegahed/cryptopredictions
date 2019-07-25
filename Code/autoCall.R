require(extrafont)
# Assuming R Studio as IDE, auto locate this script's working directory via R studio API
loadfonts(device = "win") # To use specific fonts for windows
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd('..') # set working directory just above current folder
detach(package:extrafont, unload = T)

library(jsonlite)
# API Inputs
coins <- c("BTC","ETH","XRP","BCH","LTC") # crypto symbol [Max length 10]
measured.in <- "USD" # currency to convert to [Max length 10]
num.data.points <- "1"
baseurl <- "https://min-api.cryptocompare.com/data/histohour?fsym="

library(tidyverse)
out <- tibble()
for (t in 1:(24*365)){  # will run for a year
  #start = Sys.time()
  for (c in 1:length(coins)){
    temp <- fromJSON(paste0(baseurl,
                            coins[c],
                            "&tsym=", measured.in,
                            "&limit=", num.data.points))
    out <- bind_cols(symbol = coins[c], temp$Data[2, ]) %>% bind_rows(out)
    saveRDS(out, 'Data/out.RDS')
  }
  #print(Sys.time() - start)
  Sys.sleep(60*60) # enter time in seconds to pause before re-running loop(s)
}


# To retrieve combined data and view it in sorted order by symbol 
# yep=readRDS('Data/out.rds')
# yep %>% arrange(symbol, time) %>% View