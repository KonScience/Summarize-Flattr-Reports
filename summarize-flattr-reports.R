# Please read https://github.com/KonScience/Summarize-Flattr-Reports#summarize-flattr-reports

rm(list = ls())  # clean workspace
Sys.setlocale("LC_ALL", "UTF-8")  # respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/
options(stringsAsFactors = FALSE, limitsize = FALSE) # set global options; row.names = FALSE has no effect, though

# see http://www.r-bloggers.com/library-vs-require-in-r/ for require() vs. library() discussion
library(ggplot2)
write.csv2(x = raw, file = "flattr-revenue-000000.csv", row.names = FALSE)
raw <- readr::read_csv2("Summarize-Flattr-Reports/data/KonScience-fflattr-revenue.csv")

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$EUR_per_click <- raw$revenue / raw$clicks

# populate raw data with all_revenue for each thing
for (i in 1:nrow(raw)){raw$all_revenue[i] <- sum(subset(raw, title == raw$title[i])$revenue)}

# determine dataset size to auto-adjust plots
N_months <- length(Flattr_filenames)
N_things <- length(unique(raw$title))



date <- format(Sys.time(), "%Y-%m-%d")

export_csv <- function(table, filename){
  write.csv2(table, paste0(filename, "-", date, ".csv"),
             row.names = FALSE)}

export_png <- function(p, fn, h = par("din")[2], w = par("din")[1]){
  ggsave(filename = paste0(fn, "-", date, ".png"),
         plot = p, height = h, width = w)
  return(p)}


# summarize & order by title to account for changes in Thing ID and URLs (due to redirection after permalink changes)
per_thing <- ddply(.data = raw,
                   .variables = "title",
                   .fun = summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue))
per_thing <- per_thing[order(per_thing$all_revenue, decreasing = TRUE),]
export_csv(per_thing, "flattr-revenue-things")

# summarize & order by month and thing to provide click-value development over time
per_month_and_thing <- ddply(raw,
                             c("period", "title", "EUR_per_click"),
                             summarize,
                             all_clicks = sum(clicks),
                             all_revenue = sum(revenue))
per_month_and_thing <- per_month_and_thing[order(per_month_and_thing$title),]
export_csv(per_month_and_thing, "flattr-revenue-clicks")
raw$period <- lubridate::as_date(paste0(raw$period, "-01"), format = "%Y-%m-%d")

# summarize & export revenue per month
per_month <- plyr::ddply(raw,
                   "period",
                   plyr::summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue))
per_month <- per_month[order(per_month$period),]
export_csv(per_month, "flattr-revenue-months")

# revenue per click and month coloured by thing, with trends for everything & best thing
best_thing <- subset(per_month_and_thing, title == per_thing[1,1])  #  reduces data frame to best thing, for later trendline
best_thing$EUR_per_click <- best_thing$all_revenue / best_thing$all_clicks

flattr_plot <- ggplot(data = raw,
                      mapping = aes(x = period,
                                    y = EUR_per_click,
                                    size = raw$revenue,  #  points sized according to revenue of that thing in that month => bubble plot
                                    colour = factor(title)))
export_png(flattr_plot  +
             geom_jitter()  +  # same as geom_point(position = "jitter"); spreads data points randomly around true x value bit; day-exact resolution not (yet) possible
             stat_smooth(mapping = aes(x = best_thing$period,
                                       y = best_thing$EUR_per_click,
                                       size = best_thing$all_revenue),
                         data = best_thing,
                         method = "auto",
                         show.legend = FALSE,
                         size = N_things / N_months,
                         se = FALSE,  #  confidence interval indicator
                         linetype = "dashed")  +   # learned from http://sape.inf.usi.ch/quick-reference/ggplot2/linetype
             stat_smooth(aes(group = 1),  # plots trendline over all values; otherwise: one for each thing; learned from http://stackoverflow.com/a/12810890
                         method = "auto",
                         se = FALSE,
                         color = "darkgrey",
                         show.legend = FALSE,
                         size = N_months / 20)  +
             scale_x_date(labels = date_format("%Y-%b"), expand = c(0, 0))  +
             scale_y_continuous(limits = c(0, mean(raw$EUR_per_click) * 5),  # omit extreme y-values; learned from http://stackoverflow.com/a/26558070
                                expand = c(0, 0))  +
             labs(title = "Development of Flattr Revenue per Click",  # learned from http://docs.ggplot2.org/current/labs.html
                  x = NULL,
                  y = expression("EUR per Flattr (extremes omitted)"),
                  colour = "Thing",
                  size = "Total revenue of Thing")  +
             theme_classic(base_size = sqrt(N_months + N_things))  +
             theme(legend.position = "none", axis.text.x = element_text(angle = 15)),
           "flattr-revenue-clicks")

