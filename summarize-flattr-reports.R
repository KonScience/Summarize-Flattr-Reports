# READ ME: https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

# assumes all .csv files were downloaded into same folder
first_flattr_file <- file.choose()
flattr_dir <- dirname(first_flattr_file) #learned from http://stackoverflow.com/a/18003224

# saves original working directory and sets new one as provided above
original_wd <- getwd()
setwd(flattr_dir)

# load plyr package for data frame manipulation & ggplot2 for drawing diagrams
library(plyr)
library(ggplot2)

# sets sensible number of decimals for EUR/click calculation
options(digits = 2)

# get filenames of Flattr Monthly Revenue CSVs
Flattr_filenames <- list.files(flattr_dir, pattern = "flattr-revenue-[0-9]*.csv")

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

# summarizes raw data by title, thus accounting for changes in Flattr Thing ID and URLs
per_thing <- ddply(.data = raw,
                   .variables = "title",
                   .fun = summarize, 
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

# summarizes by title and period, thus enabling overview of click-value development over time
per_period <- ddply(raw,
                    c("period", "title"),
                    summarize,
                    all_clicks = sum(clicks),
                    all_revenue = sum(revenue)
                    )

# Flattr clicks over time, colored by thing
# with trendlines for everything & best thing
per_period$EUR_per_click <- (per_period$all_revenue / per_period$all_clicks)
best_thing <- subset(per_period, title == per_thing_ordered[1,1])  #  reduces data frame to best thing, for later trendline

scatter_plot <- ggplot(data = per_period, aes(x = period, y = EUR_per_click, colour = factor(title))) + 
  geom_point(size = 5) + 
  xlab("time") +
  ylab("EUR per click") +
  labs(colour = "Things") + 
  stat_smooth(mapping = aes(best_thing$period,
                            best_thing$EUR_per_click,
                            size = best_thing$all_revenue),
              data = best_thing, 
              method = "auto",
              se = FALSE,
              linetype = "dashed"  # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
              ) + 
  stat_smooth(aes(group = 1),  # plots trendlone over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
              method = "auto",
              se = FALSE,  #  removes confidence interval indicator
              color = "black")
scatter_plot
ggsave(plot = scatter_plot, filename = "flattr-revenue-clicks.png", height = 12, width = 18)

# same, but with points as bubbles
bubble_plot <- ggplot(per_period,  #  data source
                      aes(period,  #  variable for x-axis
                          EUR_per_click,  #  variable for y-axis
                          size = per_period$all_revenue,  #  variable for point sizes => bublechart
                          color = factor(title)  #  coloration by title; factor() needed for discrete values, although with so many, the color spectrum is pretty much continous anyway, see http://stackoverflow.com/a/15070814
                          )) + geom_point() + xlab("time") + ylab("EUR per click") + 
  labs(color = "Things", size = "Total revenue")  #  set legend titles; arguments have to be same as in ggplot() call 
bubble_plot
ggsave(plot = bubble_plot, filename = "flattr-revenue-clicks-bubles.png", height = 12, width = 18)


# orders by title 
per_period_by_title <- per_period[order(per_period$title),]

# export to same folder
export_csv(per_period_by_title, "flattr-revenue-click-value.csv")

# restore original working directory
#setwd(original_wd)
