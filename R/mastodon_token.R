mastodon_token <- function(access_token = NULL, type = "user", instance = "botsin.space") {
  
  if (is.null(access_token)){
    access_token <- Sys.getenv("MASTODON_TOKEN")
  }
  
  if (access_token == "") {
    stop("No Mastodon access token found")
  } else if (typeof(access_token) != "character") {
    stop("access_token must be character vector")
  } else if (length(access_token) != 1) {
    stop("access_token must be of length 1")
  } else if (nchar(access_token) != 43) {
    stop("access_token must be exactly 43 characters")
  }
  
  if (type != "user") {
    stop("type must be \"user\"")
  }
  
  if (is.null(instance)) {
    instance <- Sys.getenv("MASTODON_INST")
  }
  
  if (instance == "") {
    stop("No Mastodon instance found")
  } else if (typeof(instance) != "character") {
    stop("instance must be character vector")
  } else if (length(instance) != 1) {
    stop("instance must be of length 1")
  }
  
  token <- structure(
    list(
      bearer = access_token,
      type = type,
      instance = instance
    ),
    class = "rtoot_bearer"
  )
  
  return(token)
  
}
