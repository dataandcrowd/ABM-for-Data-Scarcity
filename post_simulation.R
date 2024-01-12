library(tidyverse)
library(janitor)
library(data.table)

road01 <- 
  fread("no2_export_weight0.1.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.1) |> 
  filter(tick < 2850)


road02 <- 
  fread("no2_export_weight0.2.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.2) |> 
  filter(tick < 2850)

road03 <- 
  fread("no2_export_weight0.3.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.3) |> 
  filter(tick < 2850)

roadsim <- bind_rows(road01, road02, road03, road05, road06)

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



# roadsim_mean |> 
#   left_join(real, by = c("tick", "monitor_code")) |>
#   group_by(monitor_code, weight) |> 
#   summarise(no2_model = mean(no2.x),
#             no2_model_sd = sd(no2.x),
#             no2_data = mean(no2.y),
#             no2_data_sd = sd(no2.y)) |> 
#   mutate(minus = no2_model - no2_data) |>
#   select(monitor_code, weight, minus) |> 
#   pivot_wider(names_from = weight, values_from = minus) |> 
#   View()
 
