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
    
    add <- input$addr
    city <- input$city
    state <- input$state
    addr <- paste(add, city, state)
    
    wards <- read_sf("data/nh_wards_2022.geojson")
    aldermen <- readxl::read_excel("data/aldermen.xlsx")

    wards <- wards %>%
        left_join(
            aldermen,
            by = c("DISTRICT"  = "ward")
        )
    
    #TODO: get email message customized for each city
    msg <- "TEST CEASEFIRE MESSAGE"
    
    if (!is.na(addr)) {
      address <- tibble::tribble(
        ~name,    ~addr,
        "addr",   addr                              
      )
      
      lat_longs <- address %>%
        geocode(addr, method = 'osm', lat = latitude , long = longitude)
      
      if(!is.na(lat_longs$latitude)){
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
        
        ward$mailto <- 
        
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
        
        #
        
        
        if (length(ward) > 0) {
          output$wardResult <- renderText(paste(
            p("Your elected officials are:"), 
            paste(ward$display_text, collapse = "<br>"),
            h3("Email your officials"),
            p("Click on your representatives' email address above to generate a pre-filled email demanding they do everything in their power to advocate for a ceasefire in Gaza."),
            p("Or click", a("here", href='mailto:email.email'), "to send the message to all of the representatives shown above."),
            p("The email will be generated with the following message that you can edit yourself before sending:"),
            p("TODO: Generate email based on city/town selected")
            ))
        } else {
          output$wardResult <- renderText(paste("Unable to determine ward. lat/lon = ", lat_longs$latitude, lat_longs$longitude))
        } 
      } else {
        output$wardResult <- renderText("The address you entered does not appear to be valid. Please try again.")
      }
    } else {
      output$wardResult <- renderText("Please enter an address.")
    }
  })
}
