library(tidyverse)
library(janitor)
library(data.table)

road00 <- 
  fread("no2_export_weight00.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0) |> 
  filter(tick < 2850)

road10 <- 
  fread("no2_export_weight10.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.1) |> 
  filter(tick < 2850)

road20 <- 
  fread("no2_export_weight20.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.2) |> 
  filter(tick < 2850)

road30 <- 
  fread("no2_export_weight30.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.3) |> 
  filter(tick < 2850)

road40 <- 
  fread("no2_export_weight40.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.4) |> 
  filter(tick < 2850)

road50 <- 
  fread("no2_export_weight50.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.5) |> 
  filter(tick < 2850)

road60 <- 
  fread("no2_export_weight60.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.6) |> 
  filter(tick < 2850)

road70 <- 
  fread("no2_export_weight70.csv") |> 
  as_tibble() |> 
  clean_names() |> 
  mutate(weight = 0.7) |> 
  filter(tick < 2850)

road80 <- fread("no2_export_weight80.csv") |>
  as_tibble() |>
  clean_names() |>
  mutate(weight = 0.8) |>
  filter(tick < 2850)

road90 <-
  fread("no2_export_weight90.csv") |>
  as_tibble() |>
  clean_names() |>
  mutate(weight = 0.9) |>
  filter(tick < 2850)

road100 <-
  fread("no2_export_weight100.csv") |>
  as_tibble() |>
  clean_names() |>
  mutate(weight = 1) |>
  filter(tick < 2850)



roadsim <- bind_rows(road00, road10, road20, road30, road40, road50, road60, road70, road80, road90, road100)

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


roadsim_mean |> 
  left_join(real, by = c("tick", "monitor_code")) |> 
  group_by(monitor_code, weight) |> 
  summarise(no2_model = mean(no2.x),
            no2_data = mean(no2.y),
            diff = no2_data - no2_model,
            diff_abs = abs(diff)
  ) |> 
  slice(which.min(diff_abs)) |> 
  View()


#####################
##--Visualisation--##
#####################
roadsim_mean |> 
  left_join(real, by = c("tick", "monitor_code")) |> 
  group_by(monitor_code, weight) |> 
  summarise(no2_model = mean(no2.x),
            no2_data = mean(no2.y),
            diff = no2_data - no2_model,
            diff_abs = abs(diff)
  ) |> 
  ungroup() |> 
  distinct(monitor_code, no2_data) -> real_plot


roadsim_mean |> 
  left_join(real, by = c("tick", "monitor_code")) |> 
  group_by(monitor_code, weight) |> 
  summarise(no2_model = mean(no2.x),
            no2_data = mean(no2.y),
            diff = no2_data - no2_model,
            diff_abs = abs(diff)
  ) |> 
  mutate(weight = as.factor(weight)) |> 
  ggplot(aes(weight, no2_model)) +
  #geom_line(aes(group = monitor_code, colour = monitor_code)) +
  geom_smooth(aes(group = monitor_code, colour = monitor_code)) + 
  geom_point() +
  labs(x = "Weight", y = "NO2(µg/m3)") +
  geom_hline(data = real_plot, aes(yintercept = no2_data), linetype='dotted', colour = "blue", size = 1) + 
  facet_wrap(~monitor_code, scale = "free", ncol = 3) +
  theme_bw() +
  theme(legend.position = "none")
  
ggsave("plot.jpg", width = 8, height = 9.5)  


 
