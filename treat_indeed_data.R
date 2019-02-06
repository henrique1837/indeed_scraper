#### Treat Indeed Data ####
library(plyr)
library(stringr)
library(ggplot2)
setwd("~/Documentos/scripts/indeed_scraper/")
#### Read data ####
files <- Sys.glob("./results/*")
df_t <- read.csv(file = files[1])
file_date <- as.Date(str_extract(string = files[1],
                                 pattern = "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}"))
df_t <- df_t[which(!(str_detect(string = df_t$date,
                              pattern = "30+"))),]
file_date <- as.Date(str_extract(string = files[1],
                                 pattern = "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}"))
df_t$date <- file_date - as.numeric(str_extract(string = df_t$date,
                                                pattern = "[[:digit:]]+"))

for(i in 2:length(files)){
  df <- read.csv(file = files[i])
  df <- df[which(!(str_detect(string = df$date,
                              pattern = "30+"))),]
  file_date <- as.Date(str_extract(string = files[i],
                       pattern = "[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}"))
  df$date <- file_date - as.numeric(str_extract(string = df$date,
                                                pattern = "[[:digit:]]+"))
  df$date[which(is.na(df$date))] <- file_date
  df_t <- rbind(df_t,df[which(!(df$link %in% df_t$link)),])
  message("Files ",i," - ",length(files))
}

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
                   .variables = .(location),
                   .fun = summarize,
                   totalJobs=sum(count))

## Vizualize data ##

## Total jobs posted by day ##
ggplot(data = df_agreggated,
       mapping = aes(x=date,y=totalJobs)) + 
geom_point() + 
geom_smooth(formula = y~x,
            method = "loess")

## Top 20 companies ##
ggplot(data = head(df_companies[order(df_companies$totalJobs,
                                      decreasing = TRUE),],20),
       mapping = aes(x=company,y=totalJobs)) + 
  geom_bar(col="black",fill="steelblue",stat = "identity") +
  theme(axis.text.x=element_text(angle = -45, hjust = 0))
## Top 20 places ##
ggplot(data = head(df_places[order(df_places$totalJobs,
                                   decreasing = TRUE),],20),
       mapping = aes(x=location,y=totalJobs)) + 
  geom_bar(col="black",fill="steelblue",stat = "identity") +
  theme(axis.text.x=element_text(angle = -45, hjust = 0))

## Top 20 companies jobs by date ##
ggplot(data = head(df_companies_date[order(df_companies_date$totalJobs,
                                           decreasing = TRUE),],20),
       mapping = aes(x=date,y=company)) + 
  geom_tile(aes(fill = totalJobs)) +
  scale_fill_gradient(low = "white",high = "steelblue")
