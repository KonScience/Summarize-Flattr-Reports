# respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/
Sys.setlocale("LC_ALL", "UTF-8")

library(ggplot2)
library(magrittr)

raw <- readr::read_csv2("Summarize-Flattr-Reports/data/KonScience-fflattr-revenue.csv")

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$period <- lubridate::as_date(paste0(raw$period, "-01"), format = "%Y-%m-%d")

# summarize & export revenue per month
plyr::ddply(raw,
                   "period",
                   plyr::summarize,
                   all_clicks = sum(clicks),
                   all_revenue = sum(revenue)) %>%

# total revenue per month with trend
  ggplot(aes(x = period, y = all_revenue, size = all_revenue)) +
             geom_point(colour = "#ED8C3B")  +
             stat_smooth(data = per_month, method = "auto", color = "#80B04A")  +  # fit trend plus confidence interval
             scale_x_date(expand = c(0, 0), labels = scales::date_format("%Y-%b"))  +
             scale_y_continuous(limits = c(0, max(per_month$all_revenue) * 1.1), expand = c(0, 0))  +
             labs(title = "Development of Flattr Revenue", x = NULL, y = "EUR received")  +
             theme(axis.text.x = element_text(angle = 15), legend.position = "none") ->
monthly_simple_plot

plotly::ggplotly(monthly_simple_plot)
