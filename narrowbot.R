# narrowbotR
# An R-based Mastodon bot that tweets waterway features in England & Wales from
# the Canal & River Trust network.

# set-up environment ------------------------------------------------------

# load custom functions
source("R/flickr_functions.R")  # flickr api functions
source("R/mastodon_token.R")    # custom mastodon token function
source("R/bskyr_post.R")    # custom mastodon token function

# create mastodon token
toot_token <- mastodon_token(
  access_token = Sys.getenv("MASTODON_TOKEN"),
  type = "user",
  instance = "mastodon.social"
)

# select location ---------------------------------------------------------

# load points data & wales_sf
all_points <- readRDS("data/all_points.RDS")

# pick a point
place <- all_points |>
  dplyr::filter(stringr::str_detect(feature, "culvert", negate = TRUE)) |>
  dplyr::sample_n(1) |>
  as.list()

# tell user you have picked a place
message("Picked ", place$name,
        ", uid: ", place$uid,
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

# set basic hashtags for all posts
base_hashtags <- c("#canal", "#narrowboat")

# add location hashtags
if (place$wales_marker) {
  location_hashtags <- c("#wales", "#uk")
} else {
  location_hashtags <- c("#england", "#uk")
}

photo_hashtags <- NULL

# create alt text for tweet photo, add flickr info to tweet
if (download_res == 2) {
  msg_text <- base_message
  alt_msg <- paste0("A satellite image of the area containing ",
                    place$name,
                    ". Provided by MapBox.")

  photo_hashtags <- c("#mapbox", "#aerialphoto", "#aerialphotography",
                      "#satelliteview")

} else if (download_res == 1) {
  msg_text <- c(
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
  
  if (is.null(flickr_photo$tags)) {
    photo_hashtags <- "#flickr"
  } else {
    photo_hashtags <- c("#flickr", flickr_photo$tags)
  }



} else {
  stop("Something has gone wrong")
}

# combine hashtags
if (!is.null(photo_hashtags)) {
  post_hashtags <- unique(
    tolower(c(base_hashtags, location_hashtags, photo_hashtags))
  )
} else {
  post_hashtags <- c(base_hashtags, location_hashtags)
}

hashtag_length <- sum(nchar(msg_text)) + cumsum(nchar(post_hashtags) + 1)

# mastodon limit is 500 characters, bsky is 300
toot_tags <- paste0(post_hashtags[hashtag_length < 495], collapse = " ")
bsky_tags <- paste0(post_hashtags[hashtag_length < 295], collapse = " ")

# add hashtags to message and collapse
toot_text <- paste0(c(msg_text, "\n\n", toot_tags), collapse = "")
bsky_text <- paste0(c(msg_text, "\n\n", bsky_tags), collapse = "")


# submit post -------------------------------------------------------------

safely_toot <- purrr::possibly(rtoot::post_toot, otherwise = "toot_error")
safely_bsky_photo <- purrr::possibly(bskyr::bs_upload_blob, otherwise = "bsky_photo_error")
safely_bsky_post <- purrr::possibly(bskyr::bs_post, otherwise = "bsky_error", quiet = FALSE)

# if testing do not post output
if (Sys.getenv("NARROWBOT_TEST") == "true") {
  message("Test mode, will not post to Twitter/Mastodon")
} else {

  # post to mastodon
  toot_out <- safely_toot(
    status = toot_text,
    media = tmp_file,
    alt_text = alt_msg,
    token = toot_token
  )

  # upload media to bsky
  bsky_img_blob <- safely_bsky_photo(
    blob = tmp_file, clean = FALSE
  )

  # if media upload successful then make a post
  if (!is.character(bsky_img_blob)) {
    bsky_out <- safely_bsky_post(
      text = bsky_text,
      images = bsky_img_blob,
      images_alt = alt_msg
    )
  } else {
    bsky_out <- "bsky_photo_error"
  }

  if (is.character(toot_out) && is.character(bsky_out)) {
    stop("bot error - did not post to mastodon or bsky")
  } else if (is.character(toot_out) || is.character(bsky_out)) {

    if (toot_out == "toot_error") {
      warning("Toot unsuccessful")
    }
    if (bsky_out == "bsky_photo_error") {
      warning("bsky media upload unsuccessful")
    } else if (bsky_out == "bsky_error") {
      warning("bsky post unsuccessful")
    }
  }

}

# delay to avoid message and cat mixing
Sys.sleep(1)

# output toot message for GH actions log
cat(toot_text, paste("Alt text:", alt_msg), sep = "\n")


# log output --------------------------------------------------------------

if (Sys.getenv("NARROWBOT_MANUAL") == "true") {
  post_type <- "MANUAL"
} else if (Sys.getenv("NARROWBOT_TEST") == "true") {
  post_type <- "TEST"
} else {
  post_type <- "AUTO"
}

if (is.null(flickr_photo)) {
  log_text <- paste(
    Sys.time(),
    place$uid, "NA", post_type,
    sep = " | "
  )
} else {
  log_text <- paste(
    Sys.time(), place$uid, flickr_photo$photo_url, post_type,
    sep = " | "
  )
}

# write log
if (Sys.getenv("NARROWBOT_TEST") == "true") {
  message("Test mode, will not log")
} else {
  readr::write_lines(log_text, "narrowbotr.log", append = TRUE)
  if (is.character(toot_out) || is.character(bsky_out)) {
    stop("Error with either Mastodon or Bsky but not both")
  }
}

# show log output for GH actions log
cat(log_text)

