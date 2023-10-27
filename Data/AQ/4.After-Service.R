library(tidyverse)
library(imputeTS)

load("afterservice.RData")

cleaned2 %>% 
  filter(code == "LW1") %>% 
  tail

cleaned2 %>% 
  filter(code == "BG1") %>% 
  filter(date > "2021-11-03 10:00:00") %>% 
  mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "Lewisham - Catford"),
         code = case_when(code == "BG1" ~ "LW1"),
         no2 = NA) -> temp

temp


cleaned2 %>% 
  filter(code == "LW1") %>% 
  bind_rows(temp) %>% 
  group_by(site, code) %>% 
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
  ungroup() -> LW1



LW1 %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_LW1


write_csv(cleaned_LW1, "../AQ-by-bg-stations/LW1.csv")


#############################################################################

cleaned2 %>% 
  filter(code == "LH0") %>% 
  tail


cleaned2 %>% 
  filter(code == "BG1") %>% 
  filter(date > "2022-01-01 00:00:00") %>% 
  mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "Hillingdon - Harlington"),
         code = case_when(code == "BG1" ~ "LH0"),
         no2 = NA) -> temp

cleaned2 %>% 
  filter(code == "LH0") %>% 
  bind_rows(temp) %>% 
  group_by(site, code) %>% 
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
  ungroup() -> LH0


LH0 %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_LH0


write_csv(cleaned_LH0, "../AQ-by-bg-stations/LH0.csv")

#############################################################################
# cleaned2 %>% 
#   filter(code == "EI3") %>% 
#   tail
# 
# 
# cleaned2 %>% 
#   filter(code == "BG1") %>% 
#   filter(date > "2022-06-16 10:00:00") %>% 
#   mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "Ealing - Acton Vale "),
#          code = case_when(code == "BG1" ~ "EI3"),
#          no2 = NA) -> temp
# 
# cleaned2 %>% 
#   filter(code == "EI3") %>% 
#   bind_rows(temp) %>% 
#   group_by(site, code) %>% 
#   na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
#   ungroup() %>% 
#   mutate(site = NA,
#          site = "Ealing - Acton Vale") -> EI3
# 
# EI3 %>% 
#   select(Date, daynight, code, site, hours, no2) %>% 
#   mutate(hours = paste0("h", hours)) %>% summary
#   pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_EI3
# 
# 
# write_csv(EI3, "../AQ-by-bg-stations/EI3.csv")

#############################################################################
cleaned2 %>% 
  filter(code == "HG4") %>% 
  tail


cleaned2 %>% 
  filter(code == "BG1") %>% 
  filter(date > "2022-12-25 19:00:00") %>% 
  mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "Haringey  - Priory Park South"),
         code = case_when(code == "BG1" ~ "HG4"),
         no2 = NA) -> temp

cleaned2 %>% 
  filter(code == "HG4") %>% 
  bind_rows(temp) %>% 
  group_by(site, code) %>% 
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
  ungroup() -> HG4


HG4 %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_HG4



write_csv(HG4, "../AQ-by-bg-stations/HG4.csv")

