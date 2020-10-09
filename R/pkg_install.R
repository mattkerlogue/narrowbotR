
# packages for regular running
install_runner_packages <- function() {

  pkgs <- c("dplyr", "purrr", "readr", "tidyr", "rtweet",
            "janitor", "lubridate", "stringr", "suncalc")
  
  install.packages(pkgs)
  invisible(NULL)
  
}

# packages for maintenance
# as runner but with sf
install_maintenance_packages <- function() {

pkgs <- c("dplyr", "purrr", "readr", "tidyr", "rtweet", "sf",
          "janitor", "lubridate", "stringr", "suncalc")

install.packages(pkgs)
invisible(NULL)

}