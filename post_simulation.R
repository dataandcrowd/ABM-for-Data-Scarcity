library(tidyverse)
library(janitor)
library(data.table)

road00 <- 
  fread("no2_export_weight00.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0) |> 
  filter(tick < 2850)

road25 <- 
  fread("no2_export_weight25.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.25) |> 
  filter(tick < 2850)

road50 <- 
  fread("no2_export_weight50.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.5) |> 
  filter(tick < 2850)

road75 <- 
  fread("no2_export_weight75.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.75) |> 
  filter(tick < 2850)

road100 <- 
  fread("no2_export_weight100.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 1) |> 
  filter(tick < 2850)

roadsim <- bind_rows(road00, road25, road50, road75, road100)
real <- 
  fread("no2_real.csv") |> 
  as_tibble()


##################
##--Statistics--##
##################

roadsim |> 
  group_by(tick, weight, monitor_code) |> 
  summarise(no2 = mean(no2)) -> roadsim_mean


roadsim_mean %>% 
  left_join(real, by = c("tick", "monitor_code")) |> 
  group_by(monitor_code, weight) |> 
  summarise(no2_model = mean(no2.x),
            no2_data = mean(no2.y),
            diff = no2_data - no2_model
  ) |> View()


roadsim_mean %>% 
  left_join(real, by = c("tick", "monitor_code")) |> 
  group_by(monitor_code, weight) |> 
  summarise(no2_model = mean(no2.x),
            no2_data = mean(no2.y),
            diff = no2_data - no2_model
  ) |> 
  filter(weight == 0.5) |> 
  View()



 
