#' Plot Flattr Months
#'
#' @param data
#'
#' @return
#' @export
#'
#' @examples
plot_Flattr_months <- function(data = FlattRep_df) {

  FlattRep_df %>%
    summarise_flattr_months() %>%
    ggplot(aes(x = period, y = all_revenue, size = all_revenue)) +
    geom_point(colour = "#ED8C3B")  +
    stat_smooth(colour = "#80B04A")  +  # fit trend plus confidence interval
    scale_x_date(labels = scales::date_format("%Y-%b"))  +
    labs(title = "Flattr Revenue", x = NULL, y = "EUR received")  +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 15),
          axis.ticks = element_line(),
          legend.position = "none") -> p

    return(p)
}
