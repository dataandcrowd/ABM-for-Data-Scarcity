library(tidyverse)
library(data.table)

roadsim <- 
  fread("no2_export.csv") %>% 
  as_tibble %>% 
  rename(iteration = `"iteration-count`,
         no2 = `no2"` 
         ) %>% 
  filter(tick < 2850)

nextsim <- 
  fread("no2_real.csv") %>% 
  as_tibble %>% 
  rename(iteration = `"iteration-count`,
         no2 = `no2"` 
  ) %>% 
  filter(tick < 2850) %>% 
  group_by(monitor_code, tick) %>% 
  slice(1) # because they gave the same value over the course of the iteration.


roadsim %>% 
  group_by(tick, monitor_code) %>% 
  summarise(no2 = mean(no2)) %>% 
  ggplot(aes(tick, no2)) +
  geom_line(aes(group = monitor_code, colour = monitor_code)) +
  geom_smooth() +
  facet_wrap(~monitor_code)


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

