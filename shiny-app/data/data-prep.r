library(sf)
library(tidyverse)
library(tidygeocoder)

some_addresses <- tibble::tribble(
  ~name,                  ~addr,
  "Home",          "142 Falcon Crest Way, Manchester, NH"                               
)

# geocode the addresses
lat_longs <- some_addresses %>%
  geocode(addr, method = 'osm', lat = latitude , long = longitude)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))


wards <- read_sf("nh_wards_2022_nashua_fix.geojson") %>%
  select(
    c(NAME, COUNTY, DISTRICT, resolution, geometry)
  ) 


city_name = "Concord"
county = "Merrimack"
res = "Active Effort"

city <- wards %>%
  filter(
    NAME == city_name,
    DISTRICT != paste0(city_name, "- entire")
  )




city_entire <- city %>%
  st_union() %>%
  st_as_sf() %>%
  mutate(
    NAME = city_name,
    COUNTY = county,
    DISTRICT = paste0(city_name, " - entire"),
    resolution = res
  ) %>%
  select(
    NAME, COUNTY, DISTRICT, resolution,
    geometry = x
  )

wards <- wards %>%
  filter(DISTRICT != paste0(city_name, "- entire")) %>%
  rbind(city_entire)


st_write(wards, "nh_wards_2022_concord_fix.geojson", append=F)

head(wards)

ggplot(city_entire) +
  geom_sf()
