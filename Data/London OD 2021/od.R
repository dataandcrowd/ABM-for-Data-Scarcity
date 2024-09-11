library(tidyverse)
library(data.table)
library(janitor)


od_raw <- fread("LondonOD_MSOA.csv") |> as_tibble() |> clean_names()

od_raw |> glimpse()

# Remove numbers from the end of the label
df_modified <- od_raw %>%
  select(-c(middle_layer_super_output_areas_code, msoa_of_workplace_code)) |> 
  mutate(
    middle_layer_super_output_areas_label = gsub("\\s\\d+$", "", middle_layer_super_output_areas_label),
    msoa_of_workplace_label = gsub("\\s\\d+$", "", msoa_of_workplace_label)
  ) |> 
  filter(place_of_work_indicator_4_categories_code != -8,
         msoa_of_workplace_label != "Workplace is outside the UK")

# Collapse rows that are now identical
collapsed_df <- df_modified |> 
  group_by(middle_layer_super_output_areas_label, msoa_of_workplace_label) %>%
  summarise(count = sum(count)) |> 
  ungroup() |> 
  rename(msoa_home = middle_layer_super_output_areas_label,
         msoa_work = msoa_of_workplace_label) |> 
  mutate(msoa_work = if_else(msoa_work %in% msoa_home, msoa_work, "others")) |> 
  group_by(msoa_home, msoa_work) |> 
  summarise(count = sum(count)) |> 
  ungroup() 

collapsed_df

# Step 1: Calculate the total count for each 'msoa_home'
home_totals <- collapsed_df %>%
  group_by(msoa_home) %>%
  summarise(total_count = sum(count))

# Step 2: Join the total counts with the original dataset
collapsed_df_fraction <- collapsed_df %>%
  left_join(home_totals, by = "msoa_home") %>%
  mutate(fraction = count / total_count * 100) %>%
  select(msoa_home, msoa_work, fraction)

# Step 3: Reshape into a matrix format
fraction_matrix <- collapsed_df_fraction %>%
  pivot_wider(names_from = msoa_work, values_from = fraction, values_fill = 0)

fraction_matrix_reordered <- fraction_matrix |> 
  select(-others, everything(), others) |> 
  select(-`City of London`) |> 
  filter(msoa_home != "City of London")

fraction_matrix_reordered

### visualisation
# Step 1: Reshape the data using pivot_longer
fraction_long <- fraction_matrix_reordered %>%
  pivot_longer(cols = -msoa_home, names_to = "msoa_work", values_to = "fraction")

# Step 2: Create the heatmap using ggplot2
ggplot(collapsed_df_fraction, aes(x = msoa_work, y = msoa_home, fill = fraction)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(x = "Work (%)", y = "Home (%)", fill = "Fraction") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Heatmap of Fractional Matrix")



write_csv(fraction_matrix_reordered, "London_OD.csv")
