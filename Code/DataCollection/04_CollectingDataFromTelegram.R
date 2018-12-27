# This is a script written to collect relevant Telegram Messages from
# the following channels:
# (A) Bitcoin (which as of 3/26/2018 - 9:25 am had 12,910 subscribers)
# (B) EthTrader (which as of 3/26/2018 - 9:26 am had 8,402 subscribers)
# (C) Ripple XRP (which as of 3/26/2018 - 9:26 am had 61,128 subscribers)
# (D) Bitcoin Cash (which we probably need to change since it is not active, 
#                   but it has 1,122 subscribers as of 9:26)
# (E) Litecoin LTC (which had about 31,602 subsribers by 3/26/2018 - 9:29 am)


# Based on the information available at https://github.com/lbraglia/telegram,
# I have created a telegram bot with the following name:
# crypto_Scraper_Bot (which can be found at: t.me/Crypto_Scraper_Bot)
# The token for the API is: 523313526:AAFB7Jm8BGucygIuqMnfDdQ4EfrQuuaBu3Q

install.packages("telegram")
library(telegram)

token <- "523313526:AAFB7Jm8BGucygIuqMnfDdQ4EfrQuuaBu3Q"
bot <- TGBot$new(token)
bot$getMe()
