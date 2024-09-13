library(tidyverse)
library(sf)

gigle <- read_sf("GiGL_SpacesToVisit_region.shp")

glimpse(gigle)

unique(gigle$PrimaryUse)
