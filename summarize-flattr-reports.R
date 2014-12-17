# READ ME: https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

# load packages for data frame manipulation & diagram drawing; learned from http://stackoverflow.com/a/9341735
# update.packages(checkBuilt = TRUE, ask = FALSE) # update all packages

if (!"scales" %in% installed.packages()) {
  install.packages("scales")
}

if (!"ggplot2" %in% installed.packages()) {
  install.packages("ggplot2")
}

if (!"plyr" %in% installed.packages()) {
  install.packages("plyr")
}

# see http://www.r-bloggers.com/library-vs-require-in-r/ for require() vs. library() discussion
library(scales)
library(ggplot2)
library(plyr)

# get all filenames of Flattr Monthly Revenue CSV; assumes that all were downloaded into same folder

args = (commandArgs(TRUE))

if (length(args) == 0) { # execute via: Rscript path/to/script.r path/to/flattr-revenue-YYYYMM.csv
  print("Please select one of the 'flattr-revenue-....csv' files from the folder you downloaded them to.")
  first_flattr_file <- file.choose()
  flattr_dir <- dirname(first_flattr_file) # learned from http://stackoverflow.com/a/18003224
} else {
  flattr_dir <- dirname(paste(getwd(), args[1], sep="/")) # set directory by cli argument
}

Flattr_filenames <- list.files(flattr_dir, pattern = "flattr-revenue-[0-9]*.csv")

# move working directory to .csv files but saves original
original_wd <- getwd()
setwd(flattr_dir)

# read data from CSVs into data frame
raw <- do.call("rbind",  #  constructs and executes a call of the rbind function  => combines R objects
               lapply(Flattr_filenames, # applies function read.csv over list or vector
                      read.csv,
                      encoding = "UTF-8",  # learned from RTFM, but works only on Win7
                      sep = ";", dec = ",",  # csv defaults: , & . but Flattr uses "European" style
                      stringsAsFactors = FALSE)) # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html

Sys.setlocale("LC_ALL", "UTF-8")  # respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$period <- as.Date(paste(raw$period, "-01"), format="%Y-%m -%d")
raw$EUR_per_click <- raw$revenue / raw$clicks

# populate raw data with all_revenue for each thing
for (i in 1:dim(raw)[1]){
  raw$all_revenue[i] <- sum(subset(raw, title == raw$title[i])$revenue)
}

# determine dataset size to auto-adjust plots
N_months <- length(Flattr_filenames)
N_things <- length(unique(raw$title))


# define export functions for tables & plots

export_csv <- function(data_source, filename){
  write.table(x = data_source, file = filename,
              sep = ";", dec = ",",  # adhere to Flattr's csv style
              row.names = FALSE)
}

export_plot <- function(plot_name, filename){
  ggsave(plot = plot_name, filename, height = N_things / 3, width = N_months, limitsize = FALSE)
  return(plot_name)  # display plot preview in RStudio
}


# summarize & order by title to account for changes in Thing ID and URLs (due to redirection after permalink changes)
per_thing <- ddply(.data = raw, .variables = "title", .fun = summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))
per_thing <- per_thing[order(per_thing$all_revenue, decreasing = TRUE),]
export_csv(per_thing, "flattr-revenue-things.csv")

# summarize & order by month and thing to provide click-value development over time
per_month_and_thing <- ddply(raw, c("period", "title", "EUR_per_click"), summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))
per_month_and_thing <- per_month_and_thing[order(per_month_and_thing$title),]
export_csv(per_month_and_thing, "flattr-revenue-clicks.csv")

# summarize & export revenue per month
per_month <- ddply(raw, "period", summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))
per_month <- per_month[order(per_month$period),]
export_csv(per_month, "flattr-revenue-months.csv")

# themeing function for following plots
set_advanced_theme <- function(){
  theme(plot.title = element_text(size = N_months * 1.4),
        axis.text = element_text(size = N_months),
        axis.text.x = element_text(angle = 30, hjust = 1),  # hjust prevents overlap with panel; learned from http://stackoverflow.com/a/1331400
        axis.title.x = element_blank(), # remove axis title, because months labels are unambiguous already
        axis.title.y = element_text(size = N_months * 1.2),
        legend.title = element_text(size = N_months / 1.4),
        panel.grid.major = element_line(color = "lightgrey", size = N_months / 40),
        panel.grid.minor.x = element_blank(),
        panel.background = element_rect(fill = "white"),
        complete = FALSE)} # learned from http://docs.ggplot2.org/0.9.3/theme.html


# revenue per click and month colored by thing, with trends for everything & best thing
best_thing <- subset(per_month_and_thing, title == per_thing[1,1])  #  reduces data frame to best thing, for later trendline
best_thing$EUR_per_click <- best_thing$all_revenue / best_thing$all_clicks

