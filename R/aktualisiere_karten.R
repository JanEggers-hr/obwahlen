#' aktualisiere_karten.R
#' 
#' Die Funktionen, um die Grafiken zu aktualisieren - und Hilfsfunktionen
#' 

#---- Generiere den Fortschrittsbalken ----


generiere_auszählungsbalken <- function(anz = gezaehlt,max_s = stimmbezirke_n,ts = ts) {
  fortschritt <- floor(anz/max_s*100)
  annotate_str <- paste0("Ausgezählt sind ",
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
  
}

generiere_auszählung_nurtext <- function(anz = gezaehlt,max_s = stimmbezirke_n,ts = ts) {
  fortschritt <- floor(anz/max_s*100)
  annotate_str <- paste0("Ausgezählt: ",
                         anz,
                         " von ",max_s,
                         " Stimmbezirken - ",
                         "<strong>Stand: ",
                         format.Date(ts, "%d.%m.%y, %H:%M Uhr"),
                         "</strong>"
  )
  
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
    text <- link_text(karte_sieger_id,"#F0F0FF","<strong>Sieger nach Stadtteil</strong>")
  } else {
    text <- link_text(karte_sieger_id,"#333333","Sieger nach Stadtteil")
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

karten_body_html <- function(top = 5) {
  # TBD
  text <- "<p style='font-weight: 700;'>Ausgezählt: {{ meldungen_anz }} von {{ meldungen_max }} Wahllokalen{{ meldungen_max != meldungen_anz ? ' - Trendergebnis' : ''}}</p>"
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
                             " }}; padding-bottom: 5%; padding-top: 5%; border-radius: 5px;'></div></div></td>",
                              "<td style='padding-left: 3px; text-align: right; font-size: 0.8em;'>{{ FORMAT(prozent",i,
                              ", '0.0%') }}</td></tr>")
  }
  # Tabelle abbinden
  text <- text %>% paste0(
    "</thead></table>",
    "<p>Wahlberechtigte: {{ FORMAT(wahlberechtigt, '0,0') }}, abgegebene Stimmen: {{ FORMAT(stimmen, '0,0') }}, Briefwahl: {{ FORMAT(stimmen_wahlschein, '0,0') }}, ungültig {{ FORMAT(ungueltig, '0,0') }}"
  )
} 


