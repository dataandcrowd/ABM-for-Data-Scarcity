library(tidyverse)
library(imputeTS)

load("afterservice_road.RData")

cleaned_road
#############################################################################

cleaned_road %>% 
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cr


cr %>% 
  group_by(code, site) %>% 
  summarise(n = n()) %>% 
  arrange(desc(n)) %>% 
  print(n = Inf)



