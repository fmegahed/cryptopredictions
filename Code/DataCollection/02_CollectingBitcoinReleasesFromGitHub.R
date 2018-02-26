setwd("C:/Users/megahefm/Google Drive/Miami/Research/2018/cryptopredictions/Code/DataCollection")
 

# Installing the required libraries
#----------------------------------
install.packages("pacman") # Unhash if not installed
pacman::p_load(rvest,gsubfn,stringr) # allows multiple loading


# Scraping the Data:
# ------------------
base.url <-"https://github.com/bitcoin/bitcoin/releases?after="
url.git <- "https://github.com/bitcoin/bitcoin/releases?after="
# Initilization for looping
verified.releases <- {}
releases <- {}
verified.releases.dates <- {}
dates <- {}
url.extension <- "placeholder"
# Looping through all bitcoin releases on github
while (url.extension!="v0.1.5") {
  # Step 1: Reading the Data
  github.contents <- readLines(url.git)
  # Step 2: Scraping the data pertaining
  # (A) Obtaining all releases in the url (pages increment)
  releases.holder <- as.data.frame(strapplyc(github.contents,
                                             "href=\"/bitcoin/bitcoin/releases/tag/(.*?)\">",
                                             simplify = rbind))
  # (B) Obtaining all dates in the url (pages increment)
  dates.holder <- as.data.frame(strapplyc(github.contents,
                                          "<relative-time datetime=(.*?) ",
                                          simplify = rbind))
  # Step 3: Ensuring that releases and dates match
    # Checked to work in Bitcoin
  if (nrow(dates.holder) != nrow(releases.holder)){
    dates.holder <- unique(dates.holder)
  }
  # Step 4: Getting all verified releases (easier using rvest)
  alt.github.contents <- read_html(url.git)
  verified.releases.holder <- html_nodes(alt.github.contents,
                                         "a > span.css-truncate-target")
  verified.releases.holder <- data.frame(html_text(verified.releases.holder))
  verified.releases.dates.holder <- html_nodes(alt.github.contents,
                                              "p > relative-time")
  verified.releases.dates.holder <- data.frame(html_text(verified.releases.dates.holder))
  
  # Storing the data
  verified.releases <- rbind(verified.releases,verified.releases.holder)
  releases <- rbind(releases,releases.holder)
  verified.releases.dates <- rbind(verified.releases.dates,
                                   verified.releases.dates.holder)
  dates <- rbind(dates,dates.holder)
  
  # Going to the next page
  url.extension <- as.character(releases.holder[nrow(releases.holder),1])
  url.git <- paste(base.url,url.extension,sep = "")
  Sys.sleep(2)
}

# Saving the data

verified.btc <- data.frame(cbind(verified.releases.dates,verified.releases))
unverified.btc <- data.frame(cbind(dates,releases))
save(verified.btc,unverified.btc,
     file = "C:/Users/megahefm/Google Drive/Miami/Research/2018/cryptopredictions/LabNotebook/BitcoinGitHub-26-2-2018.RData")