# Schreibe die Switcher und die Farbtabellen in alle betroffenen Datawrapper-Karten
vorbereitung_alle_karten <- function() {
  # Vorbereiten: df mit Kandidierenden und Datawrapper-ids
  # Alle Datawrapper-IDs in einen Vektor extrahieren
  id_df <- config_df %>% 
    filter(str_detect(name,"_kand[0-9]+")) %>% 
    mutate(Nummer = as.integer(str_extract(name,"[0-9]+"))) %>% 
    select(Nummer,dw_id = value)#
  # Mach aus der Switcher-Tabelle eine globale Variable
  switcher_df <<- kandidaten_df %>% 
    select(Nummer, Vorname, Name, Parteikürzel, Farbwert) %>% 
    left_join(id_df, by="Nummer")
  text_pre <- "<strong>Wählen Sie eine Karte über die Felder:</strong><br>"
  text_post <- "<br><br>Klick auf den Stadtteil zeigt, wer dort führt"
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
  # visualize[["tooltip"]][["title"]] <- karten_title_html(kandidat_s)
  visualize[["tooltip"]][["body"]] <- karten_body_html(top)
  
  dw_edit_chart(karte_sieger_id,intro = dw_intro, annotate = balken_text, visualize = visualize)
  # dw_data_to_chart()
  # dw_publish_chart(karte_sieger_id)
  
  # Jetzt die n Choroplethkarten für alle Kandidaten
  # Müssen als Kopie angelegt sein. 
  for (i in 1:nrow(switcher_df)) {
    dw_intro <- paste0(text_pre,generiere_switcher(switcher_df,0),text_post)
    titel_s <- paste0(switcher_df$Vorname[i]," ",
                     switcher_df$Name[i]," (",
                     switcher_df$Parteikürzel[i],") - ",
                     "Ergebnis nach Stadtteil")
    kandidat_s <- paste0(switcher_df$name[i],
                         " (",
                         switcher_df$Parteikürzel[i])
    metadata_chart <- dw_retrieve_chart_metadata(switcher_df$dw_id[i])
    visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
    # Zwei Farben: Parteifarbe bei Pos. 1, aufgehellte Parteifarbe
    # (zu RGB jeweils 0x40 addiert) bei Pos. 0
    visualize[["colorscale"]][["colors"]][[2]]$color <- switcher_df$Farbwert[i]
    visualize[["colorscale"]][["colors"]][[2]]$position <- 1
    visualize[["colorscale"]][["colors"]][[1]]$color <- aufhellen(switcher_df$Farbwert[i])
    visualize[["colorscale"]][["colors"]][[1]]$position <- 0
    # Karten-Tooltipp anpassen
    # visualize[["tooltip"]][["title"]] <- karten_title_html(kandidat_s)
    visualize[["tooltip"]][["body"]] <- karten_body_html(top)
    dw_edit_chart(switcher_df$dw_id[i],
                  title = titel_s,
                  intro = dw_intro,
                  visualize = visualize,
                  annotate = balken_text)
    # dw_data_to_chart()
    # dw_publish_chart(switcher_df$dw_id)
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
  dw_edit_chart(chart_id = social2_id, visualize = visualize)
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
                  'cp ',social1_fname,' gs://d.data.gcp.cloud.hr.de/', social1_fname))
    system(paste0('gsutil -h "Cache-Control:no-cache, max_age=0" ',
                  'cp ',social2_fname,' gs://d.data.gcp.cloud.hr.de/', social2_fname))
  }
  linktext <- paste0("<a href='https://d.data.gcp.cloud.hr.de/",social1_fname,
                     "'>Download Social-Grafik 1 (5 stärkste)</a><br/>",
                     "<a href='https://d.data.gcp.cloud.hr.de/",social2_fname,
                     "'>Download Social-Grafik 2 (alle Stimmen)</a><br/>")
  return(linktext)
}

#---- Datawrapper-Grafiken generieren ----
aktualisiere_top <- function(kand_tabelle_df,top=5) {
  daten_df <- kand_tabelle_df %>% 
    arrange(desc(Prozent)) %>% 
    select(`Kandidat/in`,Stimmenanteil = Prozent) %>% 
    head(top)
  # Daten pushen
  dw_data_to_chart(daten_df,chart_id = top_id)
  # Intro_Text nicht anpassen. 
  # Balken reinrendern
  balken_text <- generiere_auszählungsbalken(gezaehlt,stimmbezirke_n,ts)
  # Metadaten anpassen: Farbcodes für Parteien
  metadata_chart <- dw_retrieve_chart_metadata(top_id)
  # Save the visualise path
  visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
  # Der Schlüssel liegt unter custom-colors als Liste
  visualize[["custom-colors"]] <- 
    setNames(as.list(kandidaten_df$Farbwert), 
             paste0(kandidaten_df$Name," (",
                    kandidaten_df$Parteikürzel,")"))
  dw_edit_chart(chart_id = top_id,annotate = balken_text, visualize=visualize)
  dw <- dw_publish_chart(chart_id = top_id)
}

aktualisiere_tabelle_alle <- function(kand_tabelle_df) {
  # Daten und Metadaten hochladen, für die Balkengrafik mit allen 
  # Stimmen für alle Kandidaten
  dw_data_to_chart(kand_tabelle_df, chart_id = tabelle_alle_id)
  balken_text <- generiere_auszählung_nurtext(gezaehlt,stimmbezirke_n,ts)
  # Metadaten anpassen: Farbcodes für Parteien
  metadata_chart <- dw_retrieve_chart_metadata(tabelle_alle_id)
  # Save the visualise path
  visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
  visualize[["columns"]][["Prozent"]][["customColorBarBackground"]] <- NULL
  visualize[["columns"]][["Stimmen"]][["customColorBarBackground"]] <- 
    setNames(as.list(kandidaten_df$Farbwert), 
             kandidaten_df$Nummer)
  # Irrtümlich waren die Werte auch noch in visualize[["custom-color"]] gespeichert.
  visualize[["custom-colors"]] <- NULL
  visualize[["color-category"]] <- NULL
  dw_edit_chart(chart_id = tabelle_alle_id, annotate = balken_text, visualize = visualize)
  dw_publish_chart(chart_id = tabelle_alle_id)
}

