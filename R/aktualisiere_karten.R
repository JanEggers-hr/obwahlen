#' aktualisiere_karten.R
#' 
#' Die Funktionen, um die Grafiken zu aktualisieren - und Hilfsfunktionen
#' 


# Sonderbehandlung für OF: 
#
# Hier sind die Stimmbezirke leider überhaupt nicht an den Stadtteilen
# ausgerichtet - deshalb wird nach Wahllokal gruppiert. 
# Und es gibt ein "Wahllokal" mit allen Briefwahl-Ergebnissen, weil
# die Briefwahl-Bezirke leider auch komplett quer zugeordnet sind - 
# und nicht etwa so, dass man sie klar einem Wahllokal zuordnen könnte.
# 'Historische Gründe' schulterzuckt die Offenbacher Stadtverwaltung.
#
# Also brauchen wir eine Möglichkeit, den String "Stadtteil" durch "Ortsteil"
# oder "Wahllokal" zu ersetzen. 
#---- String "Stadtteil" ggf. ersetzen ----
if (!exists("stadtteil_str")) {
  stadtteil_str <- "Stadtteil"
}

#---- Generiere den Fortschrittsbalken ----


generiere_auszählungsbalken <- function(anz = gezaehlt,
                                        max_s = stimmbezirke_n, 
                                        ts = ts) {
  fortschritt <- floor(anz/max_s*100)
  # Anmerkungen ergänzen?
  if (!exists("obwahl_annotate")) obwahl_annotate<-""
  annotate_str <- paste0(obwahl_annotate, "Ausgezählt sind ",
                         # Container Fake-Balken
                         "<span style='height:24px;display: flex;justify-content: space-around;align-items: flex-end; width: 100%;'>",
                         # Vordere Pufferzelle 70px
                         "<span style='width:70px; text-align:center;'>",
                         anz,
                         "</span>",
                         # dunkelblauer Balken
                         "<span style='width:",
                         fortschritt,
                         "%; background:#002747; height:16px;'></span>",
                         # grauer Balken
                         "<span style='width:",
                         100-fortschritt,
                         "%; background:#CCC; height:16px;'></span>",
                         # Hintere Pufferzelle 5px
                         "<span style='width:5px;'></span>",
                         # Ende Fake-Balken
                         "</span>",
                         "<br>",
                         " von ",max_s,
                         " Stimmbezirken - ",
                         "<strong>Stand: ",
                         format.Date(ts, "%d.%m.%y, %H:%M Uhr"),
                         "</strong>"
  )
  return(annotate_str)
}

generiere_auszählung_nurtext <- function(anz = gezaehlt,max_s = stimmbezirke_n,ts = ts) {
  fortschritt <- floor(anz/max_s*100)
  # Anmerkungen ergänzen?
  if (!exists("obwahl_annotate")) obwahl_annotate<-""
  annotate_str <- paste0(obwahl_annotate,
                        "Ausgezählt: ",
                         anz,
                         " von ",max_s,
                         " Stimmbezirken - ",
                         "<strong>Stand: ",
                         format.Date(ts, "%d.%m.%y, %H:%M Uhr"),
                         "</strong>"
  )
  return(annotate_str)
}

#---- Grafik auf JSON/CSV umschalten
# Magische Zutat: 
#  temp[["content"]][["externalData"]] = "https://d.data.gcp.cloud.hr.de/obwahl_test.csv"
#' Wenn dieser Key nicht auch gesetzt ist, hat die CSV-Anzeige ein Caching-Problem und
#' hängt hinter den Metadaten im JSON hinterher. 
#' 
#' Problem: Über den dw_edit_chart Parameter kommen wir nicht dran und müssen deshalb 
#' die eigene Funktion 

remote_control <- function(dw_id) {
    # csv konstruieren: immer die dw_id mit .csv auf dem Google-Bucket.
  # Irgendwie fasse ich nicht, dass ich das nicht schon früher so gemacht habe. 
  # Garantiert, dass die dw_id wirklich nur zu dieser Grafik gehört und liegen blieben kann. 
    csv_path <- paste0(GS_PATH,dw_id,".csv")
    # Metadaten holen
    d <- dw_retrieve_chart_metadata(dw_id)
    data <- d$content$metadata$data
    # Einträge für Metadaten
    data$`upload-method` <- "external-data"
    data$`external-data` <- csv_path
    data$`external-metadata` <-str_replace(csv_path,
                                           "\\.csv",
                                           ".json")
    data$`use-datawrapper-cdn` <- FALSE
    # Und jetzt die magische Zutat: 
    #' Und jetzt die magische Zutat: 
    #' Der externe Pfad MUSS auf externalData geschrieben werden, 
    #' was netterweise mit dw_edit_chart undokumentiert geht, 
    #' sonst tritt das Caching-Problem auf. 
    dw_edit_chart(chart_id = dw_id, data = data, externalData = csv_path)
    dw_publish_chart(dw_id)
}

