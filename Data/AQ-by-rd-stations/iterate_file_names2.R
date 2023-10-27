library(tidyverse)

files <- list.files(pattern = "\\.csv$")


for (i in 1:length(files)){
  line1 <- paste0("let entirelist_", files[i], " item ticks aq_", files[i])  
  line2 <- paste0("let aq_", files[i],"_ ", "sublist entirelist_", files[i] , " 5 29")
  line3 <- paste0("let aq_", files[i],"__ ", "remove -999 ", "aq_", files[i],"_")
  line4 <- paste0("ask one-of patches with [monitor-code = ", files[i], "][set no2 aq_", files[i], "__]")
  
  print(line1)
  print(line2)
  print(line3)
  print(line4)
}


