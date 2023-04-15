# functions to interact with the flickr API

# get photos based on a given lat/long
photos_for_location <- function(lat, long, key = NULL) {
  
  # get flickr key if not provided
  if (is.null(key)) {
    key <- Sys.getenv("FLICKR_API_KEY")
    if (key == "") {
      stop("Flickr API key not set")
    }
  }
  
  # check for lat/long
  if (missing(lat)) {
    stop("lat missing")
  }
  
  if (missing(long)) {
    stop("long missing")
  }
  
  # construct flickr api call
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
    "&extras=description%2Clicense%2Cdate_taken%2Cowner_name%2Ctags",
    "&format=json",
    "&nojsoncallback=1"
  )
  
  # get flickr api response
  response <- jsonlite::fromJSON(url)
  
  # get photos dataset
  if (response$photos$total == 0) {
    message("No photos at location")
    photos <- NULL
  } else if (length(response$photos$photo) == 0) {
    message("No photos at location (photos list empty)")
    photos <- NULL
  } else {
    photos <- response$photos$photo |>
      tidyr::unnest(description) |>
      dplyr::rename(description = `_content`) |>
      dplyr::mutate(distance = dplyr::row_number())
  }
  
  return(photos)
  
}

# clean a character string for processing
clean_string <- function(string) {
  
  # remove HTML
  string <- gsub("<.+?>", "", tolower(string))
  # remove newlines
  string <- gsub("\\n", " ", string)
  # remove punctuation
  string <- gsub("[[:punct:]]", "", string)
  # remove double spaces
  string <- gsub("  ", " ", string)
  
  return(string)
  
}

# count the number of words in a string
n_words <- function(string) {
  
  if (string == "") {
    words <- 0
  } else {
    string <- clean_string(string)
    words <- stringr::str_count(string, "\\b")/2
  }
  
  return(words)
}

# count the number of canal words in a string
canal_words_count <- function(string) {
  
  # words to detect
  canal_words <- c(
    # canal terminology
    "aqueduct", "bank", "barge", "beam", "boat", "canal", "channel", "cut",
    "cruise", "cruising", "dingle", "flight", "embankment", "gate",
    "gongoozl", "junction", "keeper", "lock", "marina", "mooring", "narrow",
    "navv", "paddle", "piling", "pound", "quay", "quayside", "river", "sluice",
    "towpath", "tunnel", "water", "weir", "winding", "windlass",
    # wildlife
    "badger", "bat", "bee", "bird", "butterfly", "coot", "comorant",
    "damselfly", "dormouse", "dragonfly", "duck", "frog", "goose",
    "grasshopper", "grass snake", "heron", "kestrel", "kingfisher",
    "mallard", "newt", "otter", "owl", "polecat", "stoat", "swan", "vole",
    "fox",
    # landscape/heritage
    "mill", "industr", "heritage", "historic", "transport", "landscape", 
    "field", "textile", "coal", "cargo", "warehouse", "reservoir", "pump"
  )
  
  # simplify string
  string <- clean_string(string)
  
  # count how many canal words are in the string
  canal_count <- sum(
    purrr::map_dbl(
      canal_words,
      ~stringr::str_detect(string, .x)
    )
  )
  
  return(canal_count)
  
}

# determine and score the time of day
eval_time <- function(date_taken, lat, long) {
  
  timestamp <- as.POSIXct(date_taken)
  
  sun_times <- suncalc::getSunlightTimes(
    as.Date(timestamp), 
    lat = lat, lon = long, 
    keep = c("sunrise", "goldenHourEnd", "goldenHour", "sunset")
  )
  
  sun_score <- dplyr::as_tibble(sun_times) |>
    dplyr::mutate(
      ts = timestamp,
      sun_value = dplyr::case_when(
        ts < sunrise ~ 0,        # ignore photos before sunrise
        ts < goldenHourEnd ~ 2,  # photos in morning golden hour
        ts < goldenHour ~ 1,     # photos in regular daytime
        ts < sunset ~ 2,         # photos in evening golden hour
        TRUE ~ 0                 # ignore photos after sunset
      )
    )
  
  return(sun_score$sun_value)
  
}

