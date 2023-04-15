countries_json <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Countries_December_2022_GB_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"

countries_sf <- sf::st_read(countries_json)

wales_sf <- countries_sf |>
  dplyr::filter(CTRY22NM == "Wales")

readr::write_rds(wales_sf, "data/wales_sf.RDS", compress = "bz2")
