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
  titlePanel("Tell your elected officials to support a ceasefire!"),
  
  
  sidebarLayout(
    sidebarPanel(
      
      textInput(
        "addr",
        "Street Address:",
        value = "900 Elm St"
      ),
      selectInput(
        "city",
        "City/Town:",
        c("Concord", "Dover", "Durham", "Lebanon", "Manchester", "Nashua", "Portsmouth"),
        selected = "Manchester",
        multiple = FALSE,
        selectize = TRUE
      ),
      selectInput(
        "state",
        "State:",
        c("NH"),
        selected = "NH",
        multiple = FALSE,
        selectize = FALSE
      ),
      actionButton("getWardBtn", "Get Ward")
      
    ),
    
    mainPanel(
      h2("Local Officials:"),
      htmlOutput('wardResult'),
      # h2("State Officials:"),
      # textOutput("stateResult"),
      # h2("Federal Officials:"),
      # textOutput('fedResult'),
      br(),
      hr(),
      p("Note: The Right-To-Know Law (RSA 91-A) provides that most e-mail communications, to or from government employees and volunteers, are government records available to the public upon request. Therefore, email communication to your officials may be subject to public disclosure.")
    )
  )
)
