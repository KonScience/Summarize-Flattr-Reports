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
library(scales)


# read data from CSVs into data frame
raw <- do.call("rbind",  #  constructs and executes a call of the rbind function  => combines R objects
               lapply(Flattr_filenames, # applies function read.csv over list or vector
                      read.csv,
                      sep = ";", dec = ",",  # csv defaults: , & . but Flattr uses "European" style
                      stringsAsFactors = FALSE)) # Function structure learned from https://stat.ethz.ch/pipermail/r-help/2010-October/255593.html

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$period <- as.Date(paste(raw$period, "-01"), format="%Y-%m -%d")

# append domain of flattr-thing by splitting by "/" and selecting the 3rd value
raw$domain <- sapply(strsplit(raw$url, "/"),"[",3)

# define export functions for tables & plots
{
  export_csv <- function(data_source, filename){
    write.table(x = data_source, file = filename,
                sep = ";", dec = ",",  # adhere to Flattr's csv style
                row.names = FALSE)}
  export_plot <- function(plot_name, filename, height_modifier){
    ggsave(plot = plot_name, filename,
           height = dim(per_month_and_thing)[1]/height_modifier,  # number of things determined by 1st entry in dataframe dimension result 
           width = length(Flattr_filenames))  # number of months determined by number of report files
  }
}

# summarizes raw data by title, thus accounting for changes in Flattr Thing ID and URLs
per_thing <- ddply(.data = raw, .variables = "title", .fun = summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))

# order by revenue
per_thing <- per_thing[order(per_thing$all_revenue, decreasing = TRUE),]
per_thing$EUR_per_click <- (per_thing$all_revenue / per_thing$all_clicks)
export_csv(per_thing, "flattr-revenue-things.csv")

# summarize by title and period to provide click-value development over time
per_month_and_thing <- ddply(raw, c("period", "title"), summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))

# summarize by domain and period to provide click-value development over time
per_month_and_domain <- ddply(raw, c("period", "domain"), summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))

# order by time and thing
per_month_and_thing <- per_month_and_thing[order(per_month_and_thing$title),]
per_month_and_thing$EUR_per_click <- (per_month_and_thing$all_revenue / per_month_and_thing$all_clicks)
export_csv(per_month_and_thing, "flattr-revenue-clicks.csv")

# order by time and domain
per_month_and_domain <- per_month_and_domain[order(per_month_and_domain$domain),]
per_month_and_domain$EUR_per_click <- (per_month_and_domain$all_revenue / per_month_and_domain$all_clicks)
export_csv(per_month_and_domain, "flattr-revenue-clicks-domain.csv")

# summarize & export revenue per month
per_month <- ddply(raw, "period", summarize, all_clicks = sum(clicks), all_revenue = sum(revenue))
per_month <- per_month[order(per_month$period),]
per_month$EUR_per_click <- (per_month$all_revenue / per_month$all_clicks)
export_csv(per_month, "flattr-revenue-months.csv")

# length of dataset = number of periods = months
N_months <- dim(per_month)[1]


# themeing function for following plots
{
  set_advanced_theme <- function(){
    theme(axis.text = element_text(size = N_months),
          axis.text.x = element_text(angle = 30, hjust = 1),  # hjust prevents overlap with panel; learned from http://stackoverflow.com/a/1331400
          axis.title.x = element_blank(), # remove axis title, because months labels are unambiguous already
          axis.title.y = element_text(size = N_months*1.2),
          panel.grid.major = element_line(color = "lightgrey", size = N_months/40),
          panel.grid.minor.x = element_blank(),
          panel.grid.major.y = element_line(color = "lightgrey", size = N_months/40),
          panel.background = element_rect(fill = "white"),
          complete = FALSE)} # learned from http://docs.ggplot2.org/0.9.3/theme.html
}


# plot clicks over time, colored by thing, with trendlines for everything & best thing
per_month_and_thing$EUR_per_click <- (per_month_and_thing$all_revenue / per_month_and_thing$all_clicks)
best_thing <- subset(per_month_and_thing, title == per_thing[1,1])  #  reduces data frame to best thing, for later trendline

