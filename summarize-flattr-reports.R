# READ ME: https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

# load packages for data frame manipulation & diagram drawing
# see http://www.r-bloggers.com/library-vs-require-in-r/ for require() vs. library() discussion
library(scales)
library(ggplot2)
library(plyr)

# get all filenames of Flattr Monthly Revenue CSV; assumes that all were downloaded into same folder

args = (commandArgs(trailingOnly = TRUE))

if (length(args) == 0) { # execute via: Rscript path/to/script.r path/to/flattr-revenue-000000.csv
  print("Please select one of the 'flattr-revenue-....csv' files from the folder you downloaded them to.")
  first_flattr_file <- file.choose()
  flattr_dir <- dirname(first_flattr_file) # learned from http://stackoverflow.com/a/18003224
} else {
  if (substring(args[1], 1, 1) == "/") {
    flattr_dir <- dirname(args[1]) # set absolute directory by cli argument
  } else {
    flattr_dir <- dirname(file.path(getwd(), args[1], fsep = .Platform$file.sep)) # set relative directory by cli argument
  }
}

Flattr_filenames <- list.files(flattr_dir, pattern = "flattr-revenue-20[0-9]{4}.csv")

# move working directory to .csv files but save original
original_wd <- getwd()
setwd(flattr_dir)

# check for summary file of previously processed data & add new reports, instead of reading in every files again
try(known_raw <- read.csv("flattr-revenue-000000.csv", encoding = "UTF-8", sep = ";", dec = ",", stringsAsFactors = FALSE))

if ("flattr-revenue-000000.csv" %in% list.files(flattr_dir, pattern = "*.csv")) {
  # check for existing raw date & merge with new
  if (length(unique(known_raw$period)) <= length(Flattr_filenames)) {
    known_months <- paste(paste("flattr-revenue",  # turn months into filenames
                                sub("-",
                                    "",
                                    unique(known_raw$period)),
                                sep = "-"),
                          "csv",
                          sep = ".")

    new_months <- setdiff(Flattr_filenames, known_months)

    new_raw <- do.call("rbind",
                       lapply(new_months,
                              read.csv,
                              encoding = "UTF-8",
                              sep = ";",
                              dec = ",",
                              stringsAsFactors = FALSE))
    raw <- rbind(known_raw, new_raw)  # learned from http://stackoverflow.com/a/27313467
    }
  } else {  # read data from all CSVs into data frame
    raw <- do.call("rbind",  #  constructs and executes a call of the rbind function  => combines R objects
                   lapply(Flattr_filenames, # applies function read.csv over list or vector
                          read.csv,
                          encoding = "UTF-8",  # learned from RTFM, but works only on Win7
                          sep = ";", dec = ",",  # csv defaults: , & . but Flattr uses "European" style
                          stringsAsFactors = FALSE))  # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html
  }

Sys.setlocale("LC_ALL", "UTF-8")  # respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/

# export aggregated data for next (month's) run
write.table(raw, "flattr-revenue-000000.csv", sep = ";", dec = ",")

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

# summarize & order by title to account for changes in Thing ID and URLs (due to redirection after permalink changes)
per_thing <- ddply(.data = raw,
                   .variables = "title",
                   .fun = summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue))
per_thing <- per_thing[order(per_thing$all_revenue, decreasing = TRUE),]
write.table(x = per_thing,
            file = "flattr-revenue-things.csv",
            row.names = FALSE)

# summarize & order by month and thing to provide click-value development over time
per_month_and_thing <- ddply(raw,
                             c("period", "title", "EUR_per_click"),
                             summarize, all_clicks = sum(clicks),
                             all_revenue = sum(revenue))
per_month_and_thing <- per_month_and_thing[order(per_month_and_thing$title),]
write.table(per_month_and_thing,
            "flattr-revenue-clicks.csv",
            row.names = FALSE)

# summarize & export revenue per month
per_month <- ddply(raw,
                   "period",
                   summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue))
per_month <- per_month[order(per_month$period),]
write.table(per_month,
            "flattr-revenue-months.csv",
            row.names = FALSE)

# revenue per click and month colored by thing, with trends for everything & best thing
best_thing <- subset(per_month_and_thing, title == per_thing[1,1])  #  reduces data frame to best thing, for later trendline
best_thing$EUR_per_click <- best_thing$all_revenue / best_thing$all_clicks