local_control <- function(dw_id) {
  # Metadaten holen
  d <- dw_retrieve_chart_metadata(dw_id)
  data <- d$content$metadata$data
  # Einträge für Metadaten
  data$`upload-method` <- "copy"
  data$`external-data` <- ""
  data$`external-metadata` <- ""
  data$`use-datawrapper-cdn` <- TRUE
  #' Link ins Datawrapper-CDN
  dwcn_path <- paste0("https://static.dwcdn.net/data/",dw_id,".csv")
  dw_edit_chart(chart_id = dw_id, data = data, externalData = dwcn_path)
  dw_publish_chart(dw_id)
}




#---- Hilfsfunktionen: Switcher generieren, Farben anpassen ----
# Funktion gibt Schwarz zurück, wenn Farbe hell ist, und Weiß, wenn sie 
# relativ dunkel ist. 
font_colour <- function(colour) {
  # convert color to hexadecimal format and extract RGB values
  hex <- substr(colour, 2, 7)
  r <- strtoi(paste0("0x",substr(hex, 1, 2)))
  g <- strtoi(paste0("0x",substr(hex, 3, 4)))
  b <- strtoi(paste0("0x",substr(hex, 5, 6)))

  # suggested by chatGPT: 
  # calculate the brightness of the color using the formula Y = 0.2126*R + 0.7152*G + 0.0722*B
  brightness <- 0.2126 * r + 0.7152 * g + 0.0722 * b
  # compare the brightness to a reference value and return the result
  return(ifelse(brightness > 128,"#000000","#FFFFFF"))
}

aufhellen <- function(Farbwert, heller = 128) {
  #' Funktion gibt einen um 0x404040 aufgehellten Farbwert zurück
  hex <- substr(Farbwert, 2, 7)
  r <- strtoi(paste0("0x",substr(hex, 1, 2))) + heller
  g <- strtoi(paste0("0x",substr(hex, 3, 4))) + heller
  b <- strtoi(paste0("0x",substr(hex, 5, 6))) + heller
  if (r > 255) r <- 255
  if (g > 255) g <- 255
  if (b > 255) b <- 255
  return(paste0("#",as.hexmode(r),as.hexmode(g),as.hexmode(b)))
  
}

# Generiere den Linktext für den Switcher
link_text <- function(id,id_colour,text) {
  lt = paste0("<a target='_self' href='https://datawrapper.dwcdn.net/",
                id,"' style='background:",id_colour,
                "; padding:1px 3px; border-radius:3px; color:",font_colour(id_colour),
                "; cursor:pointer;' rel='nofollow noopener noreferrer'>",
                text,"</a> ")
  return(lt)
}

# Gibt einen String mit HTML/CSS zurück. 
# Nutzt die Kandidierenden-Datei 
generiere_switcher <- function(switcher_df,selected = 0) {
  # Ist der Switcher auf 0 - der Stärkste-Kandidaten-Übersichtskarte?
  if (selected == 0) {
    text <- link_text(karte_sieger_id,"#F0F0FF",
                      paste0("<strong>Sieger nach ",
                             stadtteil_str,"</strong>"))
  } else {
    text <- link_text(karte_sieger_id,"#333333",
                      paste0("Sieger nach ",stadtteil_str))
  }
  for (i in 1:nrow(switcher_df)) {
    if (i == selected) {
      switcher_df$html[i] <- link_text(switcher_df$dw_id[i],
                                       "#F0F0FF",
                                       paste0("<strong>",switcher_df$Name[i],"</strong>"))
    } else {
      switcher_df$html[i] <- link_text(switcher_df$dw_id[i],
                                       switcher_df$Farbwert[i],
                                       switcher_df$Name[i])
    }

  }
  return(paste0(text,paste0(switcher_df$html,collapse="")))
} 

# HTML-Code für die Tooltipp-Mouseovers generieren
# Für alle Karten: Den jeweiligen Kandidaten in den Titel, 
# orientieren an top (Anzahl der Top-Kandidaten),
# Bargraph-Code generieren. 
#
# Die Mouseovers stehen in den Schlüsseln
# - visualize[["tooltip"]][["title"]]
# - visualize[["tooltip"]][["body"]]

karten_titel_html <- function(kandidat_s) {
  # TBD
}

variablerize <- function(name,partei) {
  # Formt aus Namen und Parteikürzel einen Datawrapper-
  # Variablennamen.
  # Aus Leerzeichen und Bindestrichen werden Unterstriche
  # Aus Großbuchstaben werden Kleinbuchstaben
  # Aus Sonderzeichen wird nix
  name <- gsub("[ \\-]","_",name) %>% 
    tolower(.) %>% 
    iconv("latin1", "ASCII", sub="")
  partei <- gsub("[ \\-]","_",partei) %>% 
    tolower(.) %>% 
    iconv("latin1", "ASCII", sub="")
  return(paste0(name,"_",partei))
}

