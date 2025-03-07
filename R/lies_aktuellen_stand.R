# Library-Aufrufe kann man sich eigentlich sparen, aber...
library(readr)
library(lubridate)
library(tidyr)
library(stringr)
library(dplyr)
library(openxlsx)
library(curl)

# lies_aktuellen_stand.R
#
# Enthält die Funktion zum Lesen der aktuellen Daten. 

#---- Hilfsfunktionen ----

archiviere <- function(df,a_directory = "daten/stimmbezirke") {
  #' Schreibt das Dataframe mit den zuletzt geholten Stimmbezirks-Daten
  #' als Sicherungskopie in das angegebene Verzeichnis
  #' 
  if (!dir.exists(a_directory)) {
    dir.create(a_directory)
  }
  fname = paste0(a_directory,"/",
                # Zeitstempel isolieren und alle Doppelpunkte
                # durch Bindestriche ersetzen
                str_replace_all(df %>% pull(zeitstempel) %>% last(),
                                "\\:","_"),
                ".csv")
  write_csv(df,fname)
  cat(as.character(now())," - Daten archiviert als ",paste0(a_directory,fname))
}

hole_letztes_df <- function(a_directory = "daten/stimmbezirke") {
  #' Schaut im angegebenen Verzeichnis nach der zuletzt angelegten Datei
  #' und holt die Daten zurück in ein df
  if (!dir.exists(a_directory)) return(tibble())
  # Die zuletzt geschriebene Datei finden und einlesen
  neuester_file <- list.files(a_directory, full.names=TRUE) %>% 
    file.info() %>% 
    # Legt eine Spalte namens path an
    tibble::rownames_to_column(var = "path") %>% 
    arrange(desc(ctime)) %>% 
    head(1) %>% 
    # Pfad wieder rausziehen
    pull(path)
  if (length(neuester_file)==0) {
    # Falls keine Daten archiviert, gibt leeres df zurück
    return(tibble())
  } else {
    return(read_csv(neuester_file))
  }
}

# Sind die beiden df abgesehen vom Zeitstempel identisch?
# Funktion vergleicht die numerischen Werte - Spalte für Spalte.
vergleiche_stand <- function(alt_df, neu_df) {
  #' Spaltenweiser Vergleich: Haben die Daten sich verändert? 
  #' (Anders gefragt: ist die Summe aller numerischen Spalten gleich?)
  #' Wurde für die Feldmann-Wahl benötigt; bei OB-Wahlen eigentlich überflüssig
  neu_sum_df <- alt_df %>% summarize_if(is.numeric,sum,na.rm=T)
  alt_sum_df <- neu_df %>% summarize_if(is.numeric,sum,na.rm=T)
  # Unterschiedliche Spaltenzahlen? Dann können sie keine von Finns Männern sein.
  if (length(neu_sum_df) != length(alt_sum_df)) return(FALSE)
  # Differenzen? Dann können sie keine von Finns Männern sein. 
  return(sum(abs(neu_sum_df - alt_sum_df))==0)
}


#--- CURL-Polling (experimentell!)
#
# Gibt das Änderungsdatum der Daten-Datei auf dem Wahlamtsserver zurück - 
# wenn es sich verändert hat, ist das das Signal, neue Daten zu holen. 
check_for_timestamp <- function(my_url) {
  # Erst checken: Wirklich eine Internet-Verbindung? 
  # Sonst behandle als lokale Datei. 
  if(str_detect(my_url,"^http")) {
    tmp <- curlGetHeaders(my_url, redirect = T, verify = F)
    # Redirect 
    # if (stringr::str_detect(tmp[1]," 404")) {
      # Library(curl)
      h <- new_handle()
      # Das funktioniert, holt aber alle Daten -> hohe Last
      t <- curl_fetch_memory(my_url,handle=h)$modified %>% 
        as_datetime() + hours(1)
    # } else {
    #   t <- tmp[stringr::str_detect(tmp,"last-modified")] %>% 
    #     stringr::str_replace("last-modified: ","") %>% 
    #     parse_date_time("%a, %d %m %Y %H:%M:%S",tz = "CET") 
    # }
  } else { # lokale Datei
    t = file.info(my_url)$ctime %>%  as_datetime
    print(t)
  }
  return(t)
}

