# READ ME: https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

# assumes all .csv files were downloaded into same folder
first_flattr_file <- file.choose()
flattr_dir <- dirname(first_flattr_file) #learned from http://stackoverflow.com/a/18003224

# saves original working directory and sets new one as provided above
original_wd <- getwd()
setwd(flattr_dir)

# get filenames of Flattr Monthly Revenue CSVs
Flattr_filenames <- list.files(flattr_dir,
                               pattern = "flattr-revenue-[0-9]*.csv"
                               )

# read data from CSVs into data frame
raw <- do.call("rbind",  #  constructs and executes a call of the rbind function  => combines R objects
               lapply(Flattr_filenames, # applies function read.csv over list or vector
                      read.csv,
                      sep = ";",
                      dec = ",", # convert decimal separator from , to . for following calculations
                      stringsAsFactors = FALSE
                      )
               ) # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html

# append 1st days to months & convert to date format
# learned from http://stackoverflow.com/a/4594269
raw$period <- as.Date(paste(raw$period, "-01"), format="%Y-%m -%d")

# load plyr package for data frame 
library(plyr)

# summarizes raw data by title, thus accounting for changes in Flattr Thing ID and URLs
per_thing <- ddply(raw,
                   "title",
                   summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue)
                   )

# order by revenue 
per_thing_ordered <- per_thing[order(per_thing$all_revenue, decreasing = TRUE),]

# define export function for CSV export
export_csv <- function(data_source, filename) {
  write.table(data_source,
              file = filename,
              sep = ";",
              dec = ",",
              row.names = FALSE
              )
}

# exports summary to same folder
export_csv(per_thing_ordered, "flattr-revenue-summary.csv")

# sets sensible number of decimals for EUR/click calculation
options(digits = 2)

# summarizes by title and period, thus enabling overview of click-value development over time
per_period <- ddply(raw,
                    c("period", "title"),
                    summarize,
                    all_clicks = sum(clicks),
                    all_revenue = sum(revenue)
                    )

# plots Flattr clicks over time, colored by thing
per_period$EUR_per_click <- (per_period$all_revenue / per_period$all_clicks)
library(ggplot2)
plot <- ggplot(data = per_period, aes(x = period, y = EUR_per_click, color = factor(title))) + 
  geom_point(size = 5) +
  xlab("time") +
  ylab("EUR per click")
plot
ggsave("flattr-revenue-clicks.png", height = 12, width = 18)

# orders by title 
per_period_orderd <- per_period[order(per_period$title),]

# export to same folder
export_csv(per_period_orderd, "flattr-revenue-click-value.csv")

# restore original working directory
setwd(original_wd)
