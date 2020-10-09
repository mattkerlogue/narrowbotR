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
  
  # skip if less than 10 photos returned
  # suggests uninteresting/remote place
  if (length(p) < 10) {
    p <- NULL
  } else {
    
    # get info for photos, add sunlight hours
    # drop photos before sunrise or after sunset
    p <- p %>% 
      dplyr::mutate(
        info = purrr::map2(id, secret, 
                           ~flickr_get_photo_info(key = key, 
                                                  photo_id = .x, 
                                                  photo_secret = .y))
      ) %>%
      tidyr::unnest(info) %>%
      dplyr::mutate(
        suntimes = purrr::map(
          as.Date(date), 
          ~suncalc::getSunlightTimes(date = .x, lat = lat, lon = long, 
                                     keep = c("sunrise", "goldenHourEnd", 
                                              "goldenHour", "sunset"))),
        suntimes = purrr::map(suntimes, ~dplyr::select(.x, -date, -lat, -lon))
      ) %>% 
      tidyr::unnest(suntimes) %>%
      dplyr::mutate(after_sunset = date > sunset, 
                    before_sunrise = date < sunrise, 
                    goldenhour = dplyr::if_else(
                      (date >= sunrise & date <= goldenHourEnd) | 
                        (date <= sunset & date >= goldenHour), TRUE, FALSE)) %>% 
      dplyr::filter(!after_sunset) %>%
      dplyr::filter(!before_sunrise)
    
  }
  
  return(p)
  
}

# count canal words
canal_word_count <- function(string) {
  
  canal_words <- c("canal", "lock", "water", "boat", "gate", "bird", "duck", 
                   "swan", "river", "aqueduct", "towpath", "barge", "keeper",
                   "tunnel")
  
  counter <- 0
  
  for (word in canal_words) {
    x <- stringr::str_detect(tolower(string), word)
    counter <- counter + x
  }
  
  return(counter)
  
}

# simple rescale function taken from scales::rescale.numeric
# to avoid having to install and load the scales package
rescale <- function (x, to = c(0, 1)) {
  
  from <- range(x)
  
  rx <- (x - from[1])/diff(from) * diff(to) + to[1]
  
  return(rx)
  
}

# score photos
# The scoring algorithm takes into account:
#   * the approx length of titles and 
#   descriptions (descriptions are logged to benefit titles and not to 
#   over-reward verbose descriptions),
#   * the number of canal related words used this seeks the range of canal 
#   words used rather than the pure count, this is then squared to make it
#   give it a high weighting,
#   * whether the time is during 'golden hour' for the location (if so, then 
#   the algorithm in effect doubles the score for that photo),
#   * distance from the location (the flickr api return is supposed to provide 
#   a list that is sorted by distance, however am unsure about this) so this is 
#   square rooted to reduce variance
#   * time offset from today, more recent photos are preferred but this 
#   censored (so that photos older than 5000 days are excluded) and is scaled 
#   to between 1 and 5 to reduce impact
#      
#   The final score is a product of these different components:
#       SCORE = WORD_SCORE * DIST_SCORE * GOLDEN_HOUR * TIME_OFFSET * CANAL_WORD_SCORE
#   
flickr_photo_score <- function(df) {
  
  n_df <- df %>%
    dplyr::select(id, owner, title, description, date, goldenhour) %>%
    dplyr::mutate(
      title_words = purrr::map_dbl(title, ~max(str_count(., " "),1)),
      desc_words = stringr::str_count(description, " "),
      total_words = title_words + desc_words,
      desc_words2 = log10(purrr::map_dbl(description, ~max(str_count(., " "),1))),
      word_score = purrr::pmap_dbl(list(title_words, desc_words2), sum, na.rm = TRUE),
      canal_words = canal_word_count(title) + canal_word_count(description),
      canal_word_score = purrr::map_dbl(canal_words^2, ~max(., 1)),
      gold = dplyr::if_else(goldenhour, 2, 1),
      offset = Sys.time() - date
      ) %>%
    dplyr::filter(offset <= 5000) %>%
    dplyr::mutate(
      distance = dplyr::row_number(),
      dist_rev = rev(sqrt(distance))
    ) %>%
    dplyr::arrange(offset) %>%
    dplyr::mutate(
      offset_rev = rev(sqrt(as.numeric(offset))),
      alt_off = rescale(as.numeric(offset), c(5,1)),
      final_score = word_score * dist_rev * gold * alt_off * canal_word_score
      ) %>%
    dplyr::select(id, owner, final_score) %>%
    dplyr::arrange(-final_score)
  
  return(n_df)
  
}

# pick and prep photo for tweet
flickr_pick_photo <- function(df) {
  
  scored_df <- flickr_photo_score(df)
  
  n_df <- df %>% 
    dplyr::inner_join(scored_df, by = c("id", "owner")) %>%
    tidyr::drop_na(final_score) %>%
    dplyr::filter(final_score == max(final_score))
  
  photo <- as.list(n_df)
  
  photo$photo_url <- paste("https://www.flickr.com/photos", 
                           photo$owner, 
                           photo$id,
                           sep = "/")
  
  photo$img_url <- paste0("https://live.staticflickr.com/",
                         photo$server, "/",
                         photo$id,"_",photo$secret,".jpg")
  
  return(photo)
  
}

