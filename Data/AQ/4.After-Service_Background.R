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
cleaned2 %>%
  filter(code == "GR4") %>%
  tail


cleaned2 %>%
  filter(code == "BG1") %>%
  filter(date > "2022-12-26 00:00:00") %>%
  mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "Greenwich - Eltham"),
         code = case_when(code == "BG1" ~ "GR4"),
         no2 = NA) -> temp

cleaned2 %>%
  filter(code == "GR4") %>%
  bind_rows(temp) %>%
  group_by(site, code) %>%
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>%
  ungroup() -> GR4


cleaned2 %>%
  filter(code == "GR4") %>%
  filter(Date > "2021-12-10" & Date < "2022-01-02") %>% View


cleaned2 %>%
  filter(code == "BG1") %>%
  filter(date > "2021-12-13 14:00:00" & date < "2022-01-01 00:00:00") %>%
  mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "Greenwich - Eltham"),
         code = case_when(code == "BG1" ~ "GR4"),
         no2 = NA) -> temp

GR4 %>% 
  bind_rows(temp) %>%
  group_by(site, code) %>%
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>%
  ungroup() %>% 
  arrange(date) -> GR4_new

GR4_new %>%
  select(Date, daynight, code, site, hours, no2) %>%
  mutate(hours = paste0("h", hours)) %>% 
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) %>% 
  mutate(id = row_number()) %>%
  select(id, everything()) -> cleaned_GR4


write_csv(cleaned_GR4, "../AQ-by-bg-stations/GR4.csv")

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

#############################################################################
cleaned2 %>% 
  filter(code == "KC1") %>% 
  tail


cleaned2 %>% 
  filter(code == "BG1") %>% 
  filter(date > "2022-12-26 00:00:00") %>% 
  mutate(site = case_when(site == "Barking and Dagenham - Rush Green" ~ "KC1"),
         code = case_when(code == "BG1" ~ "KC1"),
         no2 = NA) -> temp

cleaned2 %>% 
  filter(code == "KC1") %>% 
  bind_rows(temp) %>% 
  group_by(site, code) %>% 
  na_seasplit(algorithm = "mean", find_frequency=TRUE) %>% 
  ungroup() -> KC1


KC1 %>% 
  select(Date, daynight, code, site, hours, no2) %>% 
  mutate(hours = paste0("h", hours)) %>%
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) %>% 
  mutate(id = row_number()) %>%
  select(id, everything()) -> cleaned_KC1



write_csv(cleaned_KC1, "../AQ-by-bg-stations/KC1.csv")