karten_body_html <- function(top = 5) {
  # TBD
  text <- "<p style='font-weight: 700;'>Ausgezählt: {{ meldungen_anz }} von {{ meldungen_max }} Stimmbezirken{{ meldungen_max != meldungen_anz ? ' - Trendergebnis' : ''}}</p>"
  # Generiere String mit allen Prozent-Variablen
  prozent_s <- paste0(paste0("prozent",1:top),collapse=",")
  # Tabellenöffnung
  text <- text %>% paste0("<table style='width: 100%; border-spacing: 0.1em; border-collapse: collapse;'><thead>")
  for (i in 1:top) {
    text <- text %>%  paste0("<tr><th>{{ kand",i,
                             " }}</th><td style='width: 120px; height=16px;'>",
                             "<div style='width: {{ ROUND(((prozent",i,
                             " / MAX(",
                             prozent_s,
                             ")) *100),1) }}%; background-color: {{ farbe",i,
                             " }}; padding-bottom: 5%; padding-top: 5%; border-radius: 5px;'></div></td>",
                              "<td style='padding-left: 3px; text-align: right; font-size: 0.8em;'>{{ FORMAT(prozent",i,
                              ", '0.0%') }}</td></tr>")
  }
  # Tabelle abbinden
  text <- text %>% paste0(
    "</thead></table>",
    "<p>Wahlberechtigte: {{ FORMAT(wahlberechtigt, '0,0') }}, abgegebene Stimmen: {{ FORMAT(stimmen, '0,0') }}, Briefwahl: {{ FORMAT(stimmen_wahlschein, '0,0') }}, ungültig {{ FORMAT(ungueltig, '0,0') }}"
  )
  return(text)
} 


# Schreibe die Switcher und die Farbtabellen in alle betroffenen Datawrapper-Karten
vorbereitung_alle_karten <- function() {
  # Vorbereiten: df mit Kandidierenden und Datawrapper-ids
  # Alle Datawrapper-IDs  der Kandidaten-Karten in einen Vektor extrahieren
  id_df <- config_df %>% 
    filter(str_detect(name,"_kand[0-9]+")) %>% 
    mutate(Nummer = as.integer(str_extract(name,"[0-9]+"))) %>% 
    select(Nummer,dw_id = value)#
  # Mach aus der Switcher-Tabelle eine globale Variable
  switcher_df <<- kandidaten_df %>% 
    select(Nummer, Vorname, Name, Parteikürzel, Farbwert) %>% 
    left_join(id_df, by="Nummer")
  text_pre <- "<strong>Wählen Sie eine Karte über die Schaltflächen:</strong><br>"
  text_post <- "<br><br>Der Klick auf ein Gebiet zeigt, wer dort nach Stimmen führt. Die Größe des Symbols zeigt die Gesamtzahl der Stimmen im Gebiet."
  balken_text <- generiere_auszählungsbalken(gezaehlt,stimmbezirke_n,ts)
  dw_intro=paste0(text_pre,generiere_switcher(switcher_df,0),text_post)
  # Farbskala und Mouseover anpassen
  metadata_chart <- dw_retrieve_chart_metadata(karte_sieger_id)
  visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
  # Farbwerte für die Kandidierenden
  # erst mal löschen
  visualize[["colorscale"]][["map"]] <- NULL
  visualize[["colorscale"]][["map"]] <- setNames(as.list(kandidaten_df$Farbwert),
                                                 kandidaten_df$Name)
  # Karten-Tooltipp anpassen
  visualize[["tooltip"]][["title"]] <- "{{ name }} - {{ meldungen_anz < meldungen_max ? (meldungen_anz == 0 ? \"KEINE DATEN\" : \"TREND\") : \"\" }}"
  visualize[["tooltip"]][["body"]] <- karten_body_html(top)
  visualize[["tooltip"]][["enabled"]] <- TRUE
  # Orte löschen
  visualize[["labels"]][["places"]] <- NULL
  # Anpassen: Symbolgröße
  visualize[["symbol-shape"]] <- "hexagon"
  visualize[["max-size"]] <- 40
  axes <- metadata_chart[["content"]][["metadata"]][["axes"]]
  # Größe der Symbole an die Zahl der gültigen Stimmen binden
  axes[["area"]] <- "gueltig" # Gültige Stimmen
  # ...und die Farbe an den führenden Kandidaten
  axes[["values"]] <- "kand1"
  
  # Karten-Titel und Metadaten anpassen
  dw_edit_chart(karte_sieger_id,
                title = paste0("Trend: Ergebnis nach ",stadtteil_str),
                intro = dw_intro, 
                annotate = balken_text, 
                visualize = visualize,
                source_name = obwahl_q_name,
                source_url = obwahl_q_url)
  # dw_data_to_chart()
  # dw_publish_chart(karte_sieger_id)
  
  # Jetzt die n Choroplethkarten für alle Kandidaten
  # Müssen als Kopie angelegt sein. 
  for (i in 1:nrow(switcher_df)) {
    dw_intro <- paste0(text_pre,generiere_switcher(switcher_df,0),text_post)
    titel_s <- paste0(switcher_df$Vorname[i]," ",
                     switcher_df$Name[i]," (",
                     switcher_df$Parteikürzel[i],") - ",
                     "Ergebnis nach ",stadtteil_str)
    kandidat_s <- paste0(switcher_df$Name[i],
                         " (",
                         switcher_df$Parteikürzel[i],
                         ")")
    metadata_chart <- dw_retrieve_chart_metadata(switcher_df$dw_id[i])
    visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
    # Farbenliste erst mal löschen
    visualize$colorscale$colors <- list(list(),list())
    # Zwei Farben: Parteifarbe bei Pos. 1, aufgehellte Parteifarbe
    # (zu RGB jeweils 0x40 addiert) bei Pos. 0
    visualize[["colorscale"]][["colors"]][[2]]$color <- switcher_df$Farbwert[i]
    visualize[["colorscale"]][["colors"]][[2]]$position <- 1
    visualize[["colorscale"]][["colors"]][[1]]$color <- aufhellen(switcher_df$Farbwert[i])
    visualize[["colorscale"]][["colors"]][[1]]$position <- 0
    # Karten-Tooltipp anpassen
    visualize[["tooltip"]][["title"]] <- paste0(
      "{{ name }} - ",
      kandidat_s,": {{ FORMAT(",
      variablerize(switcher_df$Name[i],switcher_df$Parteikürzel[i]), 
      "\"0.0%\") }}"
    )
    # Legende Farbskala auf Prozent
    visualize[["legends"]][["color"]][["labelFormat"]] <- "0.0%"
    # Orte löschen
    visualize[["labels"]][["places"]] <- NULL
    visualize[["tooltip"]][["body"]] <- karten_body_html(top)
    visualize[["tooltip"]][["enabled"]] <- TRUE
    # Umschalten auf die entsprechende Spalte
    visualize[["map-key-attr"]] <- "Ortsbez_Na"
    axes <- metadata_chart[["content"]][["metadata"]][["axes"]]
    # Index- und Wertespalte setzen
    axes[["keys"]] <- "name"
    axes[["values"]] <- kandidat_s
    # Hochladen
    dw_edit_chart(switcher_df$dw_id[i],
                  title = titel_s,
                  intro = dw_intro,
                  visualize = visualize,
                  axes = axes, 
                  annotate = balken_text,
                  source_name = obwahl_q_name,
                  source_url = obwahl_q_url)
    # dw_data_to_chart()
    # dw_publish_chart(switcher_df$dw_id)
  }
  # Wenn Server: Alle Grafiken auf Remote-Control umschalten!
  if (SERVER) {
    # Alle 5 Hauptgrafiken und die Switcher-Grafiken
    # Sieger-Map
    remote_control(karte_sieger_id)
    # Switcher-Choropleth-Maps
    for (i in switcher_df$dw_id) {
      remote_control(i)
    }
    remote_control(tabelle_alle_id)
    remote_control(tabelle_stadtteile_id)
    remote_control(hochburgen_id)
  } else {
    # Alle 5 Hauptgrafiken und die Switcher-Grafiken
    # Sieger-Map
    local_control(karte_sieger_id)
    # Switcher-Choropleth-Maps
    for (i in switcher_df$dw_id) {
      local_control(i)
    }
    local_control(tabelle_alle_id)
    local_control(tabelle_stadtteile_id)
    local_control(hochburgen_id)
    
  }
  
}

