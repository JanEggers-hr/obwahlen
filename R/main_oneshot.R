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
p_load(R.utils)
p_load(teamr)
p_load(jsonlite)

rm(list=ls())

# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# Aus dem R-Verzeichnis eine Ebene rauf
setwd("..")

# Lies Kommandozeilen-Parameter: 
# (Erweiterte Funktion aus dem R.utils-Paket)
args = R.utils::commandArgs(asValues = TRUE)
if (length(args)!=0) { 
  if (any(c("h","help","HELP") %in% names(args))) {
    cat("Parameter: \n",
        "--TEST schaltet Testbetrieb ein\n",
        "--DO_PREPARE_MAPS schaltet Generierung der Switcher ein\n",
        "wahl_name=<name> holt Index-Dateien aus dem Verzeichnis ./index/<name>\n\n")
  }
  TEST <- "TEST" %in% names(args)
  DO_PREPARE_MAPS <- "DO_PREPARE_MAPS" %in% names(args)
  if ("wahl_name" %in% names(args)) {
    wahl_name <- args[["wahl_name"]]
    if (!dir.exists(paste0("index/",wahl_name))) stop("Kein Index-Verzeichnis für ",wahl_name)
  }
} 

# Defaults
if (!exists("wahl_name")) wahl_name = "obwahl"
TEST = TRUE
DO_PREPARE_MAPS = TRUE
NO_SOCIAL = TRUE



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
