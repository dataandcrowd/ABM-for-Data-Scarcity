library(tidyverse)
library(sf)
library(mapview)

importMeta(source = "kcl") -> ldn_raw

ldn <- na.omit(ldn_raw)

ldn %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) -> ldn_sf


mapview(ldn_sf)

ldn_sf %>%
  group_by(site_type) %>% 
  summarise(count = n())

ldn_no2_raw <- importKCL(
  year = 2019
)
