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
   select(Date, daynight, code, site, hours, no2) |>
   mutate(hours = paste0("h", hours)) |>
   pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_wider

 cleaned_wider |>
   group_by(code, site) |>
   mutate(id = row_number()) |>
   select(id, everything()) -> cleaned_wider_with_id

 cleaned_wider_with_id |>
   summarise(n = n()) |>
   print(n = Inf)


 cleaned_wider_with_id |>
   summarise(n = n()) |>
   #filter(n > 500) |>
   left_join(ldn_raw, by = c("site", "code")) |>
   filter(site_type %in% c("Urban Background", "Suburban")) |>
   select(code) |>
   ungroup() -> counter


# cleaned_wider_with_id |>
#   inner_join(counter, by = "code") |>
#   write_csv("London_AQ_tidy.csv")

date_df <- 
  data.frame(id = 1:2192, 
            Date =as_date("2019-01-01"):as_date("2021-12-31") |> as_date()) |> 
  as_tibble()



cleaned_wider_with_id |>
  summarise(n = n()) |>
  left_join(ldn_raw, by = c("site", "code")) |>
  filter(site_type %in% c("Roadside", "Kerbside")) |>
  select(code) |>
  ungroup() -> counter1


cleaned_wider_with_id |>
  inner_join(counter1, by = "code") |> 
  filter(Date >= as.Date("2019-01-01") & Date <= as.Date("2021-12-31")) -> ldn_tidy_wide_rd

ldn_tidy_wide_rd |> 
  group_by(code) |> 
  summarise(n = n()) |> 
  filter(n > 2192)










# cleaned_wider_with_id |>
#   inner_join(counter1, by = "code") |>
#   write_csv("London_AQ_tidy_rd.csv")

background_stations <- c("BG1", "BG2", "BL0", "BQ7", "BX1", "BX2", "CT3", "EN1", "EN7", "GR4", "HG4", "HI0",
"HR1", "IS6", "KC1", "LB6", "LH0", "LW1", "LW5", "NM3",  "RB7", "RI2", "SK6", "WA2", "WA9", "WM0")


for (i in 1:length(background_stations)){
  ldn_no2_raw2 |> 
    filter(code == background_stations[i]) |> 
    pull(no2) |> 
    ts() |> 
    ggplot_na_distribution2(title = paste0("Missing Values per Interval - ", background_stations[i]),
                            measure = "percent", 
                            number_intervals = 16, 
                            xlab = "Time Lapse - Interval Size: Approx 3 months",
                            color_missing = "gold3")
  
  # Define the filename
  file_name <- paste0("NA_Distribution/", background_stations[i], ".jpg")
  
  # Check if the file exists
  if (!file.exists(file_name)){
    ggsave(filename = file_name, width = 4.5, height = 4)
  }
  
}



ldn_no2_raw2 |> 
  group_by(site, code) |> 
  na_seasplit(algorithm = "kalman", find_frequency=TRUE) |> 
  ungroup()-> aq_imputed


unique(aq_imputed$code)

ldn_no2_raw2 |> filter(code == "HR1") |> print(n = 200)
aq_imputed |> filter(code == "HR1") |> print(n = 200)



aq_imputed |> 
  arrange(code, date) |> 
  mutate(Date = as_date(date),
         hours = as.character(hour(date)),
         no2 = as.numeric(no2)) -> ldn_no2_clean2

ldn_no2_clean2 |> 
  mutate(hours = as.numeric(hours),
         daynight = case_when(hours >= 8 & hours <= 17 ~ "Work",
                              TRUE ~ "Home")) -> cleaned2

########

cleaned2 |> 
  ggplot(aes(date, no2, group = code)) +
  geom_line() +
  facet_wrap(code ~.)




########

cleaned2 |> 
  inner_join(counter, by = "code") |> 
  select(Date, daynight, code, site, hours, no2) |> 
  mutate(hours = paste0("h", hours)) |>
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_background

cleaned_background |> 
  group_by(code, site) |> 
  mutate(id = row_number()) |>
  select(id, everything()) -> cleaned_background_with_id

cleaned_background_with_id |> 
  summarise(n = n()) |> 
  print(n = Inf)


cleaned_background_with_id |> 
  summarise(n = n()) |> 
  #filter(n > 500) |> 
  left_join(ldn_raw, by = c("site", "code")) |> 
  filter(site_type %in% c("Urban Background", "Suburban")) |> 
  select(code) |> 
  ungroup() -> counter2


#Activate only when needed 
# cleaned_background_with_id |> 
#   inner_join(counter2, by = "code") |> 
#   write_csv("London_AQ_tidy_bg.csv")


ldn_sf |> 
  inner_join(counter, by = "code") |> 
  mapview() +
  mapview(ldn_bnd)


######
cleaned2 |> 
  inner_join(counter1, by = "code") |> 
  select(Date, daynight, code, site, hours, no2) |> 
  mutate(hours = paste0("h", hours)) |>
  pivot_wider(names_from = hours, values_from = no2, values_fill = -999) -> cleaned_road

cleaned_road |> 
  group_by(code, site) |> 
  mutate(id = row_number()) |>
  select(id, everything()) -> cleaned_road_with_id


cleaned_road_with_id |> 
  summarise(n = n()) |> 
  filter(n > 1000) |> 
  left_join(ldn_raw, by = c("site", "code")) |> 
  filter(site_type %in% c("Roadside", "Kerbside")) |> 
  select(code) |> 
  ungroup() -> counter3



# cleaned_wider_with_id |> 
#   inner_join(counter3, by = "code") |> 
#   write_csv("London_AQ_tidy_rd.csv")