#---- Aktualisierungs-Funktion ----


#---- Lese-Funktionen ----

# Das hier ist die Haupt-Lese-Funktion
lies_stimmbezirke <- function(stand_url = stimmbezirke_url) {
  #' Versuche, Daten vom Wahlamtsserver zu lesen - und gib ggf. Warnung oder Fehler zurück
  #' Schreibt eine Meldung ins Logfile - zugleich ein Lesezeichen
  cat(as.character(now())," - Neue Daten lesen\n") # Touch logfile
  check = tryCatch(
    { 
      stand_df <- read_delim(stand_url, 
                         delim = ";", escape_double = FALSE, 
                         locale = locale(date_names = "de", 
                                         decimal_mark = ",", 
                                         grouping_mark = "."), 
                         trim_ws = TRUE) %>% 
      # Spalten umbenennen, Zeitstempel-Spalte einfügen
                    mutate(zeitstempel=ts)  %>%
      # Sonderregel: wir haben einen Zeitstempel, die "datum"-Spalte macht
      # Probleme, weil: starts_with("D"). 
                    select(-datum) %>% 
                    select(zeitstempel,
                           nr = `gebiet-nr`,
                           name = `gebiet-name`,
                           meldungen_anz = `anz-schnellmeldungen`,
                           meldungen_max = `max-schnellmeldungen`,
                           # Ergebniszellen
                           wahlberechtigt = A,
                           # Mehr zum Wahlschein hier: https://www.bundeswahlleiter.de/service/glossar/w/wahlscheinvermerk.html
                           waehler_regulaer = A1,
                           waehler_wahlschein = A2,
                           waehler_nv = A3,
                           stimmen = B,
                           stimmen_wahlschein = B1, 
                           ungueltig = C,
                           gueltig = D,
                           # neu: alle Zeilen mit Stimmen (D1..Dn)
                           starts_with("D")) %>% 
        # Zusatz für Frankfurt, das die Stimmbezirksnummern als character überträgt
        mutate(nr = as.integer(nr))
      
      },
    warning = function(w) {teams_warning(w,title="OB-Wahl: Datenakquise")},
    error = function(e) {teams_warning(e,title="OB-Wahl: Datenakquise")})
  return(stand_df)
}

aggregiere_stadtteildaten <- function(stimmbezirksdaten_df = stimmbezirksdaten_df) {
  #' Liest Stimmbezirke, gibt nach Ortsteil aggregierte Daten zurück
  #' (hier: kein Sicherheitscheck)
  stadtteildaten_df <- stimmbezirksdaten_df %>% 
    left_join(stimmbezirke_df %>% select(nr,ortsteilnr,stadtteil),
              by="nr") %>% 
    group_by(ortsteilnr)   %>% 
    # Fasse alle Spalten von meldungen_anz bis Ende der Tabelle zusammen - 
    # mit der sum()-Funktion (NA wird wie null behandelt)
    summarize(zeitstempel = last(zeitstempel),
              nr = first(ortsteilnr), 
              meldungen_anz = sum(meldungen_anz,na.rm =T),
              meldungen_max = sum(meldungen_max,na.rm = T),
              wahlberechtigt = sum(wahlberechtigt, na.rm = T),
              waehler_regulaer = sum(waehler_regulaer, na.rm = T),
              waehler_wahlschein = sum(waehler_wahlschein, na.rm = T),
              waehler_nv = sum(waehler_nv, na.rm = T),
              stimmen = sum(stimmen, na.rm = T),
              stimmen_wahlschein = sum(stimmen_wahlschein, na.rm = T),
              ungueltig = sum(ungueltig, na.rm = T),
              gueltig = sum(gueltig, na.rm = T),
              across(starts_with("D"), ~ sum(.,na.rm = T))) %>%
    mutate(across(where(is.numeric), ~ifelse(is.na(.), 0, .))) %>% 
    # Stadtteilnamen, Geokoordinaten dazuholen
    left_join(stadtteile_df, by="nr") %>% 
    # Wichtige Daten für bessere Lesbarkeit nach vorn
    relocate(zeitstempel,nr,name,lon,lat)
    
  # Sicherheitscheck: Warnen, wenn nicht alle Ortsteile zugeordnet
  if (nrow(stadtteildaten_df) != nrow(stadtteile_df)) teams_warning("Nicht alle Stadtteile zugeordnet")
  if (nrow(stimmbezirke_df) != length(unique(stimmbezirke_df$nr))) teams_warning("Nicht alle Stimmbezirke zugeordnet")
  cat("Stadtteildaten aggregiert.\n")
  return(stadtteildaten_df)
}