# revenue per month and thing
monthly_advanced_plot <- ggplot(per_month_and_thing, aes(period, all_revenue, fill = factor(title)))
export_png(monthly_advanced_plot  +
             geom_bar(stat = "identity")  +
             scale_x_date(expand = c(0, 0), labels = date_format("%Y-%b"))  +
             scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1), expand = c(0, 0))  +
             guides(fill = guide_legend(reverse = TRUE))  +
             labs(title = "Development of Flattr Revenue by Things", x = NULL, y = "EUR received", fill = "Thing")  +
             theme_classic(base_size = (N_things + N_months) / 5),
           "flattr-revenue-months",
           N_things/3,
           N_months/1.5)

# total revenue per month with trend
monthly_simple_plot <- ggplot(per_month, aes(x = period, y = all_revenue, size = per_month$all_revenue))

export_png(monthly_simple_plot +
             geom_point(colour = "#ED8C3B")  +
             stat_smooth(data = per_month, method = "auto", color = "#80B04A", size = N_things / N_months)  +  # fit trend plus confidence interval
             scale_x_date(expand = c(0, 0), labels = scales::date_format("%Y-%b"))  +
             scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1), expand = c(0, 0))  +
             labs(title = "Development of Flattr Revenue", x = NULL, y = "EUR received")  +
             theme_classic(base_size = sqrt(N_things + N_months))  +
             theme(axis.text.x = element_text(angle = 15), legend.position = "none"),
           "flattr-revenue-months-summarized")


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
export_png(monthly_domain_plot  +
             geom_bar(stat = "identity")  +
             scale_x_date(expand = c(0,0), labels = date_format("%Y-%b"))  +
             scale_y_continuous(limits = c(0, max(per_month$all_revenue)), expand = c(0, 0))  +
             scale_fill_brewer(type = "qual")  +
             guides(fill = guide_legend(reverse = TRUE, keywidth = 0.75, keyheight = 0.75))  +
             labs(title = "Development of Flattr Revenue by Button Locations", x = NULL, y = "EUR", fill = "Domains")  +
             theme_classic(base_size = sqrt(N_things + N_months))  +
             theme(axis.text.x = element_text(angle = 30)),
           "flattr-revenue-months-domain")

monthly_domain_plot_fractions <- ggplot(per_month_and_domain, aes(period, all_revenue, fill = factor(domain)))
export_png(monthly_domain_plot_fractions +
             geom_bar(position = "fill", stat = "identity")  +
             scale_x_date(expand = c(0,0), labels = date_format("%Y-%b"))  +
             scale_y_continuous(expand = c(0, 0))  +
             scale_fill_brewer(type = "qual")  +
             guides(fill = guide_legend(reverse = TRUE, keywidth = 0.75, keyheight = 0.75))  +
             labs(title = "Development of Flattr Revenue by Button Locations",
                  x = NULL, y = "Fraction", fill = "Domains")  +
             theme_classic(base_size = sqrt(N_things + N_months)) +
             theme(axis.text.x = element_text(angle = 30)),
           "flattr-revenue-months-domain-fractions")

# sort & export after plotting in order to preserve alphabatic sorting in of domains in plot
per_month_and_domain <- per_month_and_domain[order(per_month_and_domain$all_revenue),]
export_csv(per_month_and_domain, "flattr-revenue-clicks-domain")
