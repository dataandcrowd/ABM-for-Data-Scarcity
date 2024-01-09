library(tidyverse)
library(janitor)
library(data.table)

roadsim <- 
  read_csv("NO2_5.Validation experiment-lists.csv", skip = 6) |> 
  clean_names() |> 
  rename(iteration = run_number,
         no2 = x0,
         monitor_code = x1,
         tick = step) |> 
  select(-reporter) |> 
  filter(tick < 2850)

nextsim <- 
  fread("no2_real.csv") |> 
  as_tibble() |>  
  clean_names() |> 
  rename(iteration = iteration_count,
         no2 = no2) |> 
  filter(tick < 2850) |> 
  group_by(monitor_code, tick) |> 
  slice(1) # because they gave the same value over the course of the iteration.


roadsim %>% 
  group_by(tick, monitor_code) %>% 
  summarise(no2 = mean(no2)) %>% 
  ggplot(aes(tick, no2)) +
  geom_line(aes(group = monitor_code, colour = monitor_code)) +
  geom_smooth() +
  facet_wrap(~monitor_code)


# Create bins for every 100 ticks
roadsim_plot <- roadsim %>%
  mutate(tick_bin = ceiling(tick / 100)) # Grouping ticks into bins of 100

# Calculate the average NO2 level for each bin and monitor_code
avg_no2 <- roadsim_plot %>%
  group_by(iteration, tick_bin, monitor_code) %>%
  summarize(avg_no2 = mean(no2, na.rm = TRUE))

# Create the boxplot
ggplot(avg_no2, aes(x = factor(tick_bin), y = avg_no2)) +
  geom_boxplot() +
  facet_wrap(~ monitor_code, scales = "free_x") +
  labs(x = "Tick Bin (Each bin represents 100 ticks)", y = "Average NO2 Level")



###################

roadsim %>% 
  group_by(tick, monitor_code) %>% 
  summarise(no2 = mean(no2)) -> roadsim_mean


roadsim_mean %>% 
  left_join(nextsim, by = c("tick", "monitor_code")) %>%
  group_by(monitor_code) %>% 
  summarise(no2_model = mean(no2.x),
            no2_model_sd = sd(no2.x),
            no2_data = mean(no2.y),
            no2_data_sd = sd(no2.y)
            )

library(rstatix)
roadsim_mean %>% 
  left_join(nextsim %>% select(-iteration), by = c("tick", "monitor_code")) %>%
  ungroup(tick) %>% 
  select(-tick) %>% 
  group_by(monitor_code) %>% 
  get_summary_stats() %>% View


roadsim_mean %>% 
  left_join(nextsim_mean, by = c("tick", "monitor_code")) %>% 
  mutate(minus = no2.x - no2.y) %>% 
  group_by(monitor_code,tick) %>% 
  ggplot(aes(tick, minus)) +
  geom_line(aes(group = monitor_code, colour = monitor_code)) +
  geom_smooth() +
  facet_wrap(~monitor_code)

