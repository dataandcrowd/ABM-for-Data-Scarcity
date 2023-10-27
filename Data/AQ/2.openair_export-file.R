library(tidyverse, quietly = T)
library(sf, quietly = T)
library(mapview, quietly = T)
library(openair, quietly = T)
library(imputeTS)

ldn_image <- load("LDN_NO2.RData")

# Station location and name
ldn_raw


unique(ldn_no2_raw2$site)

ldn_no2 %>% 
  arrange(code, date) %>% 
  mutate(Date = as_date(date),
         hours = as.character(hour(date)),
         no2 = as.numeric(no2)) -> ldn_no2_clean1

ldn_no2_clean1 %>% 
  mutate(hours = as.numeric(hours),
         daynight = case_when(hours >= 8 & hours <= 17 ~ "Work",
                        TRUE ~ "Home")) -> cleaned

cleaned %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_wider

cleaned_wider %>% 
  group_by(code, site) %>% 
  mutate(id = row_number()) %>%
  select(id, everything()) -> cleaned_wider_with_id

cleaned_wider_with_id %>% 
  summarise(n = n()) %>% 
  print(n = Inf)


cleaned_wider_with_id %>% 
  summarise(n = n()) %>% 
  #filter(n > 500) %>% 
  left_join(ldn_raw, by = c("site", "code")) %>% 
  filter(site_type %in% c("Urban Background", "Suburban")) %>% 
  select(code) %>% 
  ungroup() -> counter


# cleaned_wider_with_id %>% 
#   inner_join(counter, by = "code") %>% 
#   write_csv("London_AQ_tidy.csv")


cleaned_wider_with_id %>% 
  summarise(n = n()) %>% 
  filter(n > 1000) %>% 
  left_join(ldn_raw, by = c("site", "code")) %>% 
  filter(site_type %in% c("Roadside", "Kerbside")) %>% 
  select(code) %>% 
  ungroup() -> counter1


# cleaned_wider_with_id %>% 
#   inner_join(counter1, by = "code") %>% 
#   write_csv("London_AQ_tidy_rd.csv")


ldn_no2_raw2 %>% 
  group_by(site, code) %>% 
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
  ungroup()-> aq_imputed


unique(aq_imputed$code)

ldn_no2_raw2 %>% filter(code == "HR1") %>% print(n = 200)
aq_imputed %>% filter(code == "HR1") %>% print(n = 200)



aq_imputed %>% 
  arrange(code, date) %>% 
  mutate(Date = as_date(date),
         hours = as.character(hour(date)),
         no2 = as.numeric(no2)) -> ldn_no2_clean2

ldn_no2_clean2 %>% 
  mutate(hours = as.numeric(hours),
         daynight = case_when(hours >= 8 & hours <= 17 ~ "Work",
                              TRUE ~ "Home")) -> cleaned2


########

cleaned2 %>% 
  inner_join(counter, by = "code") %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_background

cleaned_background %>% 
  group_by(code, site) %>% 
  mutate(id = row_number()) %>%
  select(id, everything()) -> cleaned_background_with_id

cleaned_background_with_id %>% 
  summarise(n = n()) %>% 
  print(n = Inf)


cleaned_background_with_id %>% 
  summarise(n = n()) %>% 
  #filter(n > 500) %>% 
  left_join(ldn_raw, by = c("site", "code")) %>% 
  filter(site_type %in% c("Urban Background", "Suburban")) %>% 
  select(code) %>% 
  ungroup() -> counter2


#Activate only when needed 
# cleaned_background_with_id %>% 
#   inner_join(counter2, by = "code") %>% 
#   write_csv("London_AQ_tidy_bg.csv")


ldn_sf %>% 
  inner_join(counter, by = "code") %>% 
  mapview() +
  mapview(ldn_bnd)


######
cleaned2 %>% 
  inner_join(counter1, by = "code") %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_road

cleaned_road %>% 
  group_by(code, site) %>% 
  mutate(id = row_number()) %>%
  select(id, everything()) -> cleaned_road_with_id


cleaned_road_with_id %>% 
  summarise(n = n()) %>% 
  filter(n > 1000) %>% 
  left_join(ldn_raw, by = c("site", "code")) %>% 
  filter(site_type %in% c("Roadside", "Kerbside")) %>% 
  select(code) %>% 
  ungroup() -> counter3



# cleaned_wider_with_id %>% 
#   inner_join(counter3, by = "code") %>% 
#   write_csv("London_AQ_tidy_rd.csv")
