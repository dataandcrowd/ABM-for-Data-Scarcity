library(tidyverse)
library(janitor)
library(data.table)

cv_raw <- read_csv("no2_export_random.csv") |> clean_names()
 
cv_raw |> 
  group_by(tick, monitor_code) |> 
  summarise(no2_modelled = mean(no2),
            no2_real = mean(no2_list)) -> cv

cv <- cv |> 
  group_by(monitor_code) |> 
  mutate(error = no2_modelled - no2_real,
         squared_error = error^2)

rmse_by_station <- cv |> 
  summarise(rmse = sqrt(mean(squared_error)))

rmse_by_station
