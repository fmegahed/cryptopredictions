# This file is written to extract Ethereum Releases from Github
#  Note that the ETH Github Releases Page did not follow one standard.
#  Thus, we focused only on detecting major changes, which had a
#  version number and a date in the hyperlink (on the left side)
#  of the Github pages.

# See 02_CollectingEthereumReleaseFromGitHub.R Lines 46-49
#  for a more detailed explanation

setwd("C:/Users/leonarr/Google Drive/Research/cryptopredictions/Code/DataCollection/")

# Installing the required libraries
#----------------------------------
#install.packages("pacman") # Unhash if not installed
pacman::p_load(rvest,gsubfn,stringr) # allows multiple loading

# Scraping the Data:
# ------------------
base.url <-"https://github.com/ethereum/go-ethereum/releases?after="
url.git <- "https://github.com/ethereum/go-ethereum/releases?after="
# Initilization for looping
releases <- {}
releases.dates <- {}
url.extension <- "placeholder"
# Looping through all ethereum releases on github
while (url.extension!="0.5.18") {
  releases.holder <- read_html(url.git) %>%
    html_nodes("a > span.css-truncate-target") %>%
    html_text()%>% data.frame()
  releases.dates.holder <- read_html(url.git) %>%
    html_nodes("p > relative-time") %>%
    html_attr('datetime') %>% data.frame()

  # Storing the data
  releases <- rbind(releases,releases.holder)
  releases.dates <- rbind(releases.dates,
                                   releases.dates.holder)
  
  # Going to the next page
  url.extension <- as.character(releases.holder[nrow(releases.holder), 1])
  url.git <- paste(base.url, url.extension, sep = "")
  Sys.sleep(3 + rnorm(1)) # extended beyond 2 sec to stop 403 error
}

# Saving the data
release.ethereum <- data.frame(cbind(releases.dates, releases))
save(release.ethereum,
     file = paste0("Data/EthereumGitHub-", Sys.Date(), ".RData"))
