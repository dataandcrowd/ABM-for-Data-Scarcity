library(tidyverse)
library(imputeTS)

load("afterservice_road.RData")

cleaned_road
#############################################################################
cleaned_road %>% 
  filter(code == "BT8") %>% 
  nrow

cleaned_road %>% 
  group_by(code) %>% 
  summarise(count = n()) %>% 
  arrange(desc(count)) %>% 
  print(n = Inf)


cleaned_road %>% 
  filter(code == "BT8") %>% 
  mutate(site = NA,
         no2 = NA) -> template

#############################################################################

files <- list.files(path = "../AQ-by-rd-stations/", pattern = "\\.csv$")
files_name <- substr(files,1,3)

files_name

cleaned_road %>% 
  filter(code == "BY7") %>% 
  select(Date) %>% 
  pull %>% as.character() -> imsi
  

template$Date %>% as.character() -> jamsi

setdiff(jamsi, imsi)


# BT4 BT6







cleaned_road %>% 
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cr


cr %>% 
  group_by(code, site) %>% 
  summarise(n = n()) %>% 
  arrange(desc(n)) %>% 
  print(n = Inf)



