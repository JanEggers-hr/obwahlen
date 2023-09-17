# socialmedia_test.R
#
# Schickt mit der Funktion generiere_socialmedia() aus der Datei aktualisiere_karten
# eine Teams-Nachricht

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

# Lies Test-Config, falls aktiviert
TEST = TRUE

# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# Aus dem R-Verzeichnis eine Ebene rauf
setwd("..")

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
# source("R/lies_aktuellen_stand.R")
source("R/aktualisiere_karten.R")

ts = now()
# String generieren
some_linktext <- generiere_socialmedia()

teams_meldung("<h2>Socialmedia-Test</h2>",some_linktext,title = wahl_name)
