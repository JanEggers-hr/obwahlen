# CORS-Livedaten und Metadaten einsetzen

(Stand: 17.9.2023., vor dem Livetest bei der OB-Wahl Offenbach)

## Daten live anzeigen...

...müssen einfach als CSV auf dem Google-Bucket liegen (CSV mit Komma und UTF-(); 
ich kopiere sie mit

```
system('gsutil -h "Cache-Control:no-cache, max_age=0" cp daten/test.csv gs://d.data.gcp.cloud.hr.de/obwahl_test.csv')
```

auf den Bucket. (Eine einzelne Kopieraktion dauert etwa 2s; das scheint aber vor allem der Overhead
zum Schlüsseltausch zu sein: ob ich eine oder zwei Dateien über stadtteile* kopiere, macht keinen
Unterschied.)

## Metadaten live verändern

https://academy.datawrapper.de/article/328-how-to-create-a-chart-with-live-updating-metadata

Anscheinend ist das eine Routine, die die abgespeicherten Metadaten live verändert anstatt sie
alle einzulesen - sie funktioniert um so besser, je weniger in dem JSON drin ist. Am Anfang hatte ich eine komplette Kopie der Metadaten-Liste, die ich über die API ausgelesen hatte - ging nicht. Reduziert auf den [["content"]][["metadata"]]-Zweig-der Liste ging es so halbwegs - aber erst, als ich auf die einzelnen Einträge aus dem [["content"]][["metadata"]][["describe"]]-Zweig reduziert hatte, ging's. 

Deshalb: die Liste für das JSON sollte nur die Keys enthalten, die man wirklich ändern will!

Also setzt man z.B. einen Eintrag für die Byline (Ersteller) und eine Erklärung in R so: 

```
json <- list() # Leere Liste
json[["describe"]][["byline"]][[1]] <- "Kilroy was here"
json[["describe"]][["intro"]][[1]] <- "Diese Grafik zeigt live modifizierte Grafiken."
json[["annotate"]][["notes"]][[1]] <- "Anmerkungsdaten wurden über CORS in einem JSON-File übergeben"
```

Für jeden Key, den die Routine im JSON findet, legt sie im Metadatensatz unter [[content]][["readonlyKeys"]] einen Eintrag an. (Verrückter Bug: wenn man den Key [["describe"]][["hide-title"]]) anlegt, wird der Titel der Grafik IMMER versteckt, auch wenn dieser Key auf FALSE gesetzt wird. Wie gesagt: nur anlegen, was man braucht!

Kleine Regelverletzung der Import-Routine: Der Titel der Grafik - der in den Datawrapper-Daten unter [["content"]][["title"]] liegt, wird einfach über einen Eintrag ```json[["title"]] <- "Titel"``` angelegt. Der Logik der Metadaten zufolge müsste er dann unter [["content"]][["metadata"]][["title"]] liegen, tut er aber nicht. 

## Eine Datawrapper-Grafik auf CORS-Metadatenlieferung umschalten 

Wenn man die externe Datenanlieferung einschaltet, werden folgende Keys gesetzt: 

```
  data <- d$content$metadata$data
  # Einträge für Metadaten
  data$`upload-method` <- "external-data"
  data$`external-data` <- csv_path
  data$`external-metadata` <- json_path
  data$`use-datawrapper-cdn` <- FALSE
  dw_edit_chart(dw_id, data=data)
```

Die Funktion ```dw_edit_chart()``` ermöglicht den Zugriff auf diesen Metadaten-Zweig über den ```data=``` Parameter. 

Möglicherweise zusätzlich nötig?

- ```json[["content"]][["externalData"]] = <URL CSV>```