#---- Die Tabellen für die DW-Grafiken ergänzen ----
berechne_ergänzt <- function(stadtteildaten_df = stadtteildaten_df, top = top) {
  #' Ergänze die jeweils fünf führenden Kandidaten, ihre Prozentanteile ihre 
  #' Stimmen und ihre Farbwerte. Und benenne die D1...Dn-Spalten nach 
  #' Kandidat/in/Partei in der Form "Müller (ABC)" - gleichzeitig der Index für DW
  #' 
  #' Gibt eine megalange Tabelle für Datawrapper zurück. 

  # Zuerst ein temporäres Langformat, bei dem jede/d Kand in jedem Stadtteil eine Zeile 
  # hat. Das brauchen wir 2x, um es wieder zusammenführen zu können. 
  tmp_long_df <- stadtteildaten_df %>%
    pivot_longer(cols = starts_with("D"), names_to = "kand_nr", values_to = "kand_stimmen") %>% 
    mutate(kand_nr = as.integer(str_extract(kand_nr,"[0-9]+"))) %>% 
    # Ortsteil- bzw. Stimmbezirks-Gruppen, um dort nach Stimmen zu sortieren
    group_by(nr,name) %>% 
    arrange(desc(kand_stimmen)) %>% 
    mutate(Platz = row_number()) %>%
    left_join(kandidaten_df %>% select(kand_nr = Nummer, 
                                       kand_name = Name,
                                       kand_partei = Parteikürzel,
                                       farbe= Farbwert), by="kand_nr") %>% 
    mutate(kand = paste0(kand_name," (",kand_partei,")")) %>% 
    mutate(prozent = if_else(gueltig != 0,kand_stimmen / gueltig * 100, 0)) 
  ergänzt_df <- tmp_long_df %>% 
    # Ist noch nach Stadtteil (name, nr) sortiert
    arrange(kand_nr) %>% 
    # Alles weg, was verhindert, was individuell auf den Kand ist - außer
    #  kand und Prozentwert
    select(-kand_stimmen, -kand_nr, -Platz, -kand_name, -kand_partei, -farbe) %>% 
    # Kandidatennamen in die Spalten zurückverteilen
    pivot_wider(names_from = kand, values_from = prozent) %>% 
    ungroup() %>% 
    # und die zweite Hälfte dazu: 
    left_join(
      tst <- tmp_long_df %>% 
                # Brauchen nur die Kand-Ergebnisse - und den (Stadtteil-)name
                select(name, Platz, kand=kand_name,prozent,farbe) %>% 
                # Nur die ersten (top) Plätze
                filter(Platz <= (top)) %>% 
    #The Big Pivot: Breite die ersten (top) aus. 
    pivot_wider(names_from = Platz,
                values_from = c(kand,prozent,farbe),
                names_glue = "{.value}{Platz}") %>% 
        ungroup() %>% 
        select(-nr),   
    by="name") %>% 
    # Sonderregelung: Wenn keine Stimmen, weise kand1-(top) NA zu (wg. Stadtteilen ohne Daten)
    mutate(across(starts_with("kand"), ~ if_else(meldungen_anz > 0, .,""))) %>% 
    mutate(across(starts_with("farbe"),  ~ if_else(meldungen_anz > 0, .,"#aaaaaa")))
  cat("Ergänzte Stadtteildaten berechnet.\n")
  return(ergänzt_df)
}

