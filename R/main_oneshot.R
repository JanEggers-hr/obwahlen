library(pacman)

# Laden und ggf. installieren
p_load(this.path)
p_load(readr)
p_load(lubridate)
p_load(tidyr)
p_load(stringr)
p_load(dplyr)
p_load(DatawRappr)
p_load(curl)
p_load(magick)
p_load(openxlsx)

rm(list=ls())

TEST = TRUE
DO_PREPARE_MAPS = FALSE



# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# Aus dem R-Verzeichnis eine Ebene rauf
setwd("..")

# Logfile anlegen, wenn kein Test
# if (!TEST) {
#   logfile = file("obwahl.log")
#   sink(logfile, append=T)
#   sink(logfile, append=T, type="message")
#   
# }

# Messaging-Funktionen einbinden
source("R/messaging.R")


# Hole die Konfiguration und die Index-Daten
check = tryCatch(
  { 
    source("R/lies_konfiguration.R")
  },
  warning = function(w) {teams_warning(w,title="OBWAHL: Warnung beim Lesen der Konfigurationsdatei")},
  error = function(e) {teams_error(e,title="OBWAHL: Konfigurationsdatei nicht gelesen!")})

# Funktionen einbinden
# Das könnte man auch alles hier in diese Datei schreiben, aber ist es übersichtlicher.
source("R/lies_aktuellen_stand.R")
source("R/aktualisiere_karten.R")

#---- MAIN ----
# Vorbereitung
gezaehlt <- 0 # Ausgezählte Stimmbezirke
ts <- as_datetime(startdatum) # ts, Zeitstempel, der letzten gelesenen Daten
stimmbezirke_n <- nrow(stimmbezirke_df) # Anzahl aller Stimmbezirke bei der Wahl
alte_daten <- lies_stimmbezirke(stimmbezirke_url) # Leere Stimmbezirke
# Grafiken einrichten: Farbwerte und Switcher für die Karten
# Richtet auch die globale Variable switcher ein, deshalb brauchen wir sie


if (DO_PREPARE_MAPS) {
  check = tryCatch(
    vorbereitung_alle_karten(),
    warning = function(w) {teams_warning(w,title=paste0(wahl_name,": Vorbereitung"))},
    error = function(e) {teams_warning(e,title=paste0(wahl_name,": Vorbereitung"))}
  )
} else {
  # Alle Datawrapper-IDs in einen Vektor extrahieren
  id_df <- config_df %>% 
    filter(str_detect(name,"_kand[0-9]+")) %>% 
    mutate(Nummer = as.integer(str_extract(name,"[0-9]+"))) %>% 
    select(Nummer,dw_id = value)#
  # Mach aus der Switcher-Tabelle eine globale Variable
  # Nur die Globale switcher_df definieren (mit den IDs der DW-Karten zum Kandidaten/Farbwert)
  switcher_df <- kandidaten_df %>% 
    select(Nummer, Vorname, Name, Parteikürzel, Farbwert) %>% 
    left_join(id_df, by="Nummer")
}

# One-shot. 
check = tryCatch(
    { # Zeitstempel der Daten holen
      ts_daten <- check_for_timestamp(stimmbezirke_url)
    },
    warning = function(w) {teams_warning(w,title=paste0(wahl_name,": CURL-Polling"))},
    error = function(e) {teams_warning(e,title=paste0(wahl_name,": CURL-Polling"))}
  )  
    # Zeitstempel aktualisieren, Datenverarbeitung anstoßen
ts <- ts_daten
# Hole die neuen Daten

hole_wahldaten()

# EOF