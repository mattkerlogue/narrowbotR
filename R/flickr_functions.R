# Get information about a specific photo
flickr_get_photo_info <- function(key = NULL, photo_id, photo_secret) {
  
  if (is.null(key)) {
    key <- Sys.getenv("FLICKR_API_KEY")
    if (key == "") {
      stop("Flickr API key not set")
    }
  }
  
  if (missing(photo_id)) {
    stop("photo_id missing")
  }
  
  if (missing(photo_secret)) {
    stop("photo_secret missing")
  }
  
  # create flickr api url
  url <- paste0(
    "https://www.flickr.com/services/rest/?method=flickr.photos.getInfo",
    "&api_key=", key,
    "&photo_id=", photo_id,
    "&secret=", photo_secret,
    "&format=json",
    "&nojsoncallback=1")
  
  # get data
  r <- jsonlite::fromJSON(url)
  
  # extract relevant info
  info <- tibble::tibble(
    username = r$photo$owner$username,
    realname = r$photo$owner$realname,
    licence = r$photo$license,
    description = r$photo$description$`_content`,
    date = lubridate::as_datetime(r$photo$dates$taken),
    can_download = r$photo$usage$candownload,
    can_share = r$photo$usage$canshare
  )
  
  return(info)
  
}

# Get the 100 closest photos to the desired position and pull info
flickr_get_photo_list <- function(key = NULL, lat, long) {

  if (is.null(key)) {
    key <- Sys.getenv("FLICKR_API_KEY")
    if (key == "") {
      stop("Flickr API key not set")
    }
  }
  
  if (missing(lat)) {
    stop("lat missing")
  }
  
  if (missing(long)) {
    stop("long missing")
  }
  
  # construct flickr api url
  # using lat/long will sort in geographical proximity
  # choose within 100m of the position (radius=0.1)
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
    "&radius=0.1",
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
                                         photo_secret = .y))
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

