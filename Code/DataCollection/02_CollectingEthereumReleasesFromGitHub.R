# This file is written to extract Ethereum Releases from Github
# Note that the ETH Github Releases Page did not follow one standard
# Thus, we focused only on detecting major changes, which had a
# version number and a date in the hyperlink (on the left side)
# of the Github pages
# See Lines 46-49 for a more detailed explanation


setwd("C:/Users/megahefm/Google Drive/Miami/Research/2018/cryptopredictions/Code/DataCollection/")

# Installing the required libraries
#----------------------------------
install.packages("pacman") # Unhash if not installed
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
  alt.github.contents <- read_html(url.git)
  releases.holder <- html_nodes(alt.github.contents,
                                         "a > span.css-truncate-target")
  releases.holder <- data.frame(html_text(releases.holder))
  releases.dates.holder <- html_nodes(alt.github.contents,
                                              "p > relative-time")
  releases.dates.holder <- data.frame(html_text(releases.dates.holder))
  
  # Storing the data
  releases <- rbind(releases,releases.holder)
  releases.dates <- rbind(releases.dates,
                                   releases.dates.holder)
  
  # Going to the next page
  url.extension <- as.character(releases.holder[nrow(releases.holder),1])
  url.git <- paste(base.url,url.extension,sep = "")
  Sys.sleep(2)
}

# Saving the data
release.ethereum <- data.frame(cbind(releases.dates,releases))
releases.after.0.5.18 <- 21 # manually counted on the pages
# can be easily verified by going through
# https://github.com/ethereum/go-ethereum/releases?after=0.5.18
# and click next (after counting)
other.not.counted <- c('v0.6.3','v0.6.4','v0.6.5-1',
                       'v0.6.5-2','PoC6','vv0.7.10',
                       'v0.7.11','v0.8.4-1', 'v0.8.5-2', 'v0.9.17', '0.9.16',
                       'v0.9.22','v0.9.23 (Non Olympic-Release)',
                       'v0.9.39','v1.0.4','v1.0.1.2 (aug 20, 2015)',
                       'v1.0.5 (Sept 10, 2015','v1.0.1')
totalexpected <- 125
total.scraped.and.manually.counted <- length(other.not.counted) + nrow(release.ethereum) +  releases.after.0.5.18

save(release.ethereum,total.scraped.and.manually.counted,totalexpected,
     file = "Data/EthereumGitHub-26-2-2018.RData")