flattr_plot <- ggplot(data = raw, mapping = aes(x = period, y = EUR_per_click,
                                                size = raw$revenue,  #  points sized according to revenue of that thing in that month => bubble plot
                                                colour = factor(title)))  +
  geom_jitter()  +  # same as geom_point(position = "jitter"); spreads data points randomly around true x value bit; day-exact resolution not (yet) possible
  labs(list(title = "Development of Flattr Revenue per Click\n", x = NULL, y = "EUR per Flattr\n"))  +  # learned from http://docs.ggplot2.org/current/labs.html
  labs(color = "Flattred Things", size = "EUR per Thing")  +  #  set legend titles; arguments have to be same as in ggplot() call
  stat_smooth(mapping = aes(best_thing$period, best_thing$EUR_per_click, size = best_thing$all_revenue),
              data = best_thing, method = "auto", show_guide = FALSE, size = N_months / 20,
              se = FALSE,  #  confidence interval indicator
              linetype = "dashed")  +   # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
  stat_smooth(aes(group = 1),  # plots trendline over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
              method = "auto", se = FALSE, color = "darkgrey", show_guide = FALSE, size = N_months / 20)  +
  scale_y_continuous(limits = c(0, mean(raw$EUR_per_click) * 5),  # omit y-values larger than 5x arithmetic mean learned from http://stackoverflow.com/a/26558070
                     expand = c(0, 0))  +
  scale_x_date(labels = date_format("%b '%y"),  # month name abbr. & short year
               breaks = date_breaks(width = "1 month"),  # force major gridlines; learned from http://stackoverflow.com/a/9742126
               expand = c(0.01, 0.01))  +  # reduce blank space around data; learned from http://stackoverflow.com/a/26558070
  scale_fill_identity(aes(x = period, y = EUR_per_click, colour = factor(title), guide = "legend"))  +
  guides(col = guide_legend(reverse = TRUE,  # align legend order with fill order of bars in plot; learned from http://www.cookbook-r.com/Graphs/Legends_%28ggplot2%29/#kinds-of-scales
                             override.aes = list(shape = 15, size = mean(raw$EUR_per_click) * 40)))  +  # replace geom_point() legend symbol with imitation of that of geom_bar(); learned from http://stackoverflow.com/a/27404156/4341322
  set_advanced_theme()
export_plot(flattr_plot, "flattr-revenue-clicks.png")

# revenue per month and thing
monthly_advanced_plot <- ggplot(per_month_and_thing, aes(x = period, y = all_revenue, fill = factor(title)))  +
  geom_bar(stat = "identity")  +
  labs(list(title = "Development of Flattr Revenue by Things\n", x = NULL, y = "EUR received\n"))  +
  labs(fill = "Flattred Things")  +  scale_y_continuous(limits = c(0, max(per_month_and_thing$all_revenue) * 1.1), expand = c(0, 0))  +
  scale_x_date(expand = c(0, 0))  +
  guides(fill = guide_legend(reverse = TRUE))  +
  set_advanced_theme()
export_plot(monthly_advanced_plot, "flattr-revenue-months.png")

# total revenue per month with trend
monthly_simple_plot <- ggplot(data = per_month, aes(x = period, y = all_revenue))  +
  geom_bar(stat = "identity", group = 1, fill = "#ED8C3B")  +
  labs(list(title = "Development of Flattr Revenue\n", x = NULL, y = "EUR received\n"))  +
  stat_smooth(data = per_month, method = "auto", color = "#80B04A", size = N_months / 5)  +  # fit trend plus confidence interval
  scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1),  # omit negative y-values & limit positive y-axis to 10% overhead over maximum value
                     expand = c(0, 0))  +  set_advanced_theme()
monthly_simple_plot
ggsave("flattr-revenue-months-summarized.png", monthly_simple_plot, limitsize = FALSE)


# revenue per location of button

# append domain of flattr-thing by splitting by "/" and selecting the 3rd value
raw$domain <- sapply(strsplit(raw$url, "/"),"[",3)

# summarize & order by month and domain
per_month_and_domain <- ddply(raw, c("period", "domain"), summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))
per_month_and_domain <- per_month_and_domain[order(per_month_and_domain$domain),]
export_csv(per_month_and_domain, "flattr-revenue-clicks-domain.csv")

monthly_domain_plot <- ggplot(per_month_and_domain, aes(x = period, y = all_revenue, fill = factor(domain)))  +
  geom_bar(stat = "identity")  +
  labs(list(title = "Development of Flattr Revenue by Button Locations\n", x = NULL, y = "EUR received\n"))  +
  labs(fill = "Domains")  +
  scale_y_continuous(limits = c(0, max(per_month_and_domain$all_revenue) * 1.1), expand = c(0, 0),
                     breaks = seq(0, round(max(per_month$all_revenue) * 1.1),
                                  round(max(per_month$all_revenue) / 10)))  +
  scale_x_date(labels = date_format("%b '%y"), breaks = date_breaks(width = "1 month"), expand = c(0, 0))  +
  guides(fill = guide_legend(reverse = TRUE))  +  # aligns legend order with fill order of bars in plot; learned from http://www.cookbook-r.com/Graphs/Legends_%28ggplot2%29/#kinds-of-scales
  set_advanced_theme()
export_plot(monthly_domain_plot, "flattr-revenue-months-domain.png")

# restore original working directory; only useful if you use other scripts in parallel => comment out with # while tinkering with this script, or the files won't be exported to your Flattr folder
setwd(original_wd)
