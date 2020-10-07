
# Custom function for posting tweets
# Extension of rtweet::post_tweet to include geotag
post_geo_tweet <- function(status = "Test",
                           media = NULL,
                           token = NULL,
                           lat = NULL,
                           long = NULL) {
  
  # check/get token
  token <- rtweet:::check_token(token)

  # create params list with status
  params <- list(status = status)

  # if media, upload and add media id to params
  if(!is.null(media)) {
    
    if(length(media) > 1) {
      # Twitter allows up to four images, but allow one
      stop("Only 1 item allowed in media")
    }
    
    r <- rtweet:::upload_media_to_twitter(media, token)
    
    media_id_string <- r$media_id_string
    
    params <- append(params, list(media_ids = media_id_string))

  }

  # if lat and long are provided then add to params
  if (!is.null(lat) & !is.null(long)) {
    params <- append(params, list(lat = lat, long = long, display_coordinates = TRUE))

  }

  # set query
  query <- "statuses/update"

  # create API url
  url <- rtweet:::make_url(query = query, param = params)

  # post tweet
  r <- rtweet:::TWIT(get = FALSE, url, token)
  
  # check the return
  if (r$status_code != 200) {
    return(httr::content(r))
  }
  
  message("your tweet has been posted!")
  invisible(r)
  
}
