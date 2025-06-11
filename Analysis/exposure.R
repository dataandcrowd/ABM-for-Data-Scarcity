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
  theme_minimal() +
  theme(text = element_text(size = 20))

ggsave("graph2.png", width = 9, height = 5, dpi = 600)


##########

boroughs_sf <- read_sf("../Data/London_Boundary_cleaned.shp")


# Summarise across all ticks (or filter for a subset)
summary_df <- exposure2 %>%
  group_by(home_name) %>%
  summarise(mean_no2 = mean(no2, na.rm=TRUE), .groups="drop")

dot_plot <- summary_df %>%
  arrange(mean_no2) %>%
  mutate(home_name = factor(home_name, levels=home_name)) %>%
  ggplot(aes(mean_no2, home_name)) +
  geom_point(size=2, colour="#2c3e50") +
  labs(x="NO2", y=NULL, title="Mean Exposure to NO2 by London Boroughs") +
  theme_minimal() 

ggsave("graph.png", dot_plot, width = 5, height = 7, dpi = 600)

###------------

label_points <- map_sf %>%
  st_point_on_surface() %>%
  st_cast("POINT")

ggplot() +
  geom_sf(
    data   = map_sf,
    aes(fill = mean_no2),
    colour = "grey30"
  ) +
  scale_fill_viridis_c(name = "NO2") +
  geom_label_repel(
    data            = label_points,
    aes(label       = NAME, geometry = geometry),
    stat            = "sf_coordinates",
    size            = 2.5,
    fill            = alpha("white", 0.6),
    label.size      = 0,
    segment.color   = 1
  ) +
  theme_void() +
  theme(
    legend.title           = element_text(color = "white"),
    legend.text            = element_text(color = "white"),
    legend.background      = element_rect(fill = "transparent", colour = NA),
    legend.key             = element_rect(fill = "transparent", colour = NA),
    legend.box.background  = element_blank()           # also clears any outer box
  )

ggsave("map.png",  dpi = 600)


####

exposure2 |> filter(home_name == "Kingston upon Thames", 
                    destination_name == "Westminster")

exposure2 |> 
  filter(person_id == 7095) |> 
  ggplot(aes(tick, no2, colour = daytype)) +
  geom_smooth() +
  labs(x="Time", y="NO2") +
  theme_minimal() +
  theme(text = element_text(size = 20),
        legend.position = "none") 

ggsave("persona1.png",  dpi = 600)



exposure2 |> 
  filter(person_id == 5840) |> 
  ggplot(aes(tick, no2, colour = daytype)) +
  geom_smooth() +
  labs(x="Time", y="NO2") +
  theme_minimal() +
  theme(text = element_text(size = 20),
        legend.position = "none") 

ggsave("persona2.png",  dpi = 600)
