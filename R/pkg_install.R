
# packages for regular running
install_packages <- function() {
  
  pkgs <- c("dplyr", "purrr", "readr", "tidyr", "rtweet", "jsonlite", "sf",
            "janitor", "lubridate", "stringr", "data.table", "suncalc", "cli")
  
  install.packages(pkgs)
  invisible(NULL)
  
}