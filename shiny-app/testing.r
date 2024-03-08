library(tidygeocoder)
library(sf)
library(tidyverse)
library(sendmailR)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

addr <- "900 elm st manchester nh"

wards <- read_sf("data/nh_wards_2022.geojson")
aldermen <- readxl::read_excel("data/aldermen.xlsx")

wards <- wards %>%
  left_join(
    aldermen,
    by = c("DISTRICT"  = "ward"),
    relationship = "many-to-many"
  )

address <- tibble::tribble(
    ~name,    ~addr,
    "addr",   addr                              
)

lat_longs <- address %>%
    geocode(addr, method = 'osm', lat = latitude , long = longitude)

pt_df <- data.frame(latitude = lat_longs$latitude, longitude = lat_longs$longitude)
point <- sf::st_as_sf(pt_df, coords = c('longitude', 'latitude'))
point <- st_set_crs(point, st_crs(wards))

# Do spatial join on point and wards. Return ward name

in_wards <- wards %>%
    st_join(
        point,
        join = st_intersects,
        left = FALSE
    )

ward <- in_wards %>%
  filter(
    !is.na(name),
    level == "Local"
  )

ward$display_text <- paste(
  ward$name,
  ward$role,
  paste0("<a href=mailto:'",ward$email,"'>",ward$email,"</a>"),
  paste0(
    "<a href=tel:'",ward$phone,"'>",
    paste0("(",substr(ward$phone, 1, 3),") ", substr(ward$phone, 4, 6),"-",substr(ward$phone, 7, 10)),
    "</a>"
  ),
  sep = " | "
)



wards <- wards %>%
    left_join(
        aldermen,
        by = c("DISTRICT"  = "ward")
    )

### Test Email ----

from <- "southernnh4palistine@gmx.com"
to <- "sebastianbcrowan@gmail.com"

subject <- "Hello, world."
body <- "This is the body of the message."

# sendmail(
#     from = from,
#     to = to,
#     subject = subject,
#     msg = mime_part(body),
#     engine = "curl",
#     engineopts = list(username = "foo", password = "bar"), 
#     control=list(smtpServer="smtp://smtp.gmail.com:587", verbose = TRUE) 
# )