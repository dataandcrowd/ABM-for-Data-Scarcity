

##### KCL NO2
ldn_no2_raw  <- importAURN(site = ldn_sf$code, pollutant = "no2", year = 2022)
ldn_no2_raw2 <- importKCL(site = ldn_sf$code, pollutant = "no2", year = 2022) 


unique(ldn_no2_raw$site)
unique(ldn_no2_raw2$site)


## Next job
# convert the data to 


## Netlogo job
# you find the nearest station

