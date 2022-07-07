library(shiny)
library(tidyverse)
library(httr)
library(jsonlite)
library(ggplot2)

options(stringsAsFactors=FALSE)

# assigns each code to its corresponding type and specific subtype, puts it in a dataframe
itemsetCode <- c(330, 161, 397, 398, 407, 445, 411, 509, 526, 495, 444, 406, 443, 410, 404, 401, 523, 408, 447, 548, 582, 631, 542, 492, 550, 402, 409, 501, 402, 446, 405, 580, 516, 455, 403, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 604, 626)
itemsetType <- c('Language of Judgment', 'Language of Judgment','Speed', 'Speed', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Origin', 'Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety','Variety')
itemsetSubtype <- c('English', 'Spanish', 'fast', 'slow', 'Andalusia', 'Argentina', 'Bolivia', 'Brazil', 'Bulgaria', 'Canary Islands', 'Caribbean','Castilian','Chile','Colombia','Costa Rica','Cuba','Cyprus','Dominican Republic','Ecuador','El Salvador','England','France','Germany','Haiti','Honduras','Mexico','Panama','Paraguay', 'Peru','Puerto Rico','Spain','Sweden','Uruguay', 'USA', 'Venezuela', 'Andalusian','Argentinian', 'Bolivian', 'Canarian', 'Castilian', 'Chilean', 'Colombian', 'Costa Rican', 'Cuban', 'Dominican', 'Ecuadorian', 'Guatemalan', 'Honduran', 'Mexican', 'Nicaraguan', 'Panamanian', 'Paraguayan', 'Peruvian', 'Puerto Rican', 'Salvadoran', 'Uruguayan', 'USA','Venezuelan')
dat2 = data.frame(itemsetCode, itemsetType, itemsetSubtype)

# these are the unique options for the types
options = c("", "Language of Judgment", "Speed", "Origin", "Variety")

# gets the data from the server
res = GET("https://stirrs.rll.lsa.umich.edu/api/items?per_page=1000")
data = fromJSON(rawToChar(res$content))
STIRRSdata = data$`o:item_set`

# for each itemset, add its id to each of its tags
for (ind in (1:length(STIRRSdata))) {
  STIRRSdata[[ind]][3] <- ind
}

# gets the first entry to initialize the dataframe
dat <- STIRRSdata[[1]]

# add each entry to dat
for (ind in (2:length(STIRRSdata))) {
  dat <- rbind(dat, STIRRSdata[[ind]])
}

# make the column names nice
colnames(dat) = c("link", "tag", "id")

# add type and subtype by code using dat2, remove empty rows
dat$itemsetType <- dat2$itemsetType[match(dat$tag, dat2$itemsetCode)]
dat$itemsetSubtype <- dat2$itemsetSubtype[match(dat$tag, dat2$itemsetCode)]
dat <- dat %>% filter(!is.na(itemsetType)) %>% arrange(itemsetSubtype)

ui <- fluidPage(    
  titlePanel("Select your variables:"),
  sidebarLayout(      
    sidebarPanel(
      selectInput("type", "Data Category:", choices = options), # data grouping by type
      uiOutput("subtype"),                                      # specific subtype
      uiOutput("x_axis"),                                       # type on x-axis
      hr(),
      helpText("Entry categories")
    ),
    mainPanel(
      plotOutput("barPlot")
    )
  )
)

server <- function(input, output) {
  # sets variable subtype to the selected category type (e.g. Origin -> Andalusia)
  output$subtype <- renderUI({
    if (input$type != as.character("Language of Judgment") && input$type != as.character("Speed")) {
      selectInput("subtype", "Category Subset:", 
                  choices = as.character(dat$itemsetSubtype[dat$itemsetType == input$type]))
    }
    
  })
  
  # selects the x-axis category (cannot be the data subset ca)
  output$x_axis <- renderUI ({
    selectInput("x", "X-Axis:", choices = setdiff(options, input$type))
  })
  
  output$barPlot <- renderPlot({
    # if Language or Speed, do side-by-side bar plot
    if (input$type == as.character("Language of Judgment") || input$type == as.character("Speed")) {
                  # select data for LoJ/Speed style plot: no subtype, just plotting two types of studies (e.g. Speed + Origin => fast/slow for all origins)
                  # merge 1) the data selected where [LoJ/Speed/Origin/Variety] = the x variable with 2) the data with the selected [LoJ/Speed/Origin/Variety]
      ggplot(merge(dat[dat$id %in% dat$id[dat$itemsetType == input$type],][dat[dat$id %in% dat$id[dat$itemsetType == input$type],]$itemsetType == input$x,],
                   dat[dat$id %in% dat$id[dat$itemsetType == input$type],][dat[dat$id %in% dat$id[dat$itemsetType == input$type],]$itemsetType == input$type,],
                   by="id"),
              aes(x = merge(dat[dat$id %in% dat$id[dat$itemsetType == input$type],][dat[dat$id %in% dat$id[dat$itemsetType == input$type],]$itemsetType == input$x,],
                           dat[dat$id %in% dat$id[dat$itemsetType == input$type],][dat[dat$id %in% dat$id[dat$itemsetType == input$type],]$itemsetType == input$type,],
                           by="id")$itemsetSubtype.x, fill = merge(dat[dat$id %in% dat$id[dat$itemsetType == input$type],][dat[dat$id %in% dat$id[dat$itemsetType == input$type],]$itemsetType == input$x,],
                                                    dat[dat$id %in% dat$id[dat$itemsetType == input$type],][dat[dat$id %in% dat$id[dat$itemsetType == input$type],]$itemsetType == input$type,],
                                                    by="id")$itemsetSubtype.y)) +
        geom_bar(stat = "count", position = position_dodge())  +
        xlab(input$x) +
        ylab("Number of Entries") +
        labs(fill = input$type) +
        scale_fill_manual(values = c(fill = "#c83939", "darkcyan")) +
        theme_bw(base_size = 16) + 
        theme(axis.text.x = element_text(angle = 90))
    }
    else {
            # use datasets that are in the selected subset (e.g. Andalusia as Origin), but only the rows we care about (selected x variable)
      ggplot(dat[dat$id %in% dat$id[dat$itemsetSubtype == input$subtype],][dat[dat$id %in% dat$id[dat$itemsetSubtype == input$subtype],]$itemsetType == input$x,],
             aes(x = itemsetSubtype)) +
        geom_bar(stat = "count", fill = "#c83939") + 
        xlab(input$x) +
        ylab("Number of Entries") +
        theme_bw(base_size = 16) + 
        theme(axis.text.x = element_text(angle = 90))
    }
  })
}

app <- shinyApp(ui, server)
