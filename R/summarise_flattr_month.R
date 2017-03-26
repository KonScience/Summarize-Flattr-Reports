#' Summarise Flattr Months
#'
#' @param data The tibble `FlattRep_df` produced by `read_flattr_csv()`
#'
#' @return
#'
summarise_flattr_months <- function(data = FlattRep_df) {
  return(plyr::ddply(.data = FlattRep_df,
                     .variables = "period",
                     plyr::summarize,
                     all_clicks = sum(clicks),
                     all_revenue = sum(revenue))
  )
}