aktualisiere_karten <- function(ergänzt_df) {
  # Als erstes die Übersichtskarte
  cat("Aktualisiere Karten\n")
  # Die noch überhaupt nicht gezählten Bezirke ausfiltern
  ergänzt_f_df <- ergänzt_df %>% filter(meldungen_anz > 0)
  balken_text = generiere_auszählungsbalken(gezaehlt,stimmbezirke_n,ts)
  dw_edit_chart(chart_id = karte_sieger_id, annotate = balken_text)
  dw_data_to_chart(ergänzt_f_df,chart_id = karte_sieger_id)
  dw <- dw_publish_chart(karte_sieger_id)
  # Jetzt die Choropleth-Karten für alle Kandidierenden
  for (i in 1:nrow(switcher_df)) {
    dw_edit_chart(chart_id=switcher_df$dw_id[i],annotate = balken_text)
    dw_data_to_chart(ergänzt_f_df, chart_id = switcher_df$dw_id[i])
    dw <- dw_publish_chart(switcher_df$dw_id[i])
  }
  cat("Karten neu publiziert\n")
}

aktualisiere_hochburgen <- function(hochburgen_df) {
  # Das ist ziemlich geradeheraus. 
  dw_data_to_chart(hochburgen_df, chart_id = hochburgen_id)
  balken_text <- generiere_auszählung_nurtext(gezaehlt,stimmbezirke_n,ts)
  # Metadaten anpassen: Farbcodes für Parteien
  metadata_chart <- dw_retrieve_chart_metadata(hochburgen_id)
  # Save the visualise path
  visualize <- metadata_chart[["content"]][["metadata"]][["visualize"]]
  # Die Farben für die Kandidaten werden in dieser Tabelle nur für die Balkengrafiken
  # in der Spalte "Prozent" benötigt und richten sich nach der Nummer.
  visualize[["columns"]][["Prozent"]][["customColorBarBackground"]] <- 
    setNames(as.list(kandidaten_df$Farbwert), 
             kandidaten_df$Nummer)
  # Irrtümlich waren die Werte auch noch in visualize[["custom-color"]] gespeichert.
  visualize[["custom-colors"]] <- NULL
  dw_edit_chart(chart_id = hochburgen_id, annotate = balken_text, visualize = visualize)
  dw_publish_chart(chart_id = hochburgen_id)
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
                               across(meldungen_anz:ncol(.), ~sum(.,na.r =FALSE))) %>% 
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
  dw_data_to_chart(ergebnistabelle_df %>% select(-nr), chart_id = tabelle_stadtteile_id)
    # Trendergebnis? Schreibe "Trend" oder "Endergebnis" in den Titel
  gezählt <- e_tmp_df %>% pull(meldungen_anz) %>% sum(.)
  stimmbezirke_n <- e_tmp_df %>% pull(meldungen_max) %>% sum(.)
  ts <- stadtteildaten_df %>% pull(zeitstempel) %>% first()
  titel_s <- paste0(ifelse(gezählt < stimmbezirke_n,"TREND: ",""),
                    "Ergebnisse nach Stadtteil")
  dw_edit_chart(chart_id = tabelle_stadtteile_id,title = titel_s,
                annotate=generiere_auszählung_nurtext(gezählt,stimmbezirke_n,ts))
  dw_publish_chart(tabelle_stadtteile_id)
  cat("Ergebnistabelle nach Stadtteil publiziert\n")
  return(ergebnistabelle_df)
}
