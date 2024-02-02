library(tidyverse, quietly = T)
library(sf, quietly = T)
library(mapview, quietly = T)
library(openair, quietly = T)
library(imputeTS)

ldn_image <- load("LDN_NO2.RData")

# Station location and name
ldn_raw

ldn_sf |> filter(site_type %in% c("Urban Background", "Suburban")) -> ldn_sf_back
ldn_sf |> filter(site_type %in% c("Kerbside", "Roadside")) -> ldn_sf_road

# Function to find the nearest station excluding itself
find_nearest_station <- function(row_index) {
  point <- ldn_sf_back[row_index, ]
  # Exclude the row itself by setting its distance to infinity
  distances <- st_distance(ldn_sf_back, point)
  distances[row_index] = Inf
  nearest_station_index <- which.min(distances)
  return(ldn_sf_back$code[nearest_station_index])
}

# Apply the function to each row
ldn_sf_back$nearest_station <- sapply(1:nrow(ldn_sf_back), find_nearest_station)

ldn_sf_back


unique(ldn_no2_raw2$site)
 
ldn_no2 |>
   arrange(code, date) |>
   mutate(Date = as_date(date),
          hours = as.character(hour(date)),
          no2 = as.numeric(no2)) -> ldn_no2_clean1


 ldn_no2_clean1 |>
   mutate(hours = as.numeric(hours),
          daynight = case_when(hours >= 8 & hours <= 17 ~ "Work",
                         TRUE ~ "Home")) -> cleaned

cleaned |> 
   left_join(ldn_raw, by = c("site", "code")) |>
   filter(site_type %in% c("Roadside", "Kerbside")) |> 
  select(-c(latitude, longitude, source)) -> road_data
 


road_data |> 
  select(Date, code) |> 
  group_by(code) |> 
  summarise(n = n(), .groups = "drop")


road_data |> 
  select(Date, code) |> 
  group_by(code) |> 
  summarise(n = n(), .groups = "drop") |> 
  filter(n > 20000) |> 
  pull(code) -> stations_with_sufficient_data


 
# Define start and end dates
start_date <- ymd_hms("2019-01-01 00:00:00")
end_date <- ymd_hms("2021-12-31 23:00:00")

# Create a sequence of hourly timestamps
hourly_sequence <- seq(from = start_date, to = end_date, by = "hour")

# Create a data frame
hourly_data_frame <- tibble(timestamp = hourly_sequence)

 
 
road_data |> 
  filter(code %in% stations_with_sufficient_data) -> road_data_station_filtered


#############################################

road_data_station_filtered |> 
  rename(timestamp = date) |> 
  group_by(code) |> 
  group_split() -> list_of_road

merged_list <- map(list_of_road, ~right_join(.x, hourly_data_frame, by = "timestamp"))

############################################

process_dataframe <- function(df) {
  df |> 
    fill(site, code, site_type, .direction = "downup") |> 
    mutate(Date = as_date(timestamp),
           hours = hour(timestamp),
           daynight = case_when(hours >= 8 & hours <= 17 ~ "Work",
                                TRUE ~ "Home")) |> 
    arrange(site, code, timestamp) |> 
    group_by(site, code) |> 
    na_seasplit(algorithm = "kalman", find_frequency=TRUE) |> 
    ungroup()
}

list_of_dfs <- lapply(merged_list, process_dataframe)

na_counts <- function(imsi){
  imsi %>% 
    group_by(code) %>% 
    summarise(na_count = sum(is.na(no2)))
  
}

lapply(list_of_dfs, na_counts) |> bind_rows()


aq_imputed <- list_of_dfs |> 
  bind_rows() |> 
  mutate(Date = as_date(timestamp))

###############################################

aq_imputed |>
   select(Date, daynight, code, site, hours, no2) |>
   mutate(hours = paste0("h", hours)) |>
   pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> road_wider


road_wider |>
   group_by(code, site) |>
   mutate(id = row_number()) |>
   select(id, everything()) -> road_wider_with_id

road_wider_with_id |>
   summarise(n = n()) |>
   print(n = Inf)



road_wider_with_id |> 
  write_csv("London_AQ_tidy_rd.csv")




