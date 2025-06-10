library(tidyverse)
library(sf)
library(data.table)
library(janitor)

kst <- fread("kingston-no2-exposure.csv") |> 
  as_tibble() 


fread("westminster-no2-exposure.csv")|> 
  as_tibble() |> clean_names() |> filter(no2_exposed > 0) -> westminster


# kst |> 
#   select(-c(destination_name, no2_exposed)) |> 
#   rename(destination_name = place,
#          no2 = value) |> 
#   filter(no2 > 0) -> kst
# 
# write_csv(kst, "west.csv")


kst |> 
  group_by(tick) |> 
  reframe(no2 = no2) |> 
  ggplot(aes(tick, no2)) +
  #geom_line() + 
  geom_smooth()


kst |> 
  mutate(kst_only = case_when(home_name == "Kingston upon Thames" & 
                                destination_name == "Kingston upon Thames" ~ "Within Kingston",
                             TRUE ~ "Out of Kingston"),
         age_group = cut(age,
                         breaks = seq(0, 70, by = 10),
                         labels = c("0–9", "10–19", "20–29", "30–39", "40–49", "50–59", "60–69"),
                         right = FALSE
         )) -> kst_cleaned

kst_cleaned |> 
  group_by(tick, kst_only, age_group) |> 
  reframe(no2 = mean(no2)) |> 
  ggplot(aes(tick, no2, colour = age_group)) +
  geom_smooth() +
  facet_wrap(~kst_only)




#
df_summary <- kst_cleaned %>%
  group_by(age_group, kst_only) %>%
  summarise(mean_no2 = mean(no2, na.rm = TRUE), .groups="drop")

ggplot(df_summary, aes(x = age_group, y = mean_no2, fill = kst_only)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  labs(
    title = "Mean NO₂ by Age Group & Context",
    x     = "Age Group",
    y     = "Mean NO₂",
    fill  = ""
  ) +
  theme_minimal()


ggplot(df_summary, aes(x = kst_only, y = mean_no2, group = age_group)) +
  geom_line(color = "grey70") +
  geom_point(aes(color = age_group), size = 3) +
  geom_text(
    data = df_summary %>% filter(kst_only == "Within Kingston"),
    aes(label = age_group),
    hjust = -0.1, size = 3
  ) +
  scale_x_discrete(expand = expansion(add = c(0.2,0.5))) +
  labs(
    title = "NO2 Shift from ‘Out’ to ‘Within’ by Age Group",
    x     = "",
    y     = "Mean NO2"
  ) +
  theme_minimal() +
  theme(legend.position = "none")



##########


# 1. Borough vector
boroughs <- c(
  "Ealing", "Waltham Forest", "Lambeth", "Hackney",
  "Barnet", "Richmond upon Thames", "Westminster",
  "Merton", "Enfield", "Wandsworth", "Islington",
  "Croydon", "Hounslow", "Camden", "Redbridge",
  "Southwark", "Haringey", "Brent", "Tower Hamlets",
  "Newham", "Bromley", "Kensington and Chelsea",
  "Greenwich", "Hillingdon", "Bexley",
  "Hammersmith and Fulham", "Lewisham", "Havering",
  "Harrow", "Barking and Dagenham", "Sutton",
  "Kingston upon Thames"
)

# 2–4. Build the Westminster dataset
wst_new <- westminster %>%                               # replace 'df' with your data frame name
  filter(
    destination_name == "Westminster",
    home_name %in% boroughs
  ) %>%
  mutate(
    # Flag journeys wholly within Westminster
    wst_only  = case_when(
      home_name == "Westminster" ~ "wst only",
      TRUE                        ~ "new"
    ),
    # 10-year age buckets
    age_group = cut(
      age,
      breaks = seq(0, 100, by = 10),
      labels = paste0(seq(0, 90, by = 10), "–", seq(9, 99, by = 10)),
      right = FALSE,
      include.lowest = TRUE
    )
  )


wst_new |> 
  group_by(tick, wst_only, home_name) |> 
  reframe(no2 = mean(no2_exposed)) |> 
  ggplot(aes(tick, no2, colour = home_name)) +
  geom_smooth() 

##########

boroughs_sf <- read_sf("../Data/London_Boundary_cleaned.shp")

# ─── 2. Summarise NO₂ at one time point (e.g. tick = 0) for the map ─────────
map_data <- wst_new %>%
  filter(tick == 0) %>%
  group_by(home_name) %>%
  summarise(mean_no2 = mean(no2_exposed, na.rm=TRUE), .groups="drop") %>%
  # join to spatial data
  left_join(boroughs_sf, by = c("home_name" = "NAME")) %>%
  st_as_sf()

# ─── 3. Create the choropleth ────────────────────────────────────────────────
ggplot(map_data) +
  geom_sf(aes(fill = mean_no2), colour = "grey50") +
  scale_fill_viridis_c(name = "NO2") +
  theme_minimal() +
  labs(title = "Westminster NO2 by Home Borough") +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank())







# Summarise across all ticks (or filter for a subset)
summary_df <- wst_new %>%
  group_by(home_name) %>%
  summarise(mean_no2 = mean(no2_exposed, na.rm=TRUE), .groups="drop")

map_sf <- boroughs_sf %>%
  left_join(summary_df, by = c("NAME" = "home_name"))

map_plot <- ggplot(map_sf) +
  geom_sf(aes(fill = mean_no2), colour = "grey30") +
  scale_fill_viridis_c(name = "NO₂") +
  #labs(title = "Spatial Distribution of NO₂") +
  theme_void() 

dot_plot <- summary_df %>%
  arrange(mean_no2) %>%
  mutate(home_name = factor(home_name, levels=home_name)) %>%
  ggplot(aes(mean_no2, home_name)) +
  geom_point(size=2, colour="#2c3e50") +
  labs(x="NO2", y=NULL, title="Exposure to NO2 who commute to\n the Borough of Westminster") +
  theme_minimal()

map_plot + dot_plot + plot_layout(widths = c(2,1))

ggsave("London.png", map_plot, dpi = 600)
ggsave("graph.png", dot_plot, width = 5, height = 7, dpi = 600)

