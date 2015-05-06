# Please read https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

rm(list = ls())  # clean workspace
original_wd <- getwd()  # save current working directory
Sys.setlocale("LC_ALL", "UTF-8")  # respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/
options(stringsAsFactors = FALSE, row.names = FALSE, limitsize = FALSE) # set global options

# see http://www.r-bloggers.com/library-vs-require-in-r/ for require() vs. library() discussion
library(scales)
library(ggplot2)
library(plyr)

# get all filenames of Flattr Monthly Revenue CSV; assumes that all were downloaded into same folder
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) { # execute via: Rscript path/to/summarize-flattr-reports.R path/to/flattr-revenue-000000.csv
  print("Please select one of the 'flattr-revenue-....csv' files from the folder you downloaded them to.")
  first_flattr_file <- file.choose()
  flattr_dir <- dirname(first_flattr_file) # learned from http://stackoverflow.com/a/18003224
} else {
  if ((substring(args[1], 1, 1) == "/") || (substring(args[1], 2, 2) == ":")) {
    flattr_dir <- dirname(args[1]) # set absolute directory by cli argument
  } else {flattr_dir <- dirname(file.path(getwd(), args[1], fsep = .Platform$file.sep))} # set relative directory by cli argument
}
Flattr_filenames <- list.files(flattr_dir, pattern = "flattr-revenue-20[0-9]{4}.csv")
setwd(flattr_dir)

# use summary file if available & create if not, instead of reading files individually
try(known_raw <- read.csv2("flattr-revenue-000000.csv", encoding = "UTF-8"))
if ("flattr-revenue-000000.csv" %in% list.files(flattr_dir, pattern = "*.csv")) {
  # check for existing raw date & merge with new
  if (length(unique(known_raw$period)) < length(Flattr_filenames)) {
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
                              read.csv2,
                              encoding = "UTF-8"))
    raw <- rbind(known_raw, new_raw)  # learned from http://stackoverflow.com/a/27313467
  } else {  # read data from all CSVs into data frame
    raw <- do.call("rbind",  #  constructs and executes a call of the rbind function  => combines R objects
                   lapply(Flattr_filenames, # applies function read.csv2 over list or vector
                          read.csv2,
                          encoding = "UTF-8" # learned from RTFM, but works only on Win7
                   ))  # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html
  }} else {raw <- do.call("rbind", lapply(Flattr_filenames, read.csv2, encoding = "UTF-8"))}  # same as inner else, just to catch edge case of repetive plotting without adding new Revenue Reports
write.csv2(x = raw, file = "flattr-revenue-000000.csv")

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$period <- as.Date(paste(raw$period, "-01"), format="%Y-%m -%d")
raw$EUR_per_click <- raw$revenue / raw$clicks

# populate raw data with all_revenue for each thing
for (i in 1:nrow(raw)){raw$all_revenue[i] <- sum(subset(raw, title == raw$title[i])$revenue)}

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
write.csv2(per_thing, "flattr-revenue-things.csv")

# summarize & order by month and thing to provide click-value development over time
per_month_and_thing <- ddply(raw,
                             c("period", "title", "EUR_per_click"),
                             summarize,
                             all_clicks = sum(clicks),
                             all_revenue = sum(revenue))
per_month_and_thing <- per_month_and_thing[order(per_month_and_thing$title),]
write.csv2(per_month_and_thing, "flattr-revenue-clicks.csv")

# summarize & export revenue per month
per_month <- ddply(raw,
                   "period",
                   summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue))
per_month <- per_month[order(per_month$period),]
write.csv2(per_month, "flattr-revenue-months.csv")

# revenue per click and month colored by thing, with trends for everything & best thing
best_thing <- subset(per_month_and_thing, title == per_thing[1,1])  #  reduces data frame to best thing, for later trendline
best_thing$EUR_per_click <- best_thing$all_revenue / best_thing$all_clicks

flattr_plot <- ggplot(data = raw,
                      mapping = aes(x = period,
                                    y = EUR_per_click,
                                    size = raw$revenue,  #  points sized according to revenue of that thing in that month => bubble plot
                                    colour = factor(title)))