#---- Generiere und pushe die Grafiken für Social Media
generiere_socialmedia <- function() {
  # Fairly straightforward. Rufe zwei Datawrapper-Karten über die API auf, 
  # generiere aus ihnen PNGs, benenne sie mit Zeitstempel, schiebe die auf 
  # den Bucket und gib einen Text mit Link zurück. 
  #
  # Die beiden Karten sind: 
  # - die Aufmacher-Grafik = top_id
  # - die nüchterne Balkengrafik mit allen 20 Kandidat:innen S9BbQ
  #
  # Die Funktion aktualisiert KEINE Daten, sondern nimmt das, was gerade im 
  # Datawrapper ist. Das ggf extra mit dw_data_to_chart(meine_df,social1_id,parse_dates =TRUE)
  # 
  # Setzt gültigen Zeitstempel ts voraus!
  
  # Erste Grafik ist sowieso aktuell und wird nur anders exportiert.
  # dw_data_to_chart(tag_df,social1_id,parse_dates =TRUE)
  social1_png <- dw_export_chart(social1_id,type = "png",unit="px",mode="rgb", scale = 1, 
                  width = 640, height = 640, plain = TRUE, transparent = T)
  social1_fname <- paste0("png/social1_",format.Date(ts,"%Y-%m-%d--%H%Mh"),".png")
  # Zweite Grafik muss aktualisiert und vermetadatet werden
  # Metadaten anpassen: Farbcodes für Parteien
  metadata_chart <- dw_retrieve_chart_metadata(social2_id)
  # Save the visualise path
  visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
  visualize[["color-category"]][["map"]] <- 
    setNames(as.list(kandidaten_df$Farbwert), 
             paste0(kandidaten_df$Name," (",
                    kandidaten_df$Parteikürzel,")"))
  dw_edit_chart(chart_id = social2_id, visualize = visualize,
                source_name = obwahl_q_name,
                source_url = obwahl_q_url)
  dw_data_to_chart(kand_tabelle_df, chart_id = social2_id)
  social2_png <- dw_export_chart(social2_id,type = "png",unit="px",mode="rgb", scale = 1, 
                  width = 640, height = 640, plain = TRUE, transparent = T)
  social2_fname <- paste0("png/social2_",format.Date(ts,"%Y-%m-%d--%H%Mh"),".png")
  # PNG-Dateien generieren...
  if (!dir.exists("png")) {dir.create("png")}
  magick::image_write(social1_png,social1_fname)
  magick::image_write(social2_png,social2_fname)
  #...und auf den Bucket schieben. 
  if (SERVER) {
    system(paste0('gsutil -h "Cache-Control:no-cache, max_age=0" ',
                  'cp ',social1_fname,' gs://d.data.gcp.cloud.hr.de/obwahl/', social1_fname))
    system(paste0('gsutil -h "Cache-Control:no-cache, max_age=0" ',
                  'cp ',social2_fname,' gs://d.data.gcp.cloud.hr.de/obwahl/', social2_fname))
  }
  linktext <- paste0("<a href='https://d.data.gcp.cloud.hr.de/obwahl/",social1_fname,
                     "'>Download Social-Grafik 1 (5 stärkste)</a><br/>",
                     "<a href='https://d.data.gcp.cloud.hr.de/obwahl/",social2_fname,
                     "'>Download Social-Grafik 2 (alle Stimmen)</a><br/>")
  return(linktext)
}

