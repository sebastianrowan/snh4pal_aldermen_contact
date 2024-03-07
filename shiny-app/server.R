#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(shiny)
library(tidygeocoder)
library(sf)

# Define server logic required to get ward
function(input, output, session) {
  observeEvent(input$getWardBtn, {
    
    addr <- input$addr
    
    wards <- read_sf("data/nh_wards_2022.geojson")
    
    if (!is.na(addr)) {
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
      
      ward_name <- in_wards$DISTRICT
      ward_name[!is.na(ward_name)]

      if (length(ward_name) > 0) {
        output$wardResult <- renderText(paste("You are in", paste(ward_name, collapse = ", ")))
      } else {
        output$wardResult <- renderText(paste("Unable to determine ward. lat/lon = ", lat_longs$latitude, lat_longs$longitude))
      }
    } else {
      output$wardResult <- renderText("Please enter both latitude and longitude.")
    }
  })
}
