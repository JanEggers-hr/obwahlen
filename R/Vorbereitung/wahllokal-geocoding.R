# Geocoding der Wahllokale in OF

# One-off, könnte man sicher auch mit der config.csv steuern

library(pacman)
p_load(dplyr)
p_load(tidyr)
p_load(tidygeocoder)
p_load(readr)


# Lies die Datei mit den Wahllokalen
wl_df <- read_csv2("index/obwahl_of_2023/shapefiles/opendata-wahllokale.csv") %>% 
  select(name = `Wahlraum-Bezeichnung`,
         street = `Wahlraum-Adresse`) %>% 
  distinct(name,street)

geo_df <- wl_df %>% 
  mutate(country = "Germany",
         city = "Offenbach am Main") %>% 
  geocode(address = street)

write_csv(geo_df,"index/obwahl_of_2023/shapefiles/wahllokale_geocodiert.csv")
