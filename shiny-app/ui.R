#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)




fluidPage(
  
  # Application title
  titlePanel("Address to Ward Converter"),
  
  
  sidebarLayout(
    sidebarPanel(
      textInput("addr", "Address:", value = "1200 Elm St, Manchester, NH"),
      actionButton("getWardBtn", "Get Ward")
    ),
    mainPanel(
      textOutput('wardResult')
    )
  )
)
