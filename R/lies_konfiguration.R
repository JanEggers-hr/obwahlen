#---- Vorbereitung ----
# Statische Daten einlesen
# (das später durch ein schnelleres .rda ersetzen)

# Enthält drei Datensätze: 
# - opendata_wahllokale_df mit der Liste aller Stimmwahlbezirke nach Wahllokal
# - statteile_df: Stadtteil mit Namen und laufender Nummer, Geokoordinaten, Ergebnissen 2018
# - zuordnung_stimmbezirke: Stimmbezirk-Nummer (als int und String) -> Stadtteilnr.

# load ("index/index.rda")


# Konfiguration auslesen und in Variablen schreiben
#
# Generiert für jede Zeile die genannte Variable mit dem Wert value
#
# Derzeit erwartet das Programm: 
# - wahl_name - Name der Wahl ("obwahl_ffm", "obwahl_kassel_stichwahl" etc.)
# - stimmbezirke_url - URL auf Ergebnisdaten
# - kandidaten_fname - Dateiname der Kandidierenden-Liste (s.u.)
# - datawrapper_fname - Dateiname für die Datawrapper-Verweis-Datei
# - stadtteile_fname
# - zuordnung_fname
# - startdatum - wann beginne ich zu arbeiten?
# - wahlberechtigt - Zahl der Wahlberechtigen (kommt Sonntag)
# - briefwahl - Zahl der Briefwahlstimmen (kommt Sonntag)

if (TEST) {
  config_df <- read_csv("index/config_test.csv")
} else {
  config_df <- read_csv("index/config.csv")
}
for (i in c(1:nrow(config_df))) {
  # Erzeuge neue Variablen mit den Namen und Werten aus der CSV
  assign(config_df$name[i],
         # Kann man den Wert auch als Zahl lesen?
         # Fieses Regex sucht nach reiner Zahl oder Kommawerten.
         # Keine Exponentialschreibweise!
         ifelse(grepl("^[0-9]*\\.*[0-9]+$",config_df$value[i]),
                # Ist eine Zahl - wandle um
                as.numeric(config_df$value[i]),
                # Keine Zahl - behalte den String
                config_df$value[i]))
}

lies_daten <- function(fname) {
  if (toupper(str_extract(fname,"(?<=\\.)[A-zA-Z]+$")) %in% c("XLS","XLSX")) {
    # Ist offensichtlich eine Excel-Datei. Lies das erste Sheet.
    return(read.xlsx(fname))
  } else {
    # Geh von einer CSV-Datei aus.
    first_line <- readLines(fname, n = 1)
    commas <- str_split(first_line, ",") %>% unlist() %>% length()
    semicolons <- str_split(first_line, ";") %>% unlist() %>% length()
    if (commas > semicolons) {
      return(read_csv(fname))
    } else {
      # Glaube an das Gute im Menschen: Erwarte UTF-8 und deutsche Kommasetzung.
      return(read_csv2(fname,
                       locale = locale(
                         date_names = "de",
                         date_format = "%Y-%m-%d",
                         time_format = "%H:%M:%S",
                         decimal_mark = ",",
                         grouping_mark = ".",
                         encoding = "UTF-8",
                         asciify = FALSE
                       )))
    }
    
  }
}
# Stadtteilname und -nr; Geokoordinaten. Später: Ergebnisse
# der 2021er Kommunalwahl
stadtteile_df <- lies_daten(paste0("index/",wahl_name,"/",stadtteile_fname))
# Zuordnung Stimmbezirk (Wahllokale und Briefwahl-Bezirke) -> Stadtteil
stimmbezirke_df <- lies_daten(paste0("index/",wahl_name,"/",zuordnung_fname)) %>% 
  # Nummer-Spalten in numerische INdizes umwandeln
  mutate(ortsteilnr = as.integer(ortsteilnr)) %>% 
  mutate(nr = as.integer(nr)) %>% 
  left_join(stadtteile_df %>% select(nr=1,stadtteil=2), by=c("ortsteilnr"="nr"))
# Kandidat:innen-Index
kandidaten_df <- lies_daten(paste0("index/",wahl_name,"/",kandidaten_fname))

# Läufst du auf dem Server?
SERVER <- dir.exists("/home/jan_eggers_hr_de") 

