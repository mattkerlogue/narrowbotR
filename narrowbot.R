# narrowbotR
# An R-based Twitter bot that tweets waterway features in England & Wales from
# the Canal & River Trust network.

# set-up environment ------------------------------------------------------

# load {dplyr} and flickr functions
suppressPackageStartupMessages(library(dplyr))
source("R/flickr_functions.R")


# create twitter token
narrowbotr_token <- rtweet::rtweet_bot(
  api_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  api_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)


# select location ---------------------------------------------------------

# load points data
all_points <- readRDS("data/all_points.RDS")

# pick a point
place <- all_points %>%
  dplyr::select(-geometry) %>%
  dplyr::filter(stringr::str_detect(feature, "culvert", negate = TRUE)) %>%
  dplyr::sample_n(1) %>%
  as.list()

# tell user you have picked a place
message("Picked ", place$name, 
        ", lat: ", round(place$lat,4), 
        ", long: ", round(place$long,4))

# get photo ---------------------------------------------------------------

# get a photo from Flickr based on selected location
flickr_photo <- get_flickr_photo(place$lat, place$long)

# set the flickr photo url
if (is.null(flickr_photo)) {
  flickr_url <- NULL
} else {
  flickr_url <- flickr_photo$img_url
}

# set the mapbox photo url
mapbox_url <- paste0(
  "https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/",
  paste0(place$long, ",", place$lat, ",", 16),
  "/600x400?access_token=",
  Sys.getenv("MAPBOX_PAT")
)

# get a download location
tmp_file <- tempfile(fileext = ".jpg")

# try to download the photo
download_res <- download_photo(flickr_url, mapbox_url, tmp_file)

# construct tweet ---------------------------------------------------------

# core message info used by all tweets, name, type and OSM link
base_message <- c(
  "📍: ", place$name, "\n",
  "ℹ️: ", place$obj_type_label, "\n",
  "🗺: ",  paste0("https://www.openstreetmap.org/",
                  "?mlat=", place$lat,
                  "&mlon=", place$long,
                  "#map=17/", place$lat, "/", place$long)
)

# create alt text for tweet photo, add flickr info to tweet
if (download_res == 2) {
  tweet_text <- base_message
  alt_msg <- paste0("A satellite image of the area containing ", 
                    place$name,
                    ". Provided by MapBox.")
} else if (download_res == 1) {
  tweet_text <- c(
    base_message, "\n",
    "📸: Photo by ", stringr::str_squish(flickr_photo$ownername), " on Flickr ",
    flickr_photo$photo_url)
  alt_msg <- paste0(
    "A photo titled ", "\"", flickr_photo$title, "\"" ,", taken near ", 
    place$name,
    " by ", 
    stringr::str_squish(flickr_photo$ownername),
    " on Flickr."
    )
} else {
  stop("Something has gone wrong")
}

# create finalised tweet message
status_msg <- paste0(tweet_text, collapse = "")

# post tweet --------------------------------------------------------------

# if testing do not post output
if (Sys.getenv("NARROWBOT_TEST") == "true") {
  message("Test mode, will not post to Twitter")
} else {
  rtweet::post_tweet(
    status = status_msg,
    media = tmp_file, 
    media_alt_text = alt_msg,
    lat = place$lat,
    long = place$long,
    display_coordinates = TRUE,
    token = narrowbotr_token
  )
}

# delay to avoid message and cat mixing
Sys.sleep(1)

# output tweet message for GH actions log
cat(status_msg, paste("Alt text:", alt_msg), sep = "\n")
