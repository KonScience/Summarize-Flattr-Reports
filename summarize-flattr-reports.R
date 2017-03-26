# respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/
Sys.setlocale("LC_ALL", "UTF-8")

library(ggplot2)
library(magrittr)


# summarize & export revenue per month with trend
plyr::ddply(raw, .variables = "period",
            plyr::summarize,
            all_clicks = sum(clicks),
            all_revenue = sum(revenue)) %>%
  ggplot(aes(x = period, y = all_revenue, size = all_revenue)) +
  geom_point(colour = "#ED8C3B")  +
  stat_smooth(color = "#80B04A")  +  # fit trend plus confidence interval
  scale_x_date(labels = scales::date_format("%Y-%b"))  +
  labs(title = "Flattr Revenue", x = NULL, y = "EUR received")  +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 15),
        axis.ticks = element_line(),
        legend.position = "none") ->
  monthly_simple_plot

plotly::ggplotly(monthly_simple_plot)
