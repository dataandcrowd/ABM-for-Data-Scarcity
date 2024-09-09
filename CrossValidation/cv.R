library(tidyverse)
library(janitor)

# Read in data for each beta value
cv_random_beta1 <- read_csv("beta1_random.csv") |> clean_names() |> mutate(beta = "beta1")
cv_random_beta1_5 <- read_csv("beta1.5_random.csv") |> clean_names() |> mutate(beta = "beta1.5")
cv_random_beta2 <- read_csv("beta2_random.csv") |> clean_names() |> mutate(beta = "beta2")
cv_random_beta2_5 <- read_csv("beta2.5_random.csv") |> clean_names() |> mutate(beta = "beta2.5")

cv_average_beta1 <- read_csv("beta1_average.csv") |> clean_names() |> mutate(beta = "beta1")
cv_average_beta1_5 <- read_csv("beta1.5_average.csv") |> clean_names() |> mutate(beta = "beta1.5")
cv_average_beta2 <- read_csv("beta2_average.csv") |> clean_names() |> mutate(beta = "beta2")
cv_average_beta2_5 <- read_csv("beta2.5_average.csv") |> clean_names() |> mutate(beta = "beta2.5")

# Combine the datasets for random models
cv_random_raw <- bind_rows(cv_random_beta1, cv_random_beta1_5, cv_random_beta2, cv_random_beta2_5)

# Combine the datasets for average models
cv_average_raw <- bind_rows(cv_average_beta1, cv_average_beta1_5, cv_average_beta2, cv_average_beta2_5)

# Summarise and calculate errors for random models
cv_random <- cv_random_raw |> 
  group_by(tick, monitor_code, beta) |> 
  summarise(no2_modelled = mean(no2),
            no2_real = mean(no2_list)) |> 
  ungroup() |> 
  group_by(monitor_code, beta) |> 
  mutate(error = no2_modelled - no2_real,
         squared_error = error^2)

# Summarise and calculate errors for average models
cv_average <- cv_average_raw |> 
  group_by(tick, monitor_code, beta) |> 
  summarise(no2_modelled = mean(no2),
            no2_real = mean(no2_list)) |> 
  ungroup() |> 
  group_by(monitor_code, beta) |> 
  mutate(error = no2_modelled - no2_real,
         squared_error = error^2)

# Calculate RMSE for random models
rmse_random <- cv_random |> 
  summarise(rmse = sqrt(mean(squared_error))) |> 
  ungroup()

# Calculate RMSE for average models
rmse_average <- cv_average |> 
  summarise(rmse = sqrt(mean(squared_error))) |> 
  ungroup()

# Combine RMSE for comparison across beta values
combined_df <- rmse_average |> 
  left_join(rmse_random, by = c("monitor_code", "beta"), suffix = c("_av", "_random"))

# Plotting the results
rmse_long <- combined_df |> 
  pivot_longer(cols = starts_with("rmse"), 
               names_to = "model", 
               values_to = "rmse") |> 
  mutate(model = if_else(model == "rmse_av", "Average", "Random"))


# Calculate summary statistics for each beta and model
summary_stats <- rmse_long |> 
  group_by(beta, model) |> 
  summarise(
    Mean = mean(rmse),
    Median = median(rmse),
    SD = sd(rmse)
  )

summary_stats

# Create a plot of RMSE by beta value with models side by side and mean points
ggplot(rmse_long, aes(x = beta, y = rmse, fill = model)) +
  geom_boxplot(position = position_dodge(0.8)) +  # Place models side by side for each beta
  stat_summary(fun = mean, geom = "point", 
               shape = 18, size = 3, color = "red", 
               position = position_dodge(0.8)) +  # Add mean points
  theme_minimal() +
  labs(title = "RMSE Comparison Across Betas for Random and Average Models",
       x = "Beta Value",
       y = "RMSE") +
  theme(legend.position = "right") +  # Place the legend on the right for clarity
  scale_fill_manual(values = c("Average" = "lightblue", "Random" = "lightgreen"))  # Customize colors if needed

ggsave("rmse_comparison_plot.jpg", width = 7, height = 5, dpi = 300, device = "jpeg")

library(gridExtra)

# Create the table for summary statistics
summary_table <- tableGrob(summary_stats)

rmse_plot <- ggplot(rmse_long, aes(x = beta, y = rmse, fill = model)) +
  geom_boxplot(position = position_dodge(0.8)) +  
  stat_summary(fun = mean, geom = "point", 
               shape = 18, size = 3, color = "red", 
               position = position_dodge(0.8)) +  
  theme_minimal() +
  labs(title = "RMSE Comparison Across Betas for Random and Average Models",
       x = "Beta Value",
       y = "RMSE") +
  theme(legend.position = "right") +  
  scale_fill_manual(values = c("Average" = "lightblue", "Random" = "lightgreen"))

# Load grid package if not already loaded
library(grid)

# Combine plot and table
combined_plot <- arrangeGrob(
  rmse_plot, 
  summary_table,
  nrow = 2
)

# Save as JPG
#ggsave("rmse_comparison_plot.jpg", combined_plot, width = 10, height = 8, dpi = 300, device = "jpeg")
