# Creates Flattr summary from "Monthly Revenue" reports
# Started by Katrin from the KonScience Podcast in Sept. 2014

# IMPORTANT
# Adjust folder path that contains all the downloaded .csv files here

path_to_flattr_reports <- "/Users/YOU/Flattr/"
#   Windows: Please use double backslashes like C:\\User\\YOU...
#   Linux & Mac: /Users/YOU/ can be abbreviated as '~/...'

# saves original working directory and sets new one as provided above
original_wd <- getwd()
setwd(path_to_flattr_reports)

# get filenames of Flattr Monthly Revenue CSVs
Flattr_filenames <- list.files(path_to_flattr_reports,
                               pattern = "flattr-revenue-[0-9]*.csv" # RegEx learned from http://www.regexr.com/
                        )

# // TODO find easier way to select path, e.g.
# - auto-use folder where script runs from // TODO adjust ReadMe.md
# - prompt user for path, all files (file.choose selects only one) or 1st file and find others in same folder // TODO remove original_wd code

# read data from CSVs into dataframe
raw_Flattrs <- do.call("rbind",
                      lapply(Flattr_filenames,
                             read.csv,
                             sep = ";", # column separator
                             dec = ",", # convert decimal separator from , to . for following calculations
                             stringsAsFactors = FALSE
                             )
                      ) # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html

# load plyr package
library(plyr)

# summarizes raw data by title, thus accounting for changes in Flattr Thing ID and URLs
all_Flattrs <- ddply(raw_Flattrs,
                     "title",
                     summarize, # this breaks if spelled the British way :-/
                     all_clicks = sum(clicks,
                                        na.rm = TRUE), # removes NA / empty data
                     all_revenue = sum(revenue,
                                         na.rm = TRUE)
                     ) # // TODO sort output

# exports summary to same folder
write.table(all_Flattrs,
            file = "flattr-revenue-summary.csv", # Change only in combination with RegEx pattern "flattr-revenue-[0-9]*.csv" above! If exported file must not be read into Flattr_filenames object.
            sep = ";", # reset column separator to Flattr default
            dec = ",", # reset decimal separator to Flattr default
            row.names = FALSE # 
            )

# restore original working directory
setwd(original_wd)