flattr_plot <- ggplot(data = raw, mapping = aes(x = period, y = EUR_per_click,
                                                size = raw$revenue,  #  points sized according to revenue of that thing in that month => bubble plot
                                                colour = factor(title)))  +
  geom_jitter()  +  # same as geom_point(position = "jitter"); spreads data points randomly around true x value bit; day-exact resolution not (yet) possible
  labs(list(title = "Development of Flattr Revenue per Click\n", x = NULL,
            y = expression("EUR per Flattr (outliers omitted)")))  +  # learned from http://docs.ggplot2.org/current/labs.html
  stat_smooth(mapping = aes(best_thing$period, best_thing$EUR_per_click, size = best_thing$all_revenue),
              data = best_thing, method = "auto", show_guide = FALSE, size = N_months / 20,
              se = FALSE,  #  confidence interval indicator
              linetype = "dashed")  +   # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
  stat_smooth(aes(group = 1),  # plots trendline over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
              method = "auto", se = FALSE, color = "darkgrey", show_guide = FALSE, size = N_months / 20)  +
  scale_y_continuous(limits = c(0, mean(raw$EUR_per_click) * 5),  # omit y-values larger than 5x arithmetic mean learned from http://stackoverflow.com/a/26558070
                     expand = c(0, 0))  +
  theme(legend.position = "none")
ggsave("flattr-revenue-clicks.png", flattr_plot, limitsize = FALSE)

# revenue per month and thing
monthly_advanced_plot <- ggplot(per_month_and_thing, aes(x = period, y = all_revenue, fill = factor(title)))  +
  geom_bar(stat = "identity")  +
  labs(list(title = "Development of Flattr Revenue by Things\n", x = NULL, y = "EUR received\n"))  +
  scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1), expand = c(0, 0))  +
  scale_x_date(expand = c(0, 0))  +
  theme(legend.position = "none")
monthly_advanced_plot
ggsave("flattr-revenue-months.png", monthly_advanced_plot, limitsize = FALSE)

# total revenue per month with trend
monthly_simple_plot <- ggplot(data = per_month, aes(x = period, y = all_revenue))  +
  geom_bar(stat = "identity", group = 1, fill = "#ED8C3B")  +
  labs(list(title = "Development of Flattr Revenue\n",
            y = "EUR received\n",
            x = NULL))  +
  stat_smooth(data = per_month, method = "auto", color = "#80B04A", size = N_months / 5)  +  # fit trend plus confidence interval
  scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1),  # omit negative y-values & limit positive y-axis to 10% overhead over maximum value
                     expand = c(0, 0))  +
  scale_x_date(expand = c(0, 0))
ggsave("flattr-revenue-months-summarized.png", monthly_simple_plot, limitsize = FALSE)


# revenue per location of button

# summarize & order by month and domain
raw$domain <- sapply(strsplit(x = raw$url,
                              split = "/"),
                     "[",  # indexing operator, see https://stackoverflow.com/questions/3703803/apply-strsplit-rowwise/3703855#comment3905951_3703855
                     3)  # select index 3 of list = domain

for (i in 1:length(raw$domain)) {
  raw$domain[i] <- gsub(pattern = "www.",
                        replacement = "",
                        x = raw$domain[i])}

per_month_and_domain <- ddply(raw,
                              c("period", "domain"),
                              summarize,
                              all_clicks = sum(clicks),
                              all_revenue = sum(revenue))
per_month_and_domain <- per_month_and_domain[order(per_month_and_domain$domain),]
write.table(per_month_and_domain,
            "flattr-revenue-clicks-domain.csv",
            row.names = FALSE)

monthly_domain_plot <- ggplot(per_month_and_domain, aes(x = period, y = all_revenue, fill = factor(domain)))  +
  geom_bar(stat = "identity")  +
  labs(list(title = "Development of Flattr Revenue by Button Locations\n",
            y = "EUR received\n",
            x = NULL))  +
  labs(fill = "Domains")  +
  scale_y_continuous(limits = c(0, max(per_month_and_domain$all_revenue) * 1.1),
                     expand = c(0, 0))  +
  scale_x_date(labels = date_format("%b '%y"), breaks = date_breaks(width = "3 month"), expand = c(0, 0))  +
  guides(fill = guide_legend(reverse = TRUE))  # aligns legend order with fill order of bars in plot; learned from http://www.cookbook-r.com/Graphs/Legends_%28ggplot2%29/#kinds-of-scales
monthly_domain_plot
ggsave("flattr-revenue-months-domain.png", monthly_domain_plot, limitsize = FALSE)

# restore original working directory; only useful if you use other scripts in parallel => comment out with # while tinkering with this script, or the files won't be exported to your Flattr folder
#setwd(original_wd)
