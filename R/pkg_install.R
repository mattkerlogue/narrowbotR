
# packages for regular running
install_packages <- function() {
  
  pkgs <- c("dplyr", "purrr", "readr", "tidyr", "rtoot", "jsonlite",
            "sf", "janitor", "lubridate", "stringr", "data.table", "suncalc",
            "xml2", "bskyr")
  
  install.packages(pkgs)
  invisible(NULL)
  
}