# Creates Flattr summary from "Monthly Revenue" reports
# Started by Katrin from the KonScience Podcast in Sept. 2014

# IMPORTANT: Adjust folder path that contains all the downloaded .csv files here
#   Windows: Please use double backslashes like C:\\User\\YOU...
#   Linux & Mac: /Users/YOU/ can be abbreviated as '~/...'
path_to_flattr_reports <- "/Users/YOU/Flattr/"



# saves original working directory and sets new one as provided above
original_wd <- getwd()
setwd(path_to_flattr_reports)

# get filenames of Flattr Monthly Revenue CSVs
Flattr_filenames <- list.files(path_to_flattr_reports,
                               pattern = "flattr-revenue-[0-9]*.csv"
                               )

# // TODO find easier way to select path, e.g.
# - auto-use folder where script runs from // TODO adjust ReadMe.md
# - prompt user for path, all files (file.choose selects only one) or 1st file and find others in same folder // TODO remove original_wd code

# read data from CSVs into data frame
raw <- do.call("rbind",
                      lapply(Flattr_filenames,
                             read.csv,
                             sep = ";",
                             dec = ",", # convert decimal separator from , to . for following calculations
                             stringsAsFactors = FALSE # 
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
              )}


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

# plots Flattr clicks over time
# // TODO colorize by "title"-category
# // TODO spread elements out randomly over 25 days in their months (leave visible gap to next month)
per_period$EUR_per_click <- (per_period$all_revenue / per_period$all_clicks)
library(ggplot2)
qplot(x = per_period$period,
      y = per_period$EUR_per_click,
      xlab = "time",
      ylab = "EUR per click"
      )
ggsave("flattr-revenue-clicks.pdf")

# orders by title 
per_period_orderd <- per_period[order(per_period$title),]

# export to same folder
# // TODO functionalize export with dataframe & filename objects
export_csv(per_period_orderd, "flattr-revenue-click-value.csv")

# restore original working directory
setwd(original_wd)
