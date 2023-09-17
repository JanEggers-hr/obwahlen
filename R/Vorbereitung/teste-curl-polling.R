my_url1 <- "https://www.untergeek.de/files/test.csv"
my_url2 <- "https://www.eggers-elektronik.de/files/test.csv"
my_url3 <- "https://votemanager-ffm.ekom21cdn.de/2022-11-06/06412000/praesentation/opendata-wahllokale.csv"

library(curl)
library(tidyr)
library(dplyr)
library(lubridate)

# library(readr)
tst <- read_csv2(my_url3,skip=1)

# Base R: 
# Das funktioniert, wenn es keinen Redirect gibt
tmp <- curlGetHeaders(my_url2, redirect = T, verify = F)
t <- tmp[stringr::str_detect(tmp,"last-modified")] %>% 
  stringr::str_replace("last-modified: ","") %>% 
  parse_date_time("%a, %d %m %Y %H:%M:%S", tz = "GMT")

# Library(curl)
h <- new_handle()
# Das funktioniert, holt aber alle Daten -> hohe Last
tmp2 <- curl_fetch_memory(my_url3,
                          handle=h)$modified %>% 
  as_datetime()
# Das richtige Argument im handle, um nur den Header zu holen? KA. 

# Das funktioniert
library(RCurl)
if(url.exists(my_url)) {
  h = RCurl::basicHeaderGatherer()
  RCurl::getURI(my_url,
         headerfunction = h$update)
  names(h$value())
  t <-tibble(n=names(h$value()),v=h$value()) %>% 
    filter(n=="last-modified") %>% 
    pull(v) %>% parse_date_time("%a, %d %m %Y %H:%M:%S", tz = "GMT")
}

tmp <- curl_fetch_memory(my_url)$modified
for (i in 0:1000) {
  
  tmp2 <- curl_fetch_memory(my_url)$modified
  if (tmp != tmp2) {
    tmp <- tmp2
    cat("Timestamp: ",tmp,"\n")
  }
  Sys.sleep(5)
  cat(".")
  
}

library(openxlsx)
curl_options("header")
