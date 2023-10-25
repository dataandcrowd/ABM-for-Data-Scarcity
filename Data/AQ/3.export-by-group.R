library(tidyverse)

bg <- read_csv("London_AQ_tidy_bg.csv")
rd <- read_csv("London_AQ_tidy_rd.csv")

bg %>% 
  group_by(code, site) %>%
  do(write_csv(., paste0("output/", unique(.$code), ".csv")))


rd %>% 
  group_by(code, site) %>%
  do(write_csv(., paste0("output/", unique(.$code), ".csv")))


