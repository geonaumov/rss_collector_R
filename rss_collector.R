# RSS to SQLite feed downloader
# geonaumov@proton.me

# Clean up the memory of your R session
rm(list=ls(all=TRUE))

library("tidyRSS")
library("RSQLite")
library("digest")
library("dplyr")
library("lgr")

lgr$info("RSS2SQLite R language edition")
dbfile <- "feeds.db"
feeds <- as.list(readLines("feed_urls.txt"))

# Columns with metadata that will be removed
remove_cols <- c('feed_category', 
                 'item_enclosure', 
                 "item_category",
                 "entry_category")

# Input is feed URL, write directly to DB
run_feed <- function(feed_url) {
  parsed_feed <- tidyfeed(toString(feed_url), 
                          clean_tags=TRUE, 
                          parse_dates=TRUE, 
                          list=FALSE)
  parsed_feed = subset(parsed_feed, 
                       select = !(names(parsed_feed) %in% remove_cols))
  # Hash code to check against the feed URL
  table_hash <- digest(feed, "md5", serialize=FALSE)
  # Create or append table
  dbWriteTable(conn, 
               table_hash, 
               parsed_feed, 
               append=TRUE,
               row.names=TRUE)
}

# Entry - connect to DB and parse all feeds
conn <- dbConnect(RSQLite::SQLite(), dbfile)
for (feed in feeds) {
  lgr$info(feed)
  try(run_feed(feed))
}
dbDisconnect(conn)
lgr$info("DONE")