#---- Datawrapper-Grafiken generieren ----
aktualisiere_top <- function(kand_tabelle_df,top=5) {
  # ts liegt als globale Variable vor
  chart_id <- top_id
  daten_df <- kand_tabelle_df %>% 
    arrange(desc(Prozent)) %>% 
    select(`Kandidat/in`,Stimmenanteil = Prozent) %>% 
    head(top)
  # Intro_Text nicht anpassen. 
  # Titel mit Zeitstempel bzw. Endergebnis
  if (gezaehlt < stimmbezirke_n) {
    titel <- paste0("Trend: Ergebnis",
                    format.Date(ts, " (Stand: %H:%M Uhr)"))
  } else {
    titel <- "Vorläufiges Endergebnis"
  }
  # Balken reinrendern
  balken_text <- generiere_auszählungsbalken(gezaehlt,stimmbezirke_n,ts)
  # Metadaten anpassen: Farbcodes für Parteien
  # Daten aufs Google Bucket (für CORS-Aktualisierung)
  if (SERVER) {
    # Jetzt das JSON anlegen
    forced_meta <- list()
    forced_meta[["title"]] <- titel
    forced_meta[["describe"]][["byline"]] <- "Jan Eggers"
    forced_meta[["describe"]][["source-url"]] <- obwahl_q_url
    forced_meta[["describe"]][["source-name"]] <- obwahl_q_name
    forced_meta[["annotate"]][["notes"]] <- balken_text
    # Default-Farbe setzen
    forced_meta[["visualize"]][["custom-colors"]] <- 
      setNames(as.list(kandidaten_df$Farbwert), 
               paste0(kandidaten_df$Name," (",
                      kandidaten_df$Parteikürzel,")"))
    csv_path <- paste0("daten/",chart_id,".csv")
    json_path <- paste0("daten/",chart_id,".json")
    write.csv(daten_df,csv_path, row.names = F)
    system_cmd_csv <- paste0('gsutil -h "Cache-Control:no-cache, max_age=0"',
                             ' cp daten/',
                             chart_id,
                             '.* ',
                             GS_PATH_GS
    )
    
    
    # Liste in JSON - der force-Parameter ist nötig, weil R sonst darauf
    # beharrt, dass es mit der S3-Klasse dw_chart nichts anfangen kann
    # (obwohl die eine ganz normale Liste ist)
    forced_meta_json <- toJSON(forced_meta,force=T)
    write(forced_meta_json,json_path)
    system(system_cmd_csv)
  } else {
    dw_data_to_chart(daten_df, chart_id = chart_id)
    metadata_chart <- dw_retrieve_chart_metadata(chart_id)
    # Save the visualise path
    visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
    # Der Schlüssel liegt unter custom-colors als Liste
    visualize[["custom-colors"]] <- 
      setNames(as.list(kandidaten_df$Farbwert), 
               paste0(kandidaten_df$Name," (",
                      kandidaten_df$Parteikürzel,")"))
    
    # Daten pushen
    dw_edit_chart(chart_id = top_id,
                  title=titel, 
                  annotate = balken_text, visualize=visualize,
                  source_name = obwahl_q_name,
                  source_url = obwahl_q_url)
    dw <- dw_publish_chart(chart_id = top_id)
  }
}

