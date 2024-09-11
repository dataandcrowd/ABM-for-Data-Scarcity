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
  )

# Collapse rows that are now identical
collapsed_df <- df_modified %>%
  group_by(middle_layer_super_output_areas_label, msoa_of_workplace_label) %>%
  summarise(
    #middle_layer_super_output_areas_code = first(middle_layer_super_output_areas_code),
    #msoa_of_workplace_code = first(msoa_of_workplace_code),
    #place_of_work_indicator_4_categories_code = first(place_of_work_indicator_4_categories_code),
    #place_of_work_indicator_4_categories_label = first(place_of_work_indicator_4_categories_label),
    count = sum(count)
  ) %>%
  ungroup()

collapsed_df
