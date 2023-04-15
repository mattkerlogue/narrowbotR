library(dplyr)
library(sf)

wales_sf <- readr::read_rds("data/wales_sf.RDS")

feeds <- readr::read_csv("data/feeds.csv")

point_feeds <- feeds |>
  dplyr::filter(geo_type == "point")
  
points <- purrr::map_dfr(point_feeds$feed_url, sf::st_read, .id = "feed_id")

features <- readr::read_csv("data/features.csv")

in_wales <- sf::st_covered_by(points$geometry, wales_sf)

points_combined <- points |>
  dplyr::mutate(
    feature = point_feeds$feature[as.numeric(feed_id)],
    wales_marker = tidyr::replace_na(as.logical(in_wales), FALSE)
  ) |>
  dplyr::bind_cols(
    sf::st_coordinates(points$geometry) |> 
      tibble::as_tibble() |> 
      purrr::set_names(c("long", "lat"))
  ) |>
  dplyr::left_join(features, by = c("feature", "SAP_OBJECT_TYPE"))

readr::write_rds(points_combined,"data/all_points_raw.RDS", compress = "bz2")

points_reduced <- points_combined |>
  dplyr::select(
    feature,
    uid = SAP_FUNC_LOC,
    name = SAP_DESCRIPTION,
    lat, long,
    wales_marker,
    obj_type = SAP_OBJECT_TYPE,
    obj_type_label,
    status
  ) |>
  sf::st_drop_geometry() |>
  tibble::as_tibble()

readr::write_rds(points_reduced,"data/all_points.RDS", compress = "bz2")
