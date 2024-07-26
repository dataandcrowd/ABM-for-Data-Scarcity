library(sf)
library(tidyverse)

nox <- read_sf("London_NOX.shp")
plot(nox["emiweight"])



# Specify the file name and format
jpeg("nox_emiweight_plot.jpeg", width=8, height=7, units="in", res=300)
plot(nox["emiweight"], 
     main = "NOx Weightings for Greater London Area")
mtext("Based on London Atmospheric Emissions Inventory (LAEI) 2019", side=3, line=1.4, adj=0.42, cex=1)
dev.off() # close the device



