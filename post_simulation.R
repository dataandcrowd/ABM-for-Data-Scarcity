library(tidyverse)
library(data.table)

roadsim <- 
  fread("no2_export.csv") %>% 
  as_tibble %>% 
  rename(iteration = `"iteration-count`,
         X = `patch-x`,
         Y = `patch-y`,
         no2 = `no2"` 
         ) %>% 
  slice(1:2800) 

nextsim <- 
  fread("no2_patch_neighbours.csv") %>% 
  as_tibble %>% 
  rename(iteration = `"iteration-count`,
         next_X = `patch-x`,
         next_Y = `patch-y`,
         next_no2 = `no2"` 
  ) %>% 
  slice(1:2800) 


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

nextsim %>% 
  group_by(tick, monitor_code) %>% 
  summarise(next_no2 = mean(next_no2)) -> nextsim_mean


roadsim_mean %>% 
  left_join(nextsim_mean, by = c("tick", "monitor_code")) %>% View

