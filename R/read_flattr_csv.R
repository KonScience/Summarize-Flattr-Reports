#' Read Flattr-CSVs
#'
#' @InheritParams base::list.files Param path
#'
#' @return FlattRep_df
#' A tibble of all Flattr Revenue Reports in or below the current working dir,
#' combined by row.
#'
#' @export
#'
read_flattr_csv <- function(path = ".") {

  list.files(path = path, pattern = "flattr-revenue-20[0-9]{4}.csv") %>%
    purrr::map_df(.f = readr::read_csv2) ->
    FlattRep_df

  # append 1st days to months & convert to date format
  # learned from http://stackoverflow.com/a/4594269
  FlattRep_df$period <- lubridate::as_date(
    x = paste0(FlattRep_df$period, "-01"),
    format = "%Y-%m-%d")

  return(FlattRep_df)
}
