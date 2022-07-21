
# packages for regular running
install_runner_packages <- function() {
  
  pkgs <- c("dplyr", "purrr", "readr", "tidyr", "rtweet", "jsonlite",
            "janitor", "lubridate", "stringr", "data.table", "suncalc")
  
  install.packages(pkgs, repos = "https://cloud.r-project.org/")
  invisible(NULL)
  
}

# packages for maintenance
# as runner but with sf
install_maintenance_packages <- function() {

  install.packages("jsonlite", repos = "https://cloud.r-project.org/", type = "source")
  
  pkgs <- c("dplyr", "purrr", "readr", "tidyr", "rtweet", "sf",
            "janitor", "lubridate", "stringr", "data.table", "suncalc")

  install.packages(pkgs, repos = "https://cloud.r-project.org/")
  invisible(NULL)

}
