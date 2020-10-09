# load functions
library(dplyr)
source("R/post_geo_tweet.R")
source("R/flickr_functions.R")

message("Stage: functions loaded")

# create twitter token
narrowbotr_token <- rtweet::create_token(
  app = "narrowbotr",
  consumer_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

message("Stage: Twitter token created")

# load points data
all_points <- readRDS("data/all_points.RDS")

# pick a point
place <- all_points %>%
  dplyr::select(-geometry) %>%
  dplyr::filter(feature == "locks") %>%
  dplyr::sample_n(1) %>%
  as.list()

message("Stage: Picked a place [", place$name, ", lat: ", place$lat, ", long: ", place$long, "]")

place_photos <- flickr_get_photo_list(lat = place$lat, long = place$long)

message("Stage: Got photos")

if (is.null(place_photos)) {
  photo_select <- NULL
  message("Stage: No photo selected\n")
} else {
  photo_select <- flickr_pick_photo(place_photos)
  message("Stage: Photo selected\n")
}

tmp_file <- tempfile()

if (is.null(photo_select)) {
  img_url <- paste0(
    "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/",
    paste0(place$long, ",", place$lat, ",", 16),
    "/600x400?access_token=",
    Sys.getenv("MAPBOX_PAT")
  )
} else {
  img_url <- photo_select$img_url
}

download.file(img_url, tmp_file)

message("Stage: Photo downloaded")

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
} else {
  tweet_text <- c(
    base_message, "\n",
    "📸: Photo by ", str_squish(photo_select$realname), " on Flickr ",
    photo_select$photo_url)
}

status_msg <- paste0(tweet_text, collapse = "")

message("Stage: Tweet written")

post_geo_tweet(
  status = status_msg,
  media = tmp_file,
  lat = place$lat,
  long = place$long
  )

message("Stage: Action complete")