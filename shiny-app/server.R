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
library(tidyverse)
library(tidygeocoder)
library(sf)
library(glue)

# Define server logic required to get ward
function(input, output, session) {
  observeEvent(input$getWardBtn, {
    
    name <- input$name
    add <- input$addr
    city <- input$city
    state <- input$state
    addr <- paste(add, city, state, sep = ", ")
    
    wards <- read_sf("data/nh_wards_2022.geojson")
    aldermen <- readxl::read_excel("data/aldermen.xlsx", sheet="officials")
    msgs <- readxl::read_excel("data/aldermen.xlsx", sheet="messages")
    
    subj <- msgs[msgs$city == city, 'subject']
    msg <- msgs[msgs$city == city, 'message']

    wards <- wards %>%
        left_join(
            aldermen,
            by = c("DISTRICT"  = "ward")
        )
    
    #TODO: get email message customized for each city.
    
    # Message parts
    # Greeting: "Dear Alderman ...,"
    msg <- glue(
      "My name is {name}, and my address is {addr}.\n\n{msg}\n\nSincerely,\n\n{name}\n{addr}"
    )
    
    if( is.na(name) | name == "" ){
      output$wardResult <- renderText("Please enter your full name in the form.")
    } else if ( is.na(add) | add == "") {
      output$wardResult <- renderText("Please enter your address in the form.")
    } else if (!is.na(addr)) {
      address <- tibble::tribble(
        ~name,    ~addr,
        "addr",   addr                              
      )
      
      lat_longs <- address %>%
        geocode(addr, method = 'osm', lat = latitude , long = longitude)
      
      if ( !is.na(lat_longs$latitude)){
        pt_df <- data.frame(latitude = lat_longs$latitude, longitude = lat_longs$longitude)
        point <- sf::st_as_sf(pt_df, coords = c('longitude', 'latitude'))
        point <- st_set_crs(point, st_crs(wards))
        # Do spatial join on point and wards. Return ward name
        
        in_wards <- wards %>%
          st_join(
            point,
            join = st_intersects,
            left = FALSE
          ) %>%
          mutate(
            is_mayor = (role == "Mayor")
          )
        
        ward <- in_wards %>%
          filter(
            !is.na(name),
            level == "Local"
          ) %>%
          arrange(desc(is_mayor))
        
        # Generate mailto:all
        all_msg <- glue("Dear {paste(ward$title, collapse = ', ')},\n\n{msg}")
        all_emails <- paste0(ward$email, collapse=",")
        all_mailto <- paste0(
          "mailto:",
          all_emails,
          "?subject=",
          URLencode(subj),
          "&body=",
          URLencode(glue(all_msg))
        )
        
        
        ward$mailto <- paste0(
          "<a href=mailto:",
          ward$email,
          "?subject=",
          URLencode(subj),
          "&body=",
          URLencode(glue("Dear {ward$title},\n\n{msg}")),
          "'>",
          ward$email,
          "</a>"
        )
        
        ward$display_text <- paste(
          ward$name,
          ward$role,
          ward$mailto,
          # paste0("<a href=mailto:'",ward$email,"'>",ward$email,"</a>"),
          paste0(
            "<a href=tel:'",ward$phone,"'>",
            paste0("(",substr(ward$phone, 1, 3),") ", substr(ward$phone, 4, 6),"-",substr(ward$phone, 7, 10)),
            "</a>"
          ),
          sep = " | "
        )
        
        if (length(ward) > 0) {
          output$wardResult <- renderText(paste(
            h2("Your elected officials are:"), 
            paste(ward$display_text, collapse = "<br>"),
            h3("Email your officials"),
            p("Click on your representative's email address above to generate a pre-filled email demanding they do everything in their power to advocate for a ceasefire in Gaza."),
            p(span(a("Or click here", href=all_mailto), style="font-size: 200%"), "to send the message to all of the representatives shown above at once."),
            p("The email will be generated with the message shown below, and we encourage you to add your own statements about why you personally think this is important!"),
            br(),
            p(HTML(str_replace_all(all_msg, "\n","<br>")))
            ))
        } else {
          output$wardResult <- renderText(paste("Unable to determine ward. Please check your address and try again"))
        } 
      } else {
        output$wardResult <- renderText("The address you entered does not appear to be valid. Please try again.")
      }
    } else {
      output$wardResult <- renderText("Please enter an address.")
    }
  })
}
