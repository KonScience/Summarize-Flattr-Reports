# respect non-ASCII symbols like German umlauts on Mac OSX, learned from https://stackoverflow.com/questions/8145886/
Sys.setlocale("LC_ALL", "UTF-8")

library(ggplot2)
library(magrittr)


# summarize & export revenue per month with trend

