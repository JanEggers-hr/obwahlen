# Kurzes Testprogramm: 
# Holt JSON-Daten, 
library(pacman)
#devtools::install_github("munichrocker/DatawRappr")
library(DatawRappr)
p_load(jsonlite)
p_load(lubridate)
p_load(tidyr)
p_load(dplyr)


# Aktueller Stand: 17.9. morgens
# Lege derzeit komplettes JSON an, müsste aber nur die readonlyKeys anlegen
# siehe Dokumentation
# deshalb temp auf Zweig [["content"]][["metadata"]] reduziert
#
# Problem: Die datawRappr-Library erlaubt nur den Zweig [["content"]][["metadata"]][["visualize"]]
# direkt zu ändern. Da muss ich sie wohl umgehen. 

# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# Aus dem R/Vorbereitung-Verzeichnis zwei Ebenen rauf
setwd("../..")


test_id <- "EehUB" 
# Metadaten holen: Tabelle OBwahl OF Ergebnisse nach Stadtteil

if (file.exists("daten/test.json")) {
  temp <- read_json("daten/test.json")
} else {
  # File neu anlegen
  temp <- dw_retrieve_chart_metadata(test_id)
#  temp[["content"]][["metadata"]][["data"]][["upload-method"]] = "external-data"
#  temp[["content"]][["externalData"]] = "https://d.data.gcp.cloud.hr.de/obwahl_test.csv"
#  temp[["content"]][["metadata"]][["data"]][["external-data"]] = "https://d.data.gcp.cloud.hr.de/obwahl_test.csv"
#  temp[["content"]][["metadata"]][["data"]][["external-metadata"]] = "https://d.data.gcp.cloud.hr.de/obwahl_test.json"
#  temp[["content"]][["metadata"]][["data"]][["use-datawrapper-cdn"]] = TRUE
  
  temp <- temp[["content"]][["metadata"]]
  # Pfade löschen
  # nur die Überschreibungen anlegen
  temp[["title"]] <- "TESTTITEL BLANK CORS"
  temp[["data"]] <- NULL
  temp[["axes"]] <- NULL
  temp[["custom"]] <- NULL
  temp[["publish"]] <- NULL
  temp[["json_error"]] <- NULL
  # Bleiben die Keys für den Titel, describe, visualize, annotate
  temp[["visualize"]] <- NULL
  temp[["title"]] <- NULL
  
  temp[["describe"]][["hide-title"]] <- NULL

  temp_json <- toJSON(temp,force=T)
  write(temp_json,"daten/test.json")
  
  
}



# Auf blöd irgendwas verändern
temp[["title"]] = paste0("DEMO Live-Veränderung ",now())
temp[["describe"]][["byline"]] = paste0("Cors-Daten um ",now())

# auch in den Daten
data_df <- read.csv("https://d.data.gcp.cloud.hr.de/obwahl_stadtteile.csv")
data_df$Stadtteil[1] = now()
write.csv(data_df,"daten/test.csv")
system('gsutil -h "Cache-Control:no-cache, max_age=0" cp daten/test.csv gs://d.data.gcp.cloud.hr.de/obwahl_test.csv')



# Liste in JSON - der force-Parameter ist nötig, weil R sonst darauf
# beharrt, dass es mit der S3-Klasse dw_chart nichts anfangen kann
# (obwohl die eine ganz normale Liste ist)
temp_json <- toJSON(temp,force=T)
# temp_list <- list(temp)
write(temp_json,"daten/test.json")
# 
n <- now()
system('gsutil -h "Cache-Control:no-cache, max_age=0" cp daten/test.json gs://d.data.gcp.cloud.hr.de/obwahl_test.json')
cat("gsutil-Operation took ",now()-n)


#
temp2 <- dw_retrieve_chart_metadata(test_id)
# Der Key für die externe Daten-URL ist [["content"]][["externalData"]]
# Außerdem
# temp2[["content"]][["metadata"]][["data"]][["upload-method"]] = "external-data"
# temp2[["content"]][["metadata"]][["data"]][["external-data"]] = URL CSV
# temp2[["content"]][["metadata"]][["data"]][["external-metadata"]] = URL JSON
# temp2[["content"]][["metadata"]][["data"]][["use-datawrapper-cdn"]] = F

dw_edit_chart(test_id, title="TEST NEU")
# M;öglicher Bug?
# Datawrapper scheint bei JSON-Import hide-title zu setzen - kann es von Hand nicht
# ausschalten
# Deshalb: temp[["describe"]][["hide-title"]] <- NULL - dann geht's!

