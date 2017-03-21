# respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/
Sys.setlocale("LC_ALL", "UTF-8")

library(ggplot2)
library(magrittr)

list.files(pattern = "flattr-revenue-20[0-9]{4}.csv",
           full.names = TRUE) %>%
  purrr::map_df(.f = readr::read_csv2) ->
  raw

# append 1st days to months & convert to date format; learned from http://stackoverflow.com/a/4594269
raw$period <- lubridate::as_date(paste0(raw$period, "-01"), format = "%Y-%m-%d")

# summarize & export revenue per month with trend
plyr::ddply(raw,
            "period",
            plyr::summarize,
            all_clicks = sum(clicks),
            all_revenue = sum(revenue)) %>%
  ggplot(aes(x = period, y = all_revenue, size = all_revenue)) +
  geom_point(colour = "#ED8C3B")  +
  stat_smooth(data = per_month, method = "auto", color = "#80B04A")  +  # fit trend plus confidence interval
  scale_x_date(labels = scales::date_format("%Y-%b"))  +
  labs(title = "Flattr Revenue", x = NULL, y = "EUR received")  +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 15),
        axis.ticks = element_line(),
        legend.position = "none") ->
  monthly_simple_plot

plotly::ggplotly(monthly_simple_plot)