# simple rescale function taken from scales::rescale.numeric
# to avoid having to install and load the scales package
rescale <- function (x, to = c(0, 1)) {
  
  if (length(unique(x)) == 1) {
    return(1)
  }
  
  from <- range(x)
  
  rx <- (x - from[1])/diff(from) * diff(to) + to[1]
  
  return(rx)
  
}

# get a photo from flickr
get_flickr_photo <- function(lat, long, key = NULL) {
  
  # get photos for the location
  photos <- photos_for_location(lat, long, key)
  
  if (is.null(photos)) {
    return(NULL)
  }
  
  # generate photo metrics
  scored_photos <- photos |>
    dplyr::select(id, title, description, datetaken, tags, distance) |>
    dplyr::mutate(
      title_words = purrr::map_dbl(title, n_words),
      description_words = purrr::map_dbl(description, n_words),
      word_score = title_words + log(max(description_words, 1)),
      canal_title = purrr::map_dbl(title, canal_words_count),
      canal_description = purrr::map_dbl(description, canal_words_count),
      canal_tags = purrr::map_dbl(tags, canal_words_count),
      canal_score = max(1, (canal_title + canal_description + canal_tags)),
      sun_value = eval_time(datetaken, lat, long),
      time_offset = as.numeric(Sys.time() - as.POSIXct(datetaken))
    ) |>
    dplyr::filter(time_offset <= 5000)
  
  # return NULL if all photos filtered out
  if (nrow(scored_photos) == 0) {
    return(NULL)
  }
  
  # finish scoring the photos
  scored_photos <- scored_photos |>
    dplyr::mutate(
      distance_score = rev(sqrt(distance)),
      offset_score = rev(rescale(time_offset, c(5,1))),
      photo_score = word_score * canal_score * sun_value * 
        distance_score * offset_score
    ) |>
    dplyr::arrange(-photo_score) |>
    dplyr::filter(photo_score > 0)
  
  # return NULL if all photos filtered out
  if (nrow(scored_photos) == 0) {
    return(NULL)
  }
  
  # get id of selected photo
  selected_photo_id <- scored_photos |>
    dplyr::slice_max(photo_score, n = 1) |>
    dplyr::sample_n(size = 1) |>
    dplyr::pull(id)
  
  # get details of selected photo
  selected_photo <- photos |>
    dplyr::filter(id == selected_photo_id) |>
    dplyr::mutate(
      photo_url = paste("https://www.flickr.com/photos", 
                        owner, 
                        id,
                        sep = "/"),
      img_url = paste0("https://live.staticflickr.com/",
                       server, "/",
                       id,"_",secret,".jpg")
    ) |>
    dplyr::select(id, owner, ownername, title, tags, photo_url, img_url) |>
    as.list()
  
  if (nchar(selected_photo$tags) < 3) {
    selected_photo$tags <- NULL
  } else {
    selected_photo$tags <- paste0("#", strsplit(selected_photo$tags, " ")[[1]])
  }
  
  return(selected_photo)
  
}

# download with error handling
safe_download <- function(url, dest) {
  tryCatch(
    error = function(cnd) {
      NULL
    },
    {
      download.file(url, dest, quiet = TRUE)
      url
    }
  )
}

# download photo from Flickr or Mapbox
download_photo <- function(flickr_url = NULL, mapbox_url = NULL, dest = NULL) {
  
  # check for URLs
  if (is.null(flickr_url) & is.null(mapbox_url)) {
    stop("No photo service URLs provided")
  }
  
  # check for destination
  if (is.null(dest)) {
    stop("No destination file set")
  }
  
  res <- NULL
  download <- 0
  
  # if given try to download the flickr photo
  if (!is.null(flickr_url)) {
    res <- safe_download(flickr_url, dest)
    download <- 1
    message("Flickr photo downloaded")
  }
  
  # try to download a photo from mapbox
  if (is.null(res) & !is.null(mapbox_url)) {
    res <- safe_download(mapbox_url, dest)
    if (!is.null(res)) {
      download <- 2
      if (!is.null(flickr_url)) {
        message("Flickr download failed, Mapbox photo downloaded")
      } else {
        message("Mapbox photo downloaded")
      }
    } else {
      stop("Failed to download a photo from Flickr or Mapbox")
    }
  } else if (is.null(res) & is.null(mapbox_url)) {
    stop("Flickr download failed, Mapbox URL is NULL")
  }
  
  return(download)
  
}

