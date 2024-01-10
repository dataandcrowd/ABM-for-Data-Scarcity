library(tidyverse)
library(janitor)
library(data.table)

roadsim <- 
  read_csv("NO2_5.Validation experiment-lists.csv", skip = 6) |> 
  clean_names() |> 
  rename(iteration = run_number,
         weight = roadpollution_weight,
         no2 = x0,
         monitor_code = x1,
         tick = step) |> 
  select(-reporter) |> 
  filter(tick < 2850)

real <- 
  fread("no2_real.csv") |> 
  as_tibble() |>  
  clean_names() |> 
  select(-iteration_count) |> 
  rename(no2 = no2) |> 
  filter(tick < 2850) |> 
  group_by(monitor_code, tick) |> 
  slice(1) # because they gave the same value over the course of the iteration.


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
            no2_model_sd = sd(no2.x),
            no2_data = mean(no2.y),
            no2_data_sd = sd(no2.y)
            ) |> View()


roadsim_mean |> 
  left_join(real, by = c("tick", "monitor_code")) |>
  group_by(monitor_code, weight) |> 
  summarise(no2_model = mean(no2.x),
            no2_model_sd = sd(no2.x),
            no2_data = mean(no2.y),
            no2_data_sd = sd(no2.y)) |> 
  mutate(minus = no2_model - no2_data) |>
  select(monitor_code, weight, minus) |> 
  pivot_wider(names_from = weight, values_from = minus) |> 
  View()
 
