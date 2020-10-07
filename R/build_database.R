library(tidyverse)

feeds <- read_csv("data/feeds.csv")

points <- feeds %>%
  filter(geo_type == "point") %>%
  mutate(data = map(feed_url, sf::st_read))

features <- read_csv("data/features.csv")

points_combined <- points %>%
  unnest(data) %>%
  mutate(angle = case_when(
    !is.na(Angle) ~ as.double(Angle),
    !is.na(ANGLE) ~ as.double(ANGLE),
    TRUE ~ NA_real_
  )) %>%
  left_join(features, by = c("feature", "SAP_OBJECT_TYPE")) %>%
  select(-Angle, -ANGLE, -OBJECTID) %>%
  janitor::clean_names() %>%
  rename(uid = sap_func_loc,
         name = sap_description,
         obj_type = sap_object_type)

write_rds(points_combined,"data/all_points.RDS")