aktualisiere_tabelle_alle <- function(kand_tabelle_df) {
  # Daten und Metadaten hochladen, für die Balkengrafik mit allen 
  # Stimmen für alle Kandidaten
  # Titel mit Zeitstempel bzw. Endergebnis
  chart_id <- tabelle_alle_id
  if (gezaehlt < stimmbezirke_n) {
    titel <- paste0("Alle bisher gezählten Stimmen",
                    format.Date(ts, " (Stand: %H:%M Uhr)"))
  } else {
    titel <- "Vorläufiges Endergebnis: Alle gezählten Stimmen"
  }
  # Keinen Balken in die Annotations rendern
  balken_text <- generiere_auszählung_nurtext(gezaehlt,stimmbezirke_n,ts)
  intro <- "Die bislang gezählten Stimmen für alle Kandidatinnen und Kandidaten in der Reihenfolge vom Stimmzettel."
  # Metadaten anpassen: Farbcodes für Parteien
  # Jetzt das JSON anlegen
  forced_meta <- list()
  forced_meta[["title"]] <- titel
  forced_meta[["describe"]][["intro"]] <- intro
  forced_meta[["describe"]][["byline"]] <- "Jan Eggers"
  forced_meta[["describe"]][["source-url"]] <- obwahl_q_url
  forced_meta[["describe"]][["source-name"]] <- obwahl_q_name
  forced_meta[["annotate"]][["notes"]] <- balken_text
  # Default-Farbe setzen
#  forced_meta[["visualize"]][["columns"]][["Stimmen"]][["barColor"]] <- "#707173"
#  forced_meta[["visualize"]][["columns"]][["Stimmen"]][["customColorBarBackground"]] <- 
#    setNames(as.list(kandidaten_df$Farbwert), 
#             kandidaten_df$Parteikürzel)
#  forced_meta[["visualize"]][["columns"]][["Stimmen"]][["customBarColorBy"]] <- "Parteikürzel"
  
  if (SERVER) {
    csv_path <- paste0("daten/",chart_id,".csv")
    json_path <- paste0("daten/",chart_id,".json")
    write.csv(kand_tabelle_df,csv_path, row.names = F)
    system_cmd_csv <- paste0('gsutil -h "Cache-Control:no-cache, max_age=0"',
                         ' cp daten/',
                         chart_id,
                         '.* ',
                         GS_PATH_GS
                         )

    
    # Liste in JSON - der force-Parameter ist nötig, weil R sonst darauf
    # beharrt, dass es mit der S3-Klasse dw_chart nichts anfangen kann
    # (obwohl die eine ganz normale Liste ist)
    forced_meta_json <- toJSON(forced_meta,force=T)
    write(forced_meta_json,json_path)
    system(system_cmd_csv)
  } else {
    dw_data_to_chart( kand_tabelle_df, chart_id = chart_id)
    metadata_chart <- dw_retrieve_chart_metadata(chart_id)
    # Save the visualise path
    visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
    # Die Farben für die Kandidaten werden in dieser Tabelle nur für die Balkengrafiken
    # in der Spalte "Prozent" benötigt und richten sich nach der Nummer.
    visualize[["columns"]][["Prozent"]][["customColorBarBackground"]] <- 
      setNames(as.list(kandidaten_df$Farbwert), 
               kandidaten_df$Nummer)
    visualize[["columns"]][["Stimmen"]][["barColor"]] <- "#707173"
    visualize[["columns"]][["Stimmen"]][["customBarColorBy"]] <- "Parteikürzel"
    
    dw_edit_chart(chart_id = tabelle_alle_id, 
                  title = titel,
                  intro = intro,
                  annotate = balken_text, visualize = visualize,                  
                  source_name = obwahl_q_name,
                  source_url = obwahl_q_url)
    
    dw_publish_chart(chart_id)
  }
}

aktualisiere_karten <- function(ergänzt_df) {
  # Als erstes die Übersichtskarte
  cat("Aktualisiere Karten\n")
  # Die noch überhaupt nicht gezählten Bezirke ausfiltern
  ergänzt_f_df <- ergänzt_df %>% filter(meldungen_anz > 0)
  chart_id <- karte_sieger_id
  balken_text = generiere_auszählungsbalken(gezaehlt,stimmbezirke_n,ts)
  if (SERVER) {  
    csv_path <- paste0("daten/",chart_id,".csv")
    json_path <- paste0("daten/",chart_id,".json")
    write.csv(ergänzt_f_df,csv_path, row.names = F)
    system_cmd_csv <- paste0('gsutil -h "Cache-Control:no-cache, max_age=0"',
                             ' cp daten/',
                             chart_id,
                             '.* ',
                             GS_PATH_GS
    )
    # Jetzt das JSON anlegen
    forced_meta <- list()
    forced_meta[["describe"]][["byline"]] <- "Jan Eggers"
    forced_meta[["describe"]][["source-url"]] <- obwahl_q_url
    forced_meta[["describe"]][["source-name"]] <- obwahl_q_name
    forced_meta[["annotate"]][["notes"]] <- balken_text
    forced_meta_json <- toJSON(forced_meta,force=T)
    write(forced_meta_json,json_path)
    system(system_cmd_csv)
  } else {
    dw_edit_chart(chart_id = chart_id, 
                  annotate = balken_text,
                  source_name = obwahl_q_name,
                  source_url = obwahl_q_url)
    # Daten pushen
    dw_data_to_chart(ergänzt_f_df,chart_id = chart_id)
    dw <- dw_publish_chart(chart_id = chart_id)
  }
  
  # Jetzt die Choropleth-Karten für alle Kandidierenden
  for (i in 1:nrow(switcher_df)) {
    chart_id <- switcher_df$dw_id[i]
    if (SERVER) {  
      csv_path <- paste0("daten/",chart_id,".csv")
      json_path <- paste0("daten/",chart_id,".json")
      write.csv(ergänzt_f_df,csv_path, row.names = F)
      system_cmd_csv <- paste0('gsutil -h "Cache-Control:no-cache, max_age=0"',
                               ' cp daten/',
                               chart_id,
                               '.* ',
                               GS_PATH_GS
      )
      # Jetzt das JSON anlegen
      forced_meta <- list()
      forced_meta[["describe"]][["byline"]] <- "Jan Eggers"
      forced_meta[["describe"]][["source-url"]] <- obwahl_q_url
      forced_meta[["describe"]][["source-name"]] <- obwahl_q_name
      forced_meta[["annotate"]][["notes"]] <- balken_text
      forced_meta_json <- toJSON(forced_meta,force=T)
      write(forced_meta_json,json_path)
      system(system_cmd_csv)
    } else {
      dw_edit_chart(chart_id,
                    annotate = balken_text,
                    source_name = obwahl_q_name,
                    source_url = obwahl_q_url)
      # Daten pushen
      dw_data_to_chart(ergänzt_f_df, chart_id = chart_id)
      dw <- dw_publish_chart(chart_id)
    }
  }
  cat("Karten neu publiziert\n")
}

