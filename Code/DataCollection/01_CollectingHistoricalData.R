# This Code is Written to Utilize the Quantmod Package to extract
# the top 5 cryptocurrencies by market cap

# The selection was based on 

library(quantmod)
getSymbols(c("BTC-USD","ETH-USD","XRP-USD","BCH-USD","LTC-USD")) 
