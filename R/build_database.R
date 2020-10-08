feeds <- readr::read_csv("data/feeds.csv")

points <- feeds %>%
  dplyr::filter(geo_type == "point") %>%
  dplyr::mutate(data = purrr::map(feed_url, sf::st_read))

features <- readr::read_csv("data/features.csv")

points_combined <- points %>%
  tidyr::unnest(data) %>%
  dplyr::mutate(angle = dplyr::case_when(
    !is.na(Angle) ~ as.double(Angle),
    !is.na(ANGLE) ~ as.double(ANGLE),
    TRUE ~ NA_real_
  )) %>%
  dplyr::left_join(features, by = c("feature", "SAP_OBJECT_TYPE")) %>%
  dplyr::select(-Angle, -ANGLE, -OBJECTID) %>%
  janitor::clean_names() %>%
  dplyr::rename(uid = sap_func_loc,
         name = sap_description,
         obj_type = sap_object_type)

readr::write_rds(points_combined,"data/all_points.RDS", compress = "bz2")
