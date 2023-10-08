library(tidyverse)
library(sf)
library(mapview)
library(openair)

##### London Boundary
ldn_bnd <- read_sf("../London_Boundary_cleaned.shp")

##### Metadata from KCL
importMeta(source = "kcl") -> ldn_raw
# 
# ldn <- na.omit(ldn_raw)
# 
# ldn %>% 
#   filter(site_type != "Industrial") %>%  # for some reason industrial locations don't convert to GB projection
#   st_as_sf(coords = c("longitude", "latitude"), crs = 4326) -> ldn_sf

ldn_sf <- read_sf("ldn.gpkg")

mapview(ldn_sf, zcol = "site_type") +
  mapview(ldn_bnd)


ldn_sf %>%
  group_by(site_type) %>% 
  summarise(count = n())

##### KCL NO2
ldn_no2_raw  <- importAURN(site = ldn_sf$code, pollutant = "no2", year = 2019:2022)
ldn_no2_raw2 <- importKCL(site = ldn_sf$code, pollutant = "no2", year = 2022) 


unique(ldn_no2_raw$site)
unique(ldn_no2_raw2$site)

ldn_no2 <- ldn_no2_raw2 %>% drop_na()


## Next job
# convert the data to 


## Netlogo job
# you find the nearest station

