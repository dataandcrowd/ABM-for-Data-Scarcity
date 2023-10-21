library(tidyverse, quietly = T)
library(sf, quietly = T)
library(mapview, quietly = T)
library(openair, quietly = T)
library(imputeTS)

ldn_image <- load("LDN_NO2.RData")

unique(ldn_no2_raw2$site)

ldn_no2_raw2 %>% 
  mutate(Date = as_date(date),
         hours = as.character(hour(date)),
         no2 = as.numeric(no2)) %>% 
  group_by(site, code) %>% 
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
  ungroup()-> aq_imputed

aq_imputed %>% 
  mutate(hours = as.numeric(hours),
         dn = case_when(hours >= 8 & hours <= 17 ~ "Work",
                        TRUE ~ "Home")) -> cleaned

cleaned %>% 
  select(Date, dn, code, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>% 
  pivot_wider(names_from = hours, values_from = no2) -> cleaned_wider
