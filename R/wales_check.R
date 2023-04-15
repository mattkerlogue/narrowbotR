check_in_wales <- function(lat, long, wales_sf) {
  
  chk_point <- sf::st_sfc(
    sf::st_point(c(long, lat), dim = "XY"),
    crs = sf::st_crs("WGS84")
  )
  
  in_wales <- as.numeric(sf::st_covered_by(chk_point, wales_sf))
  
  if (is.na(in_wales)) {
    return(FALSE)
  } else if (in_wales == 1) {
    return(TRUE)
  } else {
    return(FALSE)
  }
  
}