flattr_plot  +
  geom_jitter()  +  # same as geom_point(position = "jitter"); spreads data points randomly around true x value bit; day-exact resolution not (yet) possible
  stat_smooth(mapping = aes(x = best_thing$period,
                            y = best_thing$EUR_per_click,
                            size = best_thing$all_revenue),
              data = best_thing,
              method = "auto",
              show_guide = FALSE,
              size = N_things / N_months,
              se = FALSE,  #  confidence interval indicator
              linetype = "dashed")  +   # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
  stat_smooth(aes(group = 1),  # plots trendline over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
              method = "auto",
              se = FALSE,
              color = "darkgrey",
              show_guide = FALSE,
              size = N_months / 20)  +
  scale_x_date(breaks = "3 month", labels = date_format("%Y-%b"), expand = c(0, 0))  +
  scale_y_continuous(limits = c(0, mean(raw$EUR_per_click) * 5),  # omit extreme y-values; learned from http://stackoverflow.com/a/26558070
                     expand = c(0, 0))  +
  labs(title = "Development of Flattr Revenue per Click",  # learned from http://docs.ggplot2.org/current/labs.html
       x = NULL,
       y = expression("EUR per Flattr (extremes omitted)"),
       colour = "Thing",
       size = "Total revenue of Thing")  +
  theme_classic(base_size = sqrt(N_months + N_things))  +
  theme(legend.position = "none", axis.text.x = element_text(angle = 15))
ggsave("flattr-revenue-clicks.png")

# revenue per month and thing
monthly_advanced_plot <- ggplot(per_month_and_thing, aes(period, all_revenue, fill = factor(title)))
monthly_advanced_plot  +
  geom_bar(stat = "identity")  +
  scale_x_date(expand = c(0, 0), breaks = "3 month", labels = date_format("%Y-%b"))  +
  scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1), expand = c(0, 0))  +
  guides(fill = guide_legend(reverse = TRUE))  +
  labs(title = "Development of Flattr Revenue by Things", x = NULL, y = "EUR received", fill = "Thing")  +
  theme_classic(base_size = (N_things + N_months) / 5)
ggsave("flattr-revenue-months.png", height = N_things/3, width = N_months/1.5)

# total revenue per month with trend
monthly_simple_plot <- ggplot(per_month, aes(x = period, y = all_revenue, size = per_month$all_revenue))
monthly_simple_plot +
  geom_point(colour = "#ED8C3B")  +
  stat_smooth(data = per_month, method = "auto", color = "#80B04A", size = N_things / N_months)  +  # fit trend plus confidence interval
  scale_x_date(expand = c(0, 0), breaks = "3 month", labels = date_format("%Y-%b"))  +
  scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1), expand = c(0, 0))  +
  labs(title = "Development of Flattr Revenue", x = NULL, y = "EUR received")  +
  theme_classic(base_size = sqrt(N_things + N_months))  +
  theme(axis.text.x = element_text(angle = 15), legend.position = "none")
ggsave("flattr-revenue-months-summarized.png")


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

monthly_domain_plot <- ggplot(per_month_and_domain, aes(period, all_revenue, fill = factor(domain)))
monthly_domain_plot  +
  geom_bar(stat = "identity")  +
  scale_x_date(expand = c(0,0), breaks = "3 month", labels = date_format("%Y-%b"))  +
  scale_y_continuous(limits = c(0, max(per_month$all_revenue)), expand = c(0, 0))  +
  scale_fill_brewer(type = "qual")  +
  guides(fill = guide_legend(reverse = TRUE, keywidth = 0.5, keyheight = 0.5))  +
  labs(title = "Development of Flattr Revenue by Button Locations", x = NULL, y = "EUR received", fill = "Domains")  +
  theme_classic(base_size = sqrt(N_things + N_months))  +
  theme(axis.text.x = element_text(angle = 30))
ggsave("flattr-revenue-months-domain.png")

monthly_domain_plot_fractions <- ggplot(per_month_and_domain, aes(period, all_revenue, fill = factor(domain)))
monthly_domain_plot_fractions +
  geom_bar(position = "fill", stat = "identity")  +
  coord_flip() +
  scale_x_date(expand = c(0,0), breaks = "1 month", labels = date_format("%Y-%b"))  +
  scale_y_continuous(expand = c(0, 0))  +
  scale_fill_brewer(type = "qual")  +
  guides(fill = guide_legend(reverse = TRUE, keywidth = 0.5, keyheight = 0.5))  +
  labs(title = "Fractions of Flattr Revenue by Button Locations",
       x = NULL, y = NULL, fill = "Domains")  +
  theme_classic(base_size = sqrt(N_things + N_months))
ggsave("flattr-revenue-months-domain-fractions.png")

# sort & export after plotting in order to preserve alphabatic sorting in of domains in plot
per_month_and_domain <- per_month_and_domain[order(per_month_and_domain$all_revenue),]
write.csv2(per_month_and_domain, "flattr-revenue-clicks-domain.csv")
