# READ ME: https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

# get all filenames of Flattr Monthly Revenue CSV; assumes that all were downloaded into same folder
first_flattr_file <- file.choose()
flattr_dir <- dirname(first_flattr_file) #learned from http://stackoverflow.com/a/18003224
Flattr_filenames <- list.files(flattr_dir, pattern = "flattr-revenue-[0-9]*.csv")

# move working directory to .csv files but saves original
original_wd <- getwd()
setwd(flattr_dir)

# load packages for data frame manipulation & diagram drawing; learned from http://stackoverflow.com/a/9341735
if (!"ggplot2" %in% installed.packages()) install.packages("ggplot2")
if (!"plyr" %in% installed.packages()) install.packages("plyr")
library(ggplot2)
library(plyr)


# read data from CSVs into data frame
raw <- do.call("rbind",  #  constructs and executes a call of the rbind function  => combines R objects
               lapply(Flattr_filenames, # applies function read.csv over list or vector
                      read.csv,
                      sep = ";",
                      dec = ",", # convert decimal separator from , to . for following calculations
                      stringsAsFactors = FALSE
                      )
               ) # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$period <- as.Date(paste(raw$period, "-01"), format="%Y-%m -%d")


# define export function for CSV export
export_csv <- function(data_source, filename) {
  write.table(data_source,
              file = filename,
              sep = ";",
              dec = ",",
              row.names = FALSE
              )
}

# summarizes raw data by title, thus accounting for changes in Flattr Thing ID and URLs
per_thing <- ddply(.data = raw,
                   .variables = "title",
                   .fun = summarize, 
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue)
                   )
# order by revenue
per_thing <- per_thing[order(per_thing$all_revenue, decreasing = TRUE),]
per_thing$EUR_per_click <- (per_thing$all_revenue / per_thing$all_clicks)
export_csv(per_thing, "flattr-revenue-things.csv")

# summarize by title and period to provide click-value development over time
per_period_and_thing <- ddply(raw,
                              c("period", "title"),
                              summarize,
                              all_clicks = sum(clicks),
                              all_revenue = sum(revenue)
                              )
# order by time and thing
per_period_and_thing <- per_period_and_thing[order(per_period_and_thing$title),]
per_period_and_thing$EUR_per_click <- (per_period_and_thing$all_revenue / per_period_and_thing$all_clicks)
export_csv(per_period_and_thing, "flattr-revenue-clicks.csv")

# summarize by period to provide revenue development over time
per_period <- ddply(raw,
                    "period",
                    summarize,
                    all_clicks = sum(clicks),
                    all_revenue = sum(revenue)
                    )
# order by period
per_period <- per_period[order(per_period$period),]
per_period$EUR_per_click <- (per_period$all_revenue / per_period$all_clicks)
export_csv(per_period, "flattr-revenue-months.csv")


# plot clicks over time, colored by thing, with trendlines for everything & best thing
per_period_and_thing$EUR_per_click <- (per_period_and_thing$all_revenue / per_period_and_thing$all_clicks)
best_thing <- subset(per_period_and_thing, title == per_thing[1,1])  #  reduces data frame to best thing, for later trendline

flattr_plot <- ggplot(data = per_period_and_thing,
                       aes(x = period,
                           y = EUR_per_click,
                           size = (per_period_and_thing$all_revenue),  #  point sizes in bublechart
                           colour = factor(title)
                           )
                       ) + 
  geom_point() + 
  ylab("EUR pro Klick") +
  labs(color = "Flattr-Things", size = "Spendensumme") +  #  set legend titles; arguments have to be same as in ggplot() call
  stat_smooth(mapping = aes(best_thing$period,
                            best_thing$EUR_per_click,
                            size = best_thing$all_revenue),
              data = best_thing, 
              method = "auto",
              se = FALSE,  #  confidence interval indicator
              linetype = "dashed",  # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
              show_guide = FALSE
              ) + 
  stat_smooth(aes(group = 1),  # plots trendlone over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
              method = "auto",
              se = FALSE,
              color = "black",
              show_guide = FALSE
              ) +
  theme(axis.text = element_text(size = 24),
        axis.title.x = element_blank(), # remove axis title, because month labels are unambigous already
        axis.title.y = element_text(size = 24),
        panel.grid.major = element_line(color = "white", size = 2),
        complete = FALSE
        ) # learned from http://docs.ggplot2.org/0.9.3/theme.html
  flattr_plot
ggsave(plot = flattr_plot,
       filename = "flattr-revenue-clicks.png",
       height = dim(per_period_and_thing)[1]/12,  # number of things
       width = length(Flattr_filenames)  # number of time points
       )

monthly_plot <- qplot(x = per_period$period,
                      y = per_period$all_revenue,
                      geom = "bar", stat = "identity",  # have to be used together, or points are drawn instead of bars
                      ylab = "Spendensumme [EUR]",
                      xlab = NULL  # learned from http://www.talkstats.com/showthread.php/54720-ggplot2-ylab-and-xlab-hell?s=445d87d53add5909ac683c187166c9fd&p=154224&viewfull=1#post154224
                      )
monthly_plot
ggsave(plot = monthly_plot, filename = "flattr-revenue-months.png")


# restore original working directory; useful if you use other scripts in parallel
#setwd(original_wd)
