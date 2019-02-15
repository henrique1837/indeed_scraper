#### Treat Indeed Data ####
library(plyr)
library(stringr)
library(ggplot2)
library(plotly)
library(leaflet)
setwd("~/Documentos/scripts/indeed_scraper/")
#### Read data ####
files <- Sys.glob("./results/*")
files <- files[which(str_detect(string = files,pattern = "indeed")==TRUE)]
df_t <- data.frame()
for(i in 1:length(files)){
  df <- read.csv(file = files[i],
                 stringsAsFactors = FALSE)
  df <- df[which(!(str_detect(string = df$date,
                              pattern = "30+"))),]
  file_date <- as.Date(str_extract(string = files[i],
                       pattern = "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}"))
  df$date <- file_date - as.numeric(str_extract(string = df$date,
                                                pattern = "[[:digit:]]+"))
  df$date[which(is.na(df$date))] <- file_date
  if(length(df$country) == 0){
    df$country <- "USA"
  }
  df_t <- rbind(df_t,df[which(!(df$link %in% df_t$link)),])
  message("Files ",i," - ",length(files))
}
df_t$city <- gsub(pattern = "[[:punct:]].*",
                       replacement = "",
                       x = df_t$location)
df_t$state <- str_extract(string = df_t$location,
                          pattern = "[A-Z]{2}")
df_t$count <- 1
df_agreggated <- ddply(.data = df_t,
                       .variables = .(date),
                       .fun = summarize,
                       totalJobs=sum(count))

df_companies_date <- ddply(.data = df_t,
                      .variables = .(date,company),
                      .fun = summarize,
                      totalJobs=sum(count))

df_companies <- ddply(.data = df_t,
                      .variables = .(company),
                      .fun = summarize,
                      totalJobs=sum(count))

df_places <- ddply(.data = df_t,
                   .variables = .(city,state,country),
                   .fun = summarize,
                   totalJobs=sum(count))
# Download lat and long of USA cities (source https://simplemaps.com/data/us-cities)
if(!file.exists("./results/USA_lat_long.csv")){
  download.file(url = "https://simplemaps.com/static/data/us-cities/uscitiesv1.4.csv",
              destfile = "./results/USA_lat_long.csv" )
}
df_lat_long_cities <- read.csv(file = "./results/USA_lat_long.csv",
                               stringsAsFactors = FALSE)
## Preparing dataframe for leaflet map ##
lats <- numeric()
longs <- numeric()
cities <- character()
totalJobs <- numeric()
df_placesUSA <- df_places[which(df_places$country=="USA"),]
for(i in 1:nrow(df_placesUSA)){
  
  indice <- which(toupper(df_lat_long_cities$city) == toupper(df_placesUSA$city[i]))
  if(length(indice)!=0){
    if(length(indice)>1){
      for(ind in indice){
        if(toupper(df_lat_long_cities$state_id[ind]) == toupper(df_placesUSA$state[i])){
          indice <- ind
        }
      }
    }
    totalJobs[i] <- df_placesUSA$totalJobs[i]
    cities[i] <- df_placesUSA$city[i]
    lats[i] <- df_lat_long_cities$lat[indice]
    longs[i] <- df_lat_long_cities$lng[indice]
  }
  
}
df_map <- data.frame(city=cities,
                     lat=lats,
                     lng=longs,
                     totalJobs=totalJobs)

## Vizualize data ##
df_map %>%
  leaflet() %>%
  addTiles() %>% 
  addCircleMarkers(weight = 2,
             lng = df_map$lng,
             lat=df_map$lat,
             radius = df_map$totalJobs *  2,
             label = paste0("Total of ",
                            df_map$totalJobs,
                            " Ethereum Jobs in ",
                            df_map$city),
             clusterOptions = markerClusterOptions())
  
## Total jobs posted by day ##
ggplot(data = df_agreggated,
       mapping = aes(x=date,y=totalJobs)) + 
geom_point() + 
geom_smooth(formula = y~x,
            method = "loess")

## Top 10 companies ##
ggplot(data = head(df_companies[order(df_companies$totalJobs,
                                      decreasing = TRUE),],10),
       mapping = aes(x=company,y=totalJobs)) + 
  geom_bar(col="black",fill="steelblue",stat = "identity") +
  theme(axis.text.x=element_text(angle = -45,hjust = 0))
## Top 10 places ##
ggplot(data = head(df_places[order(df_places$totalJobs,
                                   decreasing = TRUE),],10),
       mapping = aes(x=location,y=totalJobs)) + 
  geom_bar(col="black",fill="steelblue",stat = "identity") +
  theme(axis.text.x=element_text(angle = -45,hjust = 0))

## Leaflet map of locations ##
leaflet(df_places) 

## Top 10 companies jobs by date ##
ggplot(data = head(df_companies_date[order(df_companies_date$totalJobs,
                                           decreasing = TRUE),],10),
       mapping = aes(x=date,y=company)) + 
  geom_tile(aes(fill = totalJobs)) +
  scale_fill_gradient(low = "lightblue",high = "steelblue")