aktualisiere_hochburgen <- function(hochburgen_df) {
  # Das ist ziemlich geradeheraus. 
  balken_text <- generiere_auszählung_nurtext(gezaehlt,stimmbezirke_n,ts)
  chart_id <- hochburgen_id
  if (SERVER) {
    csv_path <- paste0("daten/",chart_id,".csv")
    json_path <- paste0("daten/",chart_id,".json")
    write.csv(hochburgen_df,csv_path, row.names = F)
    system_cmd_csv <- paste0('gsutil -h "Cache-Control:no-cache, max_age=0"',
                             ' cp daten/',
                             chart_id,
                             '.* ',
                             GS_PATH_GS
    )
    # Jetzt das JSON anlegen
    forced_meta <- list()
    forced_meta[["describe"]][["byline"]] <- "Jan Eggers"
    forced_meta[["describe"]][["source-url"]] <- obwahl_q_url
    forced_meta[["describe"]][["source-name"]] <- obwahl_q_name
    forced_meta[["annotate"]][["notes"]] <- balken_text
#    forced_meta[["visualize"]][["columns"]][["Prozent"]][["customColorBarBackground"]] <- 
#      setNames(as.list(kandidaten_df$Farbwert), 
#               kandidaten_df$Nummer)
    forced_meta_json <- toJSON(forced_meta,force=T)
    write(forced_meta_json,json_path)
    system(system_cmd_csv)
  } else {
    dw_data_to_chart(hochburgen_df, chart_id = chart_id)  
    metadata_chart <- dw_retrieve_chart_metadata(chart_id)
    # Save the visualise path
    visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
    # Die Farben für die Kandidaten werden in dieser Tabelle nur für die Balkengrafiken
    # in der Spalte "Prozent" benötigt und richten sich nach der Nummer.
    visualize[["columns"]][["Prozent"]][["customColorBarBackground"]] <- 
      setNames(as.list(kandidaten_df$Farbwert), 
               kandidaten_df$Nummer)
    visualize[["columns"]][["Stimmen"]][["customBarColorBy"]] <- "Parteikürzel"
    dw_edit_chart(chart_id = hochburgen_id, annotate = balken_text, visualize = visualize)
    dw_publish_chart(chart_id = hochburgen_id)
  }
  # Metadaten anpassen: Farbcodes für Parteien
  cat("Hochburgen-Grafik neu publiziert\n")
}