berechne_kand_tabelle <- function(stimmbezirksdaten_df = stimmbezirksdaten_df) {
  # Nimmt die Stadtteildaten - oder auch die Wahllokale - und berechne daraus die
  # Nummer, Kandidat(in) in der Form "Müller (XYZ)", Parteikürzel, Stimmen, Prozent
  kand_tabelle_df <- stimmbezirksdaten_df %>% 
    summarize(gueltig = sum(gueltig, na.rm = T),
      across(starts_with("D"), ~ sum(.,na.rm=TRUE))) %>% 
    pivot_longer(cols=starts_with("D"),names_to = "nr", values_to = "Stimmen") %>% 
    # Namen in Nr. umwandeln
    mutate(Nummer = as.integer(str_extract(nr,"[0-9]+"))) %>% 
    left_join(kandidaten_df %>%  select(Nummer, Name, Parteikürzel, Farbwert), 
              by="Nummer") %>% 
    mutate(name = paste0(Name," (",Parteikürzel,")")) %>% 
    mutate(Prozent = ifelse(gueltig > 0, 
                            Stimmen / gueltig * 100,
                            0)) %>% 
    select(Nummer, `Kandidat/in` = name, Parteikürzel, Stimmen, Prozent)
  cat("Gesamttabelle alle Kandidaten berechnet.\n")
  return(kand_tabelle_df)
}

