library(tidyverse)
library(janitor)
library(data.table)

cv_random_raw <- read_csv("beta2_random.csv") |> clean_names()
cv_average_raw <- read_csv("beta2_average.csv") |> clean_names()

 
cv_random_raw |> 
  group_by(tick, monitor_code) |> 
  summarise(no2_modelled = mean(no2),
            no2_real = mean(no2_list)) -> cv_random

cv_random <- cv_random |> 
  group_by(monitor_code) |> 
  mutate(error = no2_modelled - no2_real,
         squared_error = error^2)

cv_average_raw |> 
  group_by(tick, monitor_code) |> 
  summarise(no2_modelled = mean(no2),
            no2_real = mean(no2_list)) -> cv_average

cv_average <- cv_average |> 
  group_by(monitor_code) |> 
  mutate(error = no2_modelled - no2_real,
         squared_error = error^2)


plot(cv_random$no2_modelled, cv_random$no2_real)
cor(cv_random$no2_modelled, cv_random$no2_real)

rmse_random <- cv_random |> 
  summarise(rmse = sqrt(mean(squared_error)))



plot(cv_average$no2_modelled, cv_average$no2_real)
cor(cv_average$no2_modelled, cv_average$no2_real)

rmse_average <- cv_average |> 
  summarise(rmse = sqrt(mean(squared_error)))

rmse_average |> 
  left_join(rmse_random, by = "monitor_code") |> 
  rename(rmse_av = rmse.x,
         rmse_random = rmse.y)


rmse_average |> 
  left_join(rmse_random, by = "monitor_code") |> 
  rename(rmse_av = rmse.x, rmse_random = rmse.y) -> combined_df


colSums(combined_df[, -1])



