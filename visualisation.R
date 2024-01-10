
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