berechne_hochburgen <- function(stadtteildaten_df = stadtteildaten_df) {
  # Tabelle mit den drei stärksten und drei schwächsten Stadtteilen
  # im Vergleich zu GESAMT
  hochburgen_df <- stadtteildaten_df %>% 
    select(name,gueltig,D1:ncol(.)) %>% 
    # Eine Zeile für Frankfurt dazu
    bind_rows(stadtteildaten_df %>% 
                select(name,gueltig,D1:ncol(.)) %>% 
                summarize(gueltig = sum(gueltig, na.rm = T),
                          across(starts_with("D"), ~ sum(.,na.rm=TRUE))) %>% 
                mutate(name = "GESAMT")) %>% 
    # Ins Langformat umformen, Nummer ist die Kandidatennummer
    pivot_longer(cols=starts_with("D"),names_to = "Nummer", values_to = "Stimmen") %>% 
    mutate(Prozent = if_else(Stimmen == 0,0,Stimmen / gueltig * 100)) %>% 
    # D1... in Integer umwandeln
    mutate(Nummer = as.numeric(str_extract(Nummer,"[0-9]+"))) %>% 
    mutate(ist_gesamt = (name == "GESAMT")) %>% 
    # Wichtig: "Currently, group_by() internally orders in ascending order."
    group_by(Nummer,ist_gesamt) %>% 
    arrange(desc(Prozent)) %>% 
    mutate(Platz = row_number()) %>% 
    filter(Platz <= 3 | Platz > (nrow(stadtteile_df) - 3)) %>% 
    mutate(Platz = if_else(ist_gesamt, as.integer(0),row_number())) %>% 
    ungroup(ist_gesamt) %>% 
    arrange(Platz) %>% 
    # Namen dazuholen
    left_join(kandidaten_df %>% select (Nummer, Vorname, Name, Parteikürzel),
              by = "Nummer") %>% 
    mutate(`Kandidat/in` = if_else(ist_gesamt,
                                   paste0(Vorname," ",Name," (",Parteikürzel,")"),
                                   "")) %>% 
    # sortieren
    mutate(sort = 7* Nummer + Platz) %>% 
    ungroup() %>% 
    arrange(sort) %>% 
    select(Nummer, `Kandidat/in`, Stadtteil = name, Prozent)
  cat("Hochburgen nach Kandidaten berechnet.\n")
  return(hochburgen_df)    
}
#---- Haupt-Funktion ----
#
# 
hole_wahldaten <- function() {
      # Hole und archiviere die Stimmbezirks-Daten; 
      # erzeuge ein df mit den Stimmen nach Stadtteil. 
      stimmbezirksdaten_df <<- lies_stimmbezirke(stimmbezirke_url) 
      gezaehlt <<- stimmbezirksdaten_df %>% pull(meldungen_anz) %>% sum(.)
      archiviere(stimmbezirksdaten_df,paste0("daten/",wahl_name,"/"))
      kand_tabelle_df <<- berechne_kand_tabelle(stimmbezirksdaten_df)
      stadtteildaten_df <<- aggregiere_stadtteildaten(stimmbezirksdaten_df)
      ergänzt_df <<- berechne_ergänzt(stadtteildaten_df,top)
      hochburgen_df <<- berechne_hochburgen(stadtteildaten_df)
      # Neue Daten: Die Stimmdaten-zeilen, die ausgezählt sind. 
      neue_daten <<- stimmbezirksdaten_df %>%
        # Filtere auf alle gezählten Stimmbezirke
        filter(meldungen_anz == 1) %>% 
        # Ziehe die ab, die schon in den alten Daten gezählt waren
        anti_join(alte_daten %>% 
                    filter(meldungen_anz == 1) %>% 
                    select(name),
                  by="name")
      alte_daten <<- stimmbezirksdaten_df
  # Aktualisiere die Karten (bzw. warne, wenn keine neuen da.)
  if (nrow(neue_daten)==0) {
    # teams_warning("Neue Stimmbezirk-Daten, aber keine neuen Ortsdaten?",title=wahl_name)
    cat("Frischer Zeitstempel, aber keine neu ausgezählten Stimmbezirke")
  } 
  
  check = tryCatch(
    { # Die Ergebnistabellen mit allen Stimmen/Top-Kandidaten und Ergebnistabelle.
      aktualisiere_top(kand_tabelle_df,top)
      aktualisiere_tabelle_alle(kand_tabelle_df)
    },
    warning = function(w) {teams_warning(w,title=paste0(wahl_name,": Grafiken A"))},
    error = function(e) {teams_warning(e,title=paste0(wahl_name,": Grafiken A"))}
  )  
  ergebnistabelle_df <<- aktualisiere_ergebnistabelle(stadtteildaten_df)
  # Jetzt erst mal die Teams-Meldung absetzen. 
  meldung_s <- paste0(nrow(neue_daten),
                      " Stimmbezirke neu ausgezählt ",
                      "(insgesamt ",gezaehlt,
                      " von ",stimmbezirke_n,")<br>",
                      "<br><strong>DERZEITIGER STAND: GANZE STADT</strong><br>",
                      # Oberste Zeile der Ergebnistabelle ausgeben
                      ergebnistabelle_df %>% head(1) %>% pull(Wahlbeteiligung),
                      "<br>",
                      ergebnistabelle_df %>% head(1) %>% pull(Ergebnis))
  # Neue Stadtteile? Dann 
  neue_stadtteile <- stadtteildaten_df %>%
    # Ausgezählte Stadtteile ausfiltern
    filter(meldungen_anz == meldungen_max) %>% 
    # ...und schauen, ob da ein neuer dabei ist
    inner_join(neue_daten %>%
                 # Neu gezählte Stimmbezirks-Meldung um Stadtteile ergänzen
                 left_join(stimmbezirke_df, by="nr") %>% 
                 select(name = stadtteil) %>% unique(),
               by="name")
  #                
  if(nrow(neue_stadtteile)>0) {
    for (s in neue_stadtteile %>% pull(nr)) {
      # Isoliere den Stadtteil, dessen Nummer wir gerade anschauen
      stadtteil <- stadtteildaten_df %>% filter(nr == s)
      meldung_s <- paste0(meldung_s,
                          "<br><br><strong>Ausgezählter Stadtteil: ",
                          stadtteil$name,
                          "</strong><br>",
                          ergebnistabelle_df %>% filter(nr == s) %>% pull(Wahlbeteiligung),
                          "<br>",
                          ergebnistabelle_df %>% filter(nr == s) %>% pull(Ergebnis))
    }
    # Stadtteil neu ausgezählt?
  }
  if (!exists("NO_SOCIAL")) {
    meldung_s <- paste0(meldung_s,"<br><br>",
                      generiere_socialmedia())
  }
  teams_meldung(meldung_s,title=wahl_name)
  
  check = tryCatch(
    {
      aktualisiere_karten(ergänzt_df)
      aktualisiere_hochburgen(hochburgen_df)
    },
    warning = function(w) {teams_warning(w,title=paste0(wahl_name,": Grafiken B"))},
    error = function(e) {teams_warning(e,title=paste0(wahl_name,": Grafiken B"))}
  )
}