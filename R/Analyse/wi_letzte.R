library(pacman)
p_load(openxlsx)
p_load(tidyverse)


# Aktuelles Verzeichnis als workdir
setwd(this.path::this.dir())
# Aus dem R-Verzeichnis eine Ebene rauf
setwd("../..")

# Alte Wahlergebnisse laden
ergebnis2019_df <- read.xlsx("rohdaten/wi/election-results_diff.xlsx") %>% 
  select(ortsbezirk=District, c(2:8)) %>% 
  pivot_longer(2:8, names_to="partei", values_to="stimmen2019") %>% 
  mutate(partei=str_replace_all(partei,"\\."," ")) %>% 
  mutate(partei=str_replace(partei," Prozent","")) %>% 
  mutate(ortsbezirk = str_replace(ortsbezirk,"Westend", "Westend, Bleichstraße"))

sqr <- function(x) {
  return(x*x)
}



diff2019_df <- ergebnis2019_df %>% 
  filter(District != "Gesamt (Wiesbaden)") %>% 
  select(10:17) %>% 
  mutate(abw=sqrt(sum(across(1:8, sqr))))

ergebnis_df <- read.xlsx("rohdaten/wi/ergebnis_wahlbezirke.xlsx")

kand_df <- read.xlsx("index/obwahl_wi/kandidaten.xlsx")
wahlbezirke_df <- read.xlsx("index/obwahl_wi/wahlbezirke.xlsx") 
ortsteile_df <- wahlbezirke_df  %>% 
  select(ortsteilnr, ortsteil) %>% 
  distinct()

to_ortsteil <- function(x) {
  # Die Ortsteil-Nr. ist entweder: 
  # - bei Wahlbezirken: die Nr. des Stimmbezirks / 100 
  # - bei Briefwahlbezirken: die Nr. des Wahlbezirks ohne 99 durch 10
  tmp <- ifelse(x >99000, (x %% 1000) %/% 10, x %/% 100)
  # Ortsteile 3,4,5 sind alle 3 Südost
  if (tmp %in% c(3,4,5)) { tmp <- 3}
  # Ortsteile 14, 15 sind alle 14 Biebrich
  if (tmp %in% c(14,15)) { tmp <- 14}
  if (!tmp %in% wahlbezirke_df$ortsteilnr) {
    stop("Ungültiger Ortsteil: ",x)
  }
  return(tmp)
}

# Volatilität der Ergebnisse
volatility <- function(p_v) {
  v <- sum(abs(p_v),na.rm=T) / 2 
  return(v)
} 

ort_df <- ergebnis_df %>% 
  pivot_longer(16:25,names_to="Nummer", values_to="stimmen") %>%
  mutate(Nummer = as.integer(str_extract(Nummer,"[0-9]+"))) %>% 
  left_join(kand_df, by="Nummer") %>% 
  rowwise() %>% 
  mutate(ortsteilnr = to_ortsteil(`gebiet-nr`)) %>% 
  ungroup() %>% 
  select(ortsteilnr,partei=Parteikürzel,stimmen) %>% 
  filter(!is.na(stimmen)) %>% 
  # left_join(ergebnis2019_df, by=c("ortsteilnr","partei")) %>% 
  group_by(ortsteilnr, partei) %>%
  summarize(stimmen = sum(stimmen)) %>%
  ungroup() %>% 
  group_by(ortsteilnr) %>% 
  mutate(prozent = stimmen/sum(stimmen)*100) %>% 
  left_join(ortsteile_df,by="ortsteilnr") %>% 
  left_join (ergebnis2019_df %>% rename(ortsteil = ortsbezirk), by=c("ortsteil","partei")) %>% 
  mutate(prozent2019 = if_else(is.na(stimmen2019),0,stimmen2019)) %>% 
  select(-stimmen2019) %>% 
  mutate(diff = prozent-prozent2019)

vol_df <- ort_df %>% 
  group_by(ortsteilnr, ortsteil) %>% 
  summarize(vol = volatility(diff)) 

ort_str_df <- ort_df %>% 
  group_by(ortsteil) %>% 
  arrange(desc(prozent)) %>% 
  mutate(prozent = round(prozent,digits=1),
         diff = round(diff,digits=1)) %>% 
  summarize(parteien_str = paste0(partei,": ",
                                  format(prozent, decimal.mark=",", nsmall = 1, ),"% (",
                                  ifelse(diff>0,"+",""),
                                  format(diff, decimal.mark=",", nsmall = 1),
                                  ")",collapse="<br>"))

vol2_df <- vol_df %>% 
  left_join(ort_str_df, by="ortsteil")
  

write.xlsx(vol2_df,"daten/obwahl_wi/volatilität.xlsx")
write.xlsx(ort_df,"daten/obwahl_wi/ortsteile.xlsx")  


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


# Briefwahl

wahllokale_df <- ergebnis_df %>% 
  filter(`gebiet-nr` < 99000) %>% 
  pivot_longer(16:25,names_to="Nummer", values_to="stimmen") %>%
  mutate(Nummer = as.integer(str_extract(Nummer,"[0-9]+"))) %>% 
  left_join(kand_df, by="Nummer") %>% 
  rowwise() %>% 
  mutate(ortsteilnr = to_ortsteil(`gebiet-nr`)) %>% 
  ungroup() %>% 
  select(ortsteilnr,partei=Parteikürzel,stimmen) %>% 
  filter(!is.na(stimmen)) %>% 
  # left_join(ergebnis2019_df, by=c("ortsteilnr","partei")) %>% 
  group_by(partei) %>%
  summarize(stimmen = sum(stimmen)) %>%
  ungroup() %>% 
  mutate(prozent = stimmen/sum(stimmen)*100) %>% 
  arrange(desc(prozent))

briefwahl_df <- ergebnis_df %>% 
  filter(`gebiet-nr` > 99000) %>% 
  pivot_longer(16:25,names_to="Nummer", values_to="stimmen") %>%
  mutate(Nummer = as.integer(str_extract(Nummer,"[0-9]+"))) %>% 
  left_join(kand_df, by="Nummer") %>% 
  rowwise() %>% 
  mutate(ortsteilnr = to_ortsteil(`gebiet-nr`)) %>% 
  ungroup() %>% 
  select(ortsteilnr,partei=Parteikürzel,stimmen) %>% 
  filter(!is.na(stimmen)) %>% 
  # left_join(ergebnis2019_df, by=c("ortsteilnr","partei")) %>% 
  group_by(partei) %>%
  summarize(stimmen = sum(stimmen)) %>%
  ungroup() %>% 
  mutate(prozent = stimmen/sum(stimmen)*100) %>% 
  arrange(desc(prozent))

vergleich_df <- wahllokale_df %>% 
  left_join(briefwahl_df %>% select(partei, stimmen_b=stimmen, prozent_b = prozent),by="partei") %>% 
  mutate(verhältnis = stimmen / stimmen_b,
         diff = prozent_b- prozent) %>% 
  # select(-stimmen, -stimmen_b) %>% 
  left_join(kand_df %>% select(partei=Parteikürzel, Name),by="partei") %>% 
  mutate(kandidat = paste0 (Name," (",partei,")")) %>% 
  select(-partei, -Name)

write.xlsx(vergleich_df, "daten/obwahl_wi/vergleich_briefwahl.xlsx")
