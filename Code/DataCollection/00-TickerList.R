#_______________________________Clear Screen and Environment
cat("\014") # clear screen
rm(list=ls()) # clear global environment
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # set wd to current file location
set.seed(1018) # pick an arbitrary seed number; this number corresponded to date of analysis
# Seed number to be fixed to allow for replicating our analysis

#________________________________ Installing Packages________________________
install.packages("pacman")
library(pacman)
p_load(stocks, quantmod, dplyr, rvest, Quandl)

#__________________________________________________________________________
# Top 10 cryptos by volume as of 3:48 pm Eastern Time on 10/18/2018
# From https://coinmarketcap.com/
# Not all of these can be traded with a dollar. If there is not direct purchase
# with USD; the price of BTC is used for conversion
top_crypto_tickers <- getSymbols(c("BTC-USD","ETH-USD","XRP-USD","BCH-USD","EOS-USD",
             "XLM-USD", "LTC-USD", "USDT-USD", "ADA-USD", "XMR-USD",
             "TRX-USD")) # included 11 since USDT-USD is not volatile at all
#Note:
# We also got the data for their tickers based on the previous line of code
# and they are stored with the names of the ticker pairs


#__________________________________________________________________________
# US Economic Indicators based on Trading Economics
# Running this code; we got 198 names of U.S. Economic Indicators
# We need to scrape their data
dataholder <- read_html("https://tradingeconomics.com/united-states/indicators") %>% 
              html_node("#ctl00_ContentPlaceHolder1_ctl00_Panel1 > div:nth-child(3) > table") %>% 
              html_table() %>% subset(Last != "Last")
dataholder <- dataholder[,-7]
dataholder2 <- read_html("https://tradingeconomics.com/united-states/indicators") %>% 
                html_node("#ctl00_ContentPlaceHolder1_ctl00_Panel1 > div:nth-child(1) > table") %>% 
                html_table()
dataholder2 <- dataholder2[-1,-7]
colnames(dataholder)[1] <- "Index"
colnames(dataholder2) <- colnames(dataholder)
macroeconomic_names <- rbind(dataholder2, dataholder)
rm(dataholder, dataholder2) # Data Cleaning; we do not need to store them


#__________________________________________________________________________
# U.S. Stocks (Sampled from AMEX, NYSE, NASDAQ)
# CSVs obtained from: https://www.nasdaq.com/screening/company-list.aspx
amex_sample <- read.csv("Data/amex-companylist.csv") %>% sample_frac(0.1)
nyse_sample <- read.csv("Data/nyse-companylist.csv") %>% sample_frac(0.1)
nasdaq_sample <- read.csv("Data/nasdaq-companylist.csv") %>% sample_frac(0.1)
stocks_to_be_tracked <- rbind(amex_sample, nasdaq_sample, nyse_sample)
rm(amex_sample, nyse_sample, nasdaq_sample)


#__________________________________________________________________________
# Getting Currency Pairs
majors <- read_html("http://www.sharptrader.com/new-to-trading/forex/majors-minors-exotic-currency-pairs/") %>% 
          html_node("#content > div:nth-child(4) > div > div > div.wpb_text_column.wpb_content_element > div > div > table") %>% 
          html_table()
colnames(majors) <- majors[1,]
majors <- majors[-1,]

minors <- read_html("http://www.sharptrader.com/new-to-trading/forex/majors-minors-exotic-currency-pairs/") %>% 
          html_node("#content > div:nth-child(7) > div > div > div.wpb_text_column.wpb_content_element > div > div > table") %>% 
          html_table()
colnames(minors) <- minors[1,]
minors <- minors[-1,]

exotics <- read_html("http://www.sharptrader.com/new-to-trading/forex/majors-minors-exotic-currency-pairs/") %>% 
           html_node("#content > div:nth-child(10) > div > div > div.wpb_text_column.wpb_content_element > div > div > table") %>% 
           html_table()
colnames(exotics) <- exotics[1,]
exotics <- exotics[-1,]

currency_pairs <- rbind(majors, minors, exotics) # Combining them in one df
rm(majors,minors, exotics)

# Note:
# Some if not all currencies can be obtained like this
getSymbols("USD/EUR", src="oanda") # this will create a df called USDEUR


#__________________________________________________________________________
# Commodities site reached from: https://www.businessinsider.com/the-18-most-traded-goods-in-the-world-2018-2
commodity.names <- read_html("http://www.visualcapitalist.com/top-importers-exporters-worlds-18-traded-goods/") %>% 
                   html_node("#tablepress-184-no-4") %>% html_table()

