library(tidyverse)
library(sf)
library(data.table)
library(janitor)


fread("no2-exposure.csv")|> 
  as_tibble() |> clean_names() |> filter(no2 > 0) -> exposure



exposure |> 
  group_by(tick, daytype) |> 
  reframe(no2 = no2) |> 
  ggplot(aes(tick, no2, colour = daytype)) +
  geom_smooth()


inner  <- c("Camden","Greenwich","Hackney","Hammersmith and Fulham",
            "Islington","Kensington and Chelsea","Lambeth","Lewisham",
            "Southwark","Tower Hamlets","Wandsworth","Westminster")

exposure %>%
  mutate(
    zone = if_else(home_name %in% inner, "Inner London", "Outer London")
  ) -> exposure

exposure2 <- exposure %>%
  mutate(
    origin_zone = if_else(home_name %in% inner, "inner", "outer"),
    dest_zone   = if_else(destination_name %in% inner, "inner", "outer"),
    route_type  = paste(origin_zone, dest_zone, sep = "–")  # yields "inner–inner", etc.
  )

# 3. Summarise mean exposure per tick, daytype, and route
route_summary <- exposure2 %>%
  group_by(tick, daytype, route_type) %>%
  summarise(mean_no2 = mean(no2, na.rm = TRUE), .groups = "drop")

# 4. Plot: one line per route_type, faceted by daytype
ggplot(route_summary, aes(x = tick, y = mean_no2, colour = route_type)) +
  geom_smooth(se = FALSE, linewidth = 1) +
  facet_wrap(~ daytype) +
  scale_colour_brewer(palette = "Set2", name = "Route") +
  labs(
    title = "NO2 Exposure by Origin–Destination Zones in London",
    x     = "Time (halfday)",
    y     = "NO2"
  ) +
  theme_minimal()

ggsave("graph2.jpg", width = 9, height = 5, dpi = 600)


##########

boroughs_sf <- read_sf("../Data/London_Boundary_cleaned.shp")


# Summarise across all ticks (or filter for a subset)
summary_df <- exposure2 %>%
  group_by(home_name) %>%
  summarise(mean_no2 = mean(no2, na.rm=TRUE), .groups="drop")

map_sf <- boroughs_sf %>%
  left_join(summary_df, by = c("NAME" = "home_name"))

map_plot <- ggplot(map_sf) +
  geom_sf(aes(fill = mean_no2), colour = "grey30") +
  scale_fill_viridis_c(name = "NO2") +
  #labs(title = "Spatial Distribution of NO₂") +
  theme_void() 

dot_plot <- summary_df %>%
  arrange(mean_no2) %>%
  mutate(home_name = factor(home_name, levels=home_name)) %>%
  ggplot(aes(mean_no2, home_name)) +
  geom_point(size=2, colour="#2c3e50") +
  labs(x="NO2", y=NULL, title="Exposure to NO2 by London Boroughs") +
  theme_minimal()

map_plot + dot_plot + plot_layout(widths = c(2,1))

ggsave("London.png", map_plot, dpi = 600)
ggsave("graph.jpg", dot_plot, width = 5, height = 7, dpi = 600)


##-----------------