flattr_plot <- ggplot(data = per_month_and_thing,
                      aes(x = period, y = EUR_per_click,
                          size = per_month_and_thing$all_revenue,  #  point sizes in bublechart
                          colour = factor(title))) + 
  geom_jitter() + 
  ylab("EUR per Flattr") +
  labs(color = "Flattred Things", size = "EUR per Thing") +  #  set legend titles; arguments have to be same as in ggplot() call
  stat_smooth(mapping = aes(best_thing$period, best_thing$EUR_per_click, size = best_thing$all_revenue),
              data = best_thing, method = "auto", show_guide = FALSE, size = N_months/20, 
              se = FALSE,  #  confidence interval indicator
              linetype = "dashed") +   # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
  stat_smooth(aes(group = 1),  # plots trendline over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
              method = "auto", se = FALSE, color = "darkgrey", show_guide = FALSE, size = N_months/20) +
  scale_y_continuous(limits = c(0,max(per_month_and_thing$EUR_per_click) * 1.1), expand = c(0, 0)) +  # limit y axis to positive values with 10% overhead & remove blank space around data; learned from http://stackoverflow.com/a/26558070
  scale_x_date(labels = date_format(format = "%b '%y"),  # month name abbr. & short year
               breaks = "1 month",  # force major gridlines; learned from http://stackoverflow.com/a/9742126
               expand = c(0.01, 0.01)) +  # limit y axis to positive values with 10% overhead & remove blank space around data; learned from http://stackoverflow.com/a/26558070
  guides(col = guide_legend(reverse = TRUE)) +  # aligns legend order with col(our) order in plot; learned from http://docs.ggplot2.org/0.9.3.1/guide_legend.html
  set_advanced_theme()
flattr_plot
export_plot(flattr_plot, "flattr-revenue-clicks.png", height_modifier = 12)


monthly_advanced_plot <- ggplot(data = per_month_and_thing, aes(x = period, y = all_revenue, fill = factor(title))) +
  geom_bar(stat = "identity") +
  ylab("EUR received") +
  xlab(NULL) +  # learned from http://www.talkstats.com/showthread.php/54720-ggplot2-ylab-and-xlab-hell?s=445d87d53add5909ac683c187166c9fd&p=154224&viewfull=1#post154224
  labs(fill = "Flattr-Things") +
  scale_y_continuous(limits = c(0,max(per_month$all_revenue) * 1.1), expand = c(0, 0)) +
  scale_x_date(expand = c(0, 0)) +
  guides(fill = guide_legend(reverse = TRUE)) +  # aligns legend order with fill order of bars in plot; learned from http://www.cookbook-r.com/Graphs/Legends_%28ggplot2%29/#kinds-of-scales
  set_advanced_theme()
monthly_advanced_plot
export_plot(monthly_advanced_plot, "flattr-revenue-months.png", height_modifier = 15)


monthly_advanced_domain_plot <- ggplot(data = per_month_and_domain, aes(x = period, y = all_revenue, fill = factor(domain))) +
  geom_bar(stat = "identity") +
  ylab("EUR received") +
  xlab(NULL) +  # learned from http://www.talkstats.com/showthread.php/54720-ggplot2-ylab-and-xlab-hell?s=445d87d53add5909ac683c187166c9fd&p=154224&viewfull=1#post154224
  labs(fill = "Domains") +
  scale_y_continuous(limits = c(0,max(per_month$all_revenue) * 1.1), expand = c(0, 0), breaks = seq(0, round(max(per_month$all_revenue)*1.1), round(max(per_month$all_revenue)/10))) +
  scale_x_date(labels = date_format("%b '%y"), breaks = date_breaks(width = "1 month"), expand = c(0, 0)) +
  guides(fill = guide_legend(reverse = TRUE)) +  # aligns legend order with fill order of bars in plot; learned from http://www.cookbook-r.com/Graphs/Legends_%28ggplot2%29/#kinds-of-scales
  set_advanced_theme()
monthly_advanced_domain_plot
export_plot(monthly_advanced_domain_plot, "flattr-revenue-months-domain.png", height_modifier = 15)


monthly_simple_plot <- ggplot(data = per_month_and_thing, aes(x = period, y = all_revenue)) +
  geom_bar(stat = "identity", group = 1, fill = "#ED8C3B") + 
  ylab("EUR received") + xlab(NULL) + 
  stat_smooth(data = per_month, method = "auto", color = "#80B04A", size = N_months/5) +  # draws a fitted trendline with confidence interval
  scale_y_continuous(limits = c(0,max(per_month$all_revenue) * 1.1), expand = c(0, 0)) +
  set_advanced_theme()
monthly_simple_plot
ggsave("flattr-revenue-months-summarized.png", monthly_simple_plot)

# restore original working directory; useful if you use other scripts in parallel
#setwd(original_wd)
