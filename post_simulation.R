library(tidyverse)
library(data.table)

roadsim <- 
  fread("no2_export.csv") %>% 
  as_tibble %>% 
  rename(iteration = `"iteration-count`,
         X = `patch-x`,
         Y = `patch-y`,
         no2 = `no2"` 
         )
nextsim <- 
  fread("no2_patch_neighbours.csv") %>% 
  as_tibble %>% 
  rename(iteration = `"iteration-count`,
         X = `patch-x`,
         Y = `patch-y`,
         no2 = `no2"` 
  )


