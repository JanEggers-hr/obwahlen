# Auswertung nach Stadtteilen vs. Kommunalwahlergebnis 2021


# Parteienliste 
parteien_df <- read.xlsx("index/obwahl_da_2023/parteien-kommunalwahl.xlsx")

# Kommunaldaten: Stadtverordnetenwahl
kommunal_url <- "https://votemanager-da.ekom21cdn.de/2021-03-14/06411000/praesentation/Open-Data-06411000-Stadtverordnetenwahl-Wahlbezirk.csv?ts=1679256774922"
k_stimm_df <- lies_stimmbezirke(kommunal_url) %>% 
  # Die Spalten D1-D14 enthalten die Gesamtergebnisse der Parteien. 
  # Unzählige weitere Spalten enthalten die Ergebnisse für jeden Kandidaten
  # auf den sehr, sehr langen Wahllisten. 
  select(zeitstempel,
         nr,
         name,
         meldungen_anz,
         meldungen_max,
         wahlberechtigt,
         waehler_regulaer,
         waehler_wahlschein,
         waehler_nv,
         stimmen,
         stimmen_wahlschein,
         ungueltig,
         gueltig,
         matches("D[0-9]+$")) %>% 
  mutate(nr = as.integer(str_extract(nr,"[0-9]+")))


k_stadtteile_df <- k_stimm_df %>% 
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
if (nrow(stadtteildaten_df) != nrow(stadtteile_df)) teams_warnung("Nicht alle Stadtteile zugeordnet")
if (nrow(stimmbezirke_df) != length(unique(stimmbezirke_df$nr))) teams_warnung("Nicht alle Stimmbezirke zugeordnet")

  tmp_long_df <- k_stadtteile_df %>%
    pivot_longer(cols = starts_with("D"), names_to = "partei_nr", values_to = "partei_stimmen") %>% 
    mutate(partei_nr = as.integer(str_extract(partei_nr,"[0-9]+"))) %>% 
    # Ortsteil- bzw. Stimmbezirks-Gruppen, um dort nach Stimmen zu sortieren
    group_by(nr,name) %>% 
    arrange(desc(partei_stimmen)) %>% 
    mutate(Platz = row_number()) %>%
    left_join(parteien_df %>% select(partei_nr = Nummer, 
                                       partei = Parteikürzel,
                                       farbe= Farbwert), by="partei_nr") %>% 
    mutate(prozent = if_else(gueltig != 0,partei_stimmen / gueltig * 100, 0)) 
  k_ergänzt_df <- tmp_long_df %>% 
    # Ist noch nach Stadtteil (name, nr) sortiert
    arrange(partei_nr) %>% 
    # Alles weg, was verhindert, was individuell auf den Kand ist - außer
    #  kand und Prozentwert
    select(-partei_stimmen, -partei_nr, -Platz, -farbe) %>% 
    # Kandidatennamen in die Spalten zurückverteilen
    pivot_wider(names_from = partei, values_from = prozent) %>% 
    ungroup() %>% 
    # und die zweite Hälfte dazu: 
    left_join(
      tst <- tmp_long_df %>% 
        # Brauchen nur die Kand-Ergebnisse - und den (Stadtteil-)name
        select(name, Platz, partei,prozent,farbe) %>% 
        # Nur die ersten (top) Plätze
        filter(Platz <= (3)) %>% 
        #The Big Pivot: Breite die ersten (3) aus. 
        pivot_wider(names_from = Platz,
                    values_from = c(partei,prozent,farbe),
                    names_glue = "{.value}{Platz}") %>% 
        ungroup() %>% 
        select(-nr),   
      by="name") %>% 
    # Jetzt auswählen und umbenennen
    select(nr, # ortsteilnr
           k_wahlberechtigt = wahlberechtigt,
           k_stimmen = stimmen, 
           k_stimmen_wahlschein = stimmen_wahlschein,
           k_gueltig = gueltig, 
           ungueltig:partei3) %>% 
    rename(k_ungueltig = ungueltig)

ergänzt3_df <- berechne_ergänzt(stadtteildaten_df,3)  

vergleichstabelle_df <- ergänzt3_df %>% 
  left_join(k_ergänzt_df,by="nr") %>% 
  select(-zeitstempel,
         -ortsteilnr,
         -meldungen_anz,
         -meldungen_max,
         -waehler_regulaer,
         -waehler_wahlschein,
         -waehler_nv) 
  # Gesamt-Ergebnisse ergänzen

write.xlsx(vergleichstabelle_df,"daten/obwahl_da_2023/vergleichstabelle2021.xlsx", overwrite=T)


# Briefwahlergebnis
urnenwahl_df <- stimmbezirksdaten_df %>% 
  # Achtung: Prüfen, ob die Benennung der Briefwahllokale hierzu passt.
  filter(nr < 9999) %>% 
  summarize(gueltig = sum(gueltig),
            across(starts_with("D"),~ sum(.))) %>% 
  pivot_longer(cols = starts_with("D"), names_to = "kand_nr", 
               values_to = "kand_stimmen") %>% 
  mutate(kand_nr = as.integer(str_extract(kand_nr,"[0-9]+"))) %>% 
  left_join(kandidaten_df %>% select(kand_nr=Nummer,
                                     Parteikürzel,
                                     kand_name=Name),by="kand_nr") %>% 
  mutate(`Kandidat/in` = paste0(kand_name," (",Parteikürzel,")")) %>% 
  mutate(Prozent = kand_stimmen / gueltig *100) %>% 
  select(`Kandidat/in`, Urnenwahl = Prozent)

briefwahl_df <- stimmbezirksdaten_df %>% 
  filter(nr > 9999) %>% 
  summarize(gueltig = sum(gueltig),
                  across(starts_with("D"),~ sum(.))) %>% 
  pivot_longer(cols = starts_with("D"), names_to = "kand_nr", 
               values_to = "kand_stimmen") %>% 
  mutate(kand_nr = as.integer(str_extract(kand_nr,"[0-9]+"))) %>% 
  left_join(kandidaten_df %>% select(kand_nr=Nummer,
                                     Parteikürzel,
                                     kand_name=Name),by="kand_nr") %>% 
  mutate(`Kandidat/in` = paste0(kand_name," (",Parteikürzel,")")) %>% 
  mutate(Prozent = kand_stimmen / gueltig *100) %>% 
  select(`Kandidat/in`, Briefwahl = Prozent) %>% 
  left_join(urnenwahl_df,by = "Kandidat/in")



write.xlsx(briefwahl_df,"daten/briefwahl_ergebnis.xlsx", overwrite = T)  

            