library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(openxlsx)


# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# Aus dem R/Vorbereitungs-Verzeichnis zwei Ebenen rauf
setwd("../..")

stimmzettel_df <- read_delim("rohdaten/wi/Open-Data-06414000-Oberbuergermeisterwahl-Wahlbezirk.csv", 
                             delim = ";", escape_double = FALSE, locale = locale(date_names = "de"), 
                             trim_ws = TRUE)

wahlbezirke_df <- read.xlsx("./rohdaten/wi/wi_wahlbezirke.xlsx")
ortsbezirke_df <- read.xlsx("./rohdaten/wi/wi_ortsbezirke.xlsx")
wb_index_df <- read.xlsx("./rohdaten/wi/index_wahlbezirke_ortsbezirke.xlsx")
wb_index_opendata_df <- read_delim("rohdaten/wi/opendata-wahllokale(3).csv", 
                                   delim = ";", escape_double = FALSE, locale = locale(date_names = "de"), 
                                   trim_ws = TRUE)

# Stimmbezirke vom Stimmzettel
wb_st <- stimmzettel_df$`gebiet-nr`
# Stimmbezirke aus der Stimmbezirks-Datei aus dem Shapefile
wb_shape <- wahlbezirke_df$Wahlbezirk

# Stimm
wb_nu <- wb_st[!wb_st %in% wb_shape]
wb_nu

# Vermutung: Berechnungsmethode Wahlbezirk <--> Ortsbezirk. Erstelle Referenztabelle

wb_map_df <- wb_index_df %>% 
  mutate(wb = as.integer(Wahlbezirk)) %>% 
  select(id=1,name=2,wb) %>% 
  group_by(id,name) %>% 
  mutate(wb = wb %/% 100) %>% 
  summarize(wb = list(unique(wb)))

# Funktion, um Stimmbezirke zuzuordnen
to_ortsteil <- function(x) {
  # Die Ortsteil-Nr. ist entweder: 
  # - bei Wahlbezirken: die Nr. des Stimmbezirks / 100 
  # - bei Briefwahlbezirken: die Nr. des Wahlbezirks ohne 99 durch 10
  tmp <- ifelse(x >99000, (x %% 1000) %/% 10, x %/% 100)
  # Ortsteile 3,4,5 sind alle 3 Südost
  if (tmp %in% c(3,4,5)) { tmp <- 3}
  # Ortsteile 14, 15 sind alle 14 Biebrich
  if (tmp %in% c(14,15)) { tmp <- 14}
  if (!tmp %in% wb_map_df$id) {
    stop("Ungültiger Ortsteil: ",x)
  }
  return(tmp)
}

#' ```index/wahlname/zuordnung_wahllokale.csv```- 
#' Die Stimmbezirks-Datei enthält die Zuordnungen für die Wahlbezirke zu Stadtteilen 
#' und wird aus der Open-Data-Beispieldatei des votemanagers erstellt: 
#' -	nr | ID des Stimmbezirks
#' -	ortsteilnr | ID des Stadtteils
#' -	ortsteil | Name des Stadtteils
#' Nicht benötigte Spalten können in der Tabelle bleiben, 
#' sollten aber möglichst nicht "name" oder so heißen.

ortsteile_idx_df <- wb_index_opendata_df %>% 
  rowwise() %>% 
  mutate(ortsteilnr = to_ortsteil(`Bezirk-Nr`)) %>% 
  ungroup() %>% 
  select(nr = `Bezirk-Nr`,
         wb_name = `Bezirk-Name`,
         adresse = `Wahlraum-Adresse`,
         ortsteilnr) %>% 
  mutate(wb_name = str_replace(wb_name,"^[0-9]+ ","")) %>% 
  left_join(ortsbezirke_df %>% select(ortsteilnr = Ortsbez_ID,
                                      ortsteil = Ortsbez_Na),by="ortsteilnr")

# Index Ortsteile schreiben

write.xlsx(ortsteile_idx_df,"index/wi/wahlbezirke.xlsx")

wahllokale_v <- ortsteile_idx_df %>% filter(nr<99000) %>% pull(wb_name) %>% unique()