aktualisiere_ergebnistabelle <- function(stadtteildaten_df) {
  # Nr des Stadtteils, Stadtteil, Wahlbeteiligung (Info), Ergebnis
  # Wahlbeteiligung und Ergebnis sind jeweils HTML-Text mit den Daten
  # Unleserlich, aber funktional
  e_tmp_df <- stadtteildaten_df %>% 
    select(nr,name,meldungen_anz:ncol(.)) %>% 
    # Nach Stadtteil sortieren
    arrange(name) %>% 
    mutate(sort = row_number())
  # Nochmal ansetzen, um als erste Zeile das Gesamtergebnis einzusetzen
  ergebnistabelle_df <- e_tmp_df %>% summarize(nr = 0, sort = 0,
                               name = "GESAMTERGEBNIS",
                               across(meldungen_anz:ncol(.), ~sum(.,na.rm =FALSE))) %>% 
    bind_rows(e_tmp_df) %>% 
    # Mit den Kandidaten-Namen anreichern
    # Ins Langformat umformen, Nummer ist die Kandidatennummer
    pivot_longer(cols=starts_with("D"),names_to = "Nummer", values_to = "Stimmen") %>% 
    mutate(Prozent = if_else(Stimmen == 0,0,Stimmen / gueltig * 100)) %>% 
    # D1... in Integer umwandeln
    mutate(Nummer = as.numeric(str_extract(Nummer,"[0-9]+"))) %>% 
    left_join(kandidaten_df %>% select (Nummer, Vorname, Name, Parteikürzel),
              by = "Nummer") %>% 
    mutate(`Kandidat/in` = paste0(Name," (",Parteikürzel,")")) %>% 
    # Kandidaten-Tabelle wieder zurückpivotieren
    select(-Vorname, -Name, -Parteikürzel, -Nummer) %>%
    # Nach Stadtteil gruppieren
    group_by(sort,nr,name) %>% 
    # Zusätzliche Variable: Stadtteil gezählt oder TREND?
    mutate(trend = meldungen_anz < meldungen_max) %>% 
    # Big bad summary - jeweils Daten aus den Spalten generieren
    summarize(Stadtteil = paste0("<strong>",first(name),
                                "</strong><br><br>",
                                # TREND oder ERGEBNIS?
                                if_else(first(trend),
                                        paste0("TREND: ",
                                               first(meldungen_anz)," von ",
                                               first(meldungen_max)," Stimmbezirken ausgezählt"),
                                        #...oder alles ausgezählt?
                                        paste0("Alle ",
                                               first(meldungen_max),
                                               " Stimmbezirke ausgezählt"))),
              Wahlbeteiligung = paste0("Wahlberechtigt: ",
                                       # Wenn noch nicht ausgezählt, leer lassen
                                       if_else(first(trend),"",
                                               first(wahlberechtigt) %>% 
                                         format(big.mark = ".", decimal.mark =",")),
                                       "<br>",
                                       "abg. Stimmen: ",first(stimmen) %>% format(big.mark = ".", decimal.mark =","),
                                       " (",
                                       # Nicht gezählte Bezirke haben 0 Wahlberechtigte
                                       if_else(first(trend),"--", 
                                                (first(stimmen)/first(wahlberechtigt) *100) %>% 
                                         round(digits=1) %>% format(decimal.mark=",", nsmall = 1)),
                                       "%)<br>",
                                       "davon Briefwahl: ",
                                       first(stimmen_wahlschein) %>% format(big.mark = ".", decimal.mark =","),
                                       " (",
                                       # Falls noch nicht alles ausgezählt, keinen Prozentwert angeben
                                       if_else(first(trend),
                                               "--",
                                       (first(stimmen_wahlschein) / first(stimmen) * 100) %>% 
                                         round(digits = 1) %>% format(decimal.mark=",", nsmall = 1)),
                                       "%)<br>",
                                       "<br>Ungültig: ",
                                       first(ungueltig) %>% format(big.mark = ".", decimal.mark =","),
                                       "<br>Gültige Stimmen: ",
                                       first(gueltig) %>% format(big.mark = ".", decimal.mark =",")),
              # Hier geschachtelte paste0-Aufrufe: 
              # Der innere baut einen Vektor mit allen Kandidaten plus Ergebnissen
              # Der äußere fügt diesen Vektor zu einem String zusammen (getrennt durch <br>)
              Ergebnis = paste0(paste0("<strong>",`Kandidat/in`,"</strong>: ",
                                       Stimmen %>% format(big.mark=".",decimal.mark=","),
                                       " (",
                                       Prozent %>% round(1) %>% format(decimal.mark=",", nsmall=1),"%)"),
                collapse="<br>")
              ) %>% 
    ungroup() %>% 
    arrange(sort) %>% 
    select(-name,-sort)
  gezählt <- e_tmp_df %>% pull(meldungen_anz) %>% sum(.)
  stimmbezirke_n <- e_tmp_df %>% pull(meldungen_max) %>% sum(.)
  ts <- stadtteildaten_df %>% pull(zeitstempel) %>% first()
  titel_s <- paste0(ifelse(gezählt < stimmbezirke_n,"TREND: ",""),
                    "Ergebnisse nach ",stadtteil_str)
  chart_id <- tabelle_stadtteile_id
  if (SERVER) {
   csv_path <- paste0("daten/",chart_id,".csv")
   json_path <- paste0("daten/",chart_id,".json")
   write.csv(ergebnistabelle_df %>% select(-nr),csv_path, row.names = F)
   system_cmd_csv <- paste0('gsutil -h "Cache-Control:no-cache, max_age=0"',
                            ' cp daten/',
                            chart_id,
                            '.* ',
                            GS_PATH_GS
   )
   # Jetzt das JSON anlegen
   forced_meta <- list()
   forced_meta[["describe"]][["byline"]] <- "Jan Eggers"
   forced_meta[["describe"]][["source-url"]] <- obwahl_q_url
   forced_meta[["describe"]][["source-name"]] <- obwahl_q_name
   forced_meta[["title"]] <- paste0(titel_s,".")
   forced_meta[["annotate"]][["notes"]] <- generiere_auszählung_nurtext(gezählt,stimmbezirke_n,ts)
   
   forced_meta_json <- toJSON(forced_meta,force=T)
   write(forced_meta_json,json_path)
   system(system_cmd_csv)
  } else {
    dw_data_to_chart(ergebnistabelle_df %>% select(-nr), chart_id = chart_id)
    # Trendergebnis? Schreibe "Trend" oder "Endergebnis" in den Titel
    dw_edit_chart(chart_id = chart_id,title = titel_s,
                  annotate=generiere_auszählung_nurtext(gezählt,stimmbezirke_n,ts))
    dw_publish_chart(tabelle_stadtteile_id)
  }
  cat("Ergebnistabelle nach",stadtteil_str,"publiziert\n")
  return(ergebnistabelle_df)
}
