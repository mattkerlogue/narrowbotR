flickr_get_photo_info <- function(key, photo_id, secret) {
  
  # create flickr api url
  url <- paste0(
    "https://www.flickr.com/services/rest/?method=flickr.photos.getInfo",
    "&api_key=", key,
    "&photo_id=",photo_id,
    "&secret=",secret,
    "&format=json",
    "&nojsoncallback=1")
  
  # get data
  r <- jsonlite::fromJSON(url)
  
  # extract relevant info
  info <- tibble::tibble(
    username = r$photo$owner$username,
    licence = r$photo$license,
    description = r$photo$description$`_content`,
    date = lubridate::as_datetime(r$photo$dates$taken),
    can_download = r$photo$usage$candownload,
    can_share = r$photo$usage$canshare
  )
  
  return(info)
  
}


flickr_get_photo_list <- function(key, lat, long) {
  
  # construct flickr api url
  url <- paste0(
    "https://www.flickr.com/services/rest/?method=flickr.photos.search",
    "&api_key=", key,
    "&license=1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9%2C10",
    "&privacy_filter=1",
    "&safe_search=1",
    "&content_type=1",
    "&media=photos",
    "&lat=", lat,
    "&lon=", long,
    "&radius=0.2",
    "&per_page=100",
    "&page=1",
    "&format=json",
    "&nojsoncallback=1"
  )
  
  # get data
  r <- jsonlite::fromJSON(url)
  
  # extract the photo data
  p <- r$photos$photo
  
  # get info for photos, add sunlight hours
  # drop photos before sunrise or after sunset
  p <- p %>% 
    mutate(
      info = map2(id, secret, 
                  ~flickr_get_photo_info(key = key, 
                                         photo_id = .x, 
                                         secret = .y))
      ) %>%
    unnest(info) %>%
    mutate(
      suntimes = map(
        as.Date(date), 
        ~suncalc::getSunlightTimes(date = .x, lat = lat, lon = long, 
                                   keep = c("sunrise", "goldenHourEnd", 
                                            "goldenHour", "sunset"))),
      suntimes = map(suntimes, ~select(.x, -date, -lat, -lon))
      ) %>% 
    unnest(suntimes) %>%
    mutate(after_sunset = date > sunset, 
           before_sunrise = date < sunrise, 
           goldenhour = if_else(
             (date >= sunrise & date <= goldenHourEnd) | 
               (date <= sunset & date >= goldenHour), TRUE, FALSE)) %>% 
    filter(!after_sunset) %>%
    filter(!before_sunrise)
  
  return(p)
  
}

