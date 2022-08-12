# load functions

cli::cli_progress_step("Load flickr functions")

library(dplyr)
source("R/flickr_functions.R")


cli::cli_progress_step("Get rtweet token")

# create twitter token
narrowbotr_token <- rtweet::rtweet_bot(
  api_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  api_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

cli::cli_progress_step("Select location")

# load points data
all_points <- readRDS("data/all_points.RDS")

# pick a point
place <- all_points %>%
  dplyr::select(-geometry) %>%
  dplyr::filter(stringr::str_detect(feature, "culvert", negate = TRUE)) %>%
  dplyr::sample_n(1) %>%
  as.list()

cli::cli_alert(
  "Picked {place$name}, lat: {.val {round(place$lat,4)}}, long: {.val {round(place$long,4)}}"
)

cli::cli_progress_step("Get photo")

place_photos <- flickr_get_photo_list(lat = place$lat, long = place$long)

if (is.null(place_photos)) {
  photo_select <- NULL
  cli::cli_alert_warning("No flickr photo available")
} else {
  photo_select <- flickr_pick_photo(place_photos)
}

tmp_file <- tempfile(fileext = ".jpg")

if (is.null(photo_select)) {
  mapbox_url <- paste0(
    "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/",
    paste0(place$long, ",", place$lat, ",", 16),
    "/600x400?access_token=",
    Sys.getenv("MAPBOX_PAT")
  )
  img_url <- mapbox_url
} else {
  img_url <- photo_select$img_url
}

photo_success <- download.file(img_url, tmp_file)

if (!is.null(photo_select) & photo_sucess != 0) {
  cli::cli_alert_warning("Flickr download failed, attempting Mapbox")
  photo_success <- download.file(mapbox_url, tmp_file)
  photo_select <- NULL
}

if (photo_success == 0) {
  cli::cli_abort("Unable to download photo. Ending bot instance.")
}

cli::cli_progress_step("Construct tweet")

base_message <- c(
  "📍: ", place$name, "\n",
  "ℹ️: ", place$obj_type_label, "\n",
  "🗺: ",  paste0("https://www.openstreetmap.org/",
                  "?mlat=", place$lat,
                  "&mlon=", place$long,
                  "#map=17/", place$lat, "/", place$long)
)

if (is.null(photo_select)) {
  tweet_text <- base_message
  alt_msg <- paste0("A satellite image of the area containing ", 
                    place$name,
                    ". Provided by MapBox.")
} else {
  tweet_text <- c(
    base_message, "\n",
    "📸: Photo by ", stringr::str_squish(photo_select$realname), " on Flickr ",
    photo_select$photo_url)
  alt_msg <- paste0(
    "A photo taken near ", 
    place$name,
    " by ", 
    stringr::str_squish(photo_select$realname),
    " on Flickr."
    )
}

status_msg <- paste0(tweet_text, collapse = "")

cli::cli_progress_step("Post tweet")

rtweet::post_tweet(
  status = status_msg,
  media = tmp_file, 
  media_alt_text = alt_msg,
  lat = place$lat,
  long = place$long,
  token = narrowbotr_token
)

cli::cli_progress_done()

cli::cli({
  cli::cli_h1("narrowbot completed")
  cli::cli_verbatim(status_msg)
})
