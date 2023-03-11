# obwahlen PRE

R-Code, um den Auszählungsstand hessischer Bürgermeisterwahlen in Echtzeit abzurufen und mit Datawrapper darzustellen

## Ordnerstruktur

- **R** enthält den Code
- **index** enthält die Konfigurationsdatei index.csv und Unterordner mit den Indexdateien: Kandidaten, Stadtteile, Stimmbezirke, Datawrapper-Zuordnungen. 
- **daten** wird vom Code beschrieben und enthält den aktuellen Datenstand.

## Daten aufarbeiten

### Ziele

Grafiken: 
* Säulengrafik erste fünf; Ergebnis nach derzeitigem Auszählungsstand mit "Fortschrittsbalken"

* Balkengrafik alle
* Choropleth Stadtteil-Sieger (mit Switcher alle, die gewonnen haben)
* Choropleth Ergebnis nach Kandidat
* Tabelle nach Kandidaten (3 beste, 3 schlechteste Stadtteile)
* Tabelle nach Stadtteil 

### Konfiguration

- Konfigurationsdatei ```index/config.csv``` mit Link, Starttermin, Datawrapper-Zielen; Anzahl der eingegangenen Briefwahlstimmen
- ```index/index.rda``` mit Tabellen Zuordnung Stimmbezirk->Wahllokal und Stadtteilen

### Aufarbeitung

- Daten nach Stimmbezirk abfragen
- Zuordnung Stimmen zu Kandidaten, Umrechnung Prozente gültige Stimmen
Aggregation auf Stadtteilebene
- Zuordnung Stimmbezirk->Stadtteil
- Prozentanteile je Kandidat, Wahlbeteiligung
Aggregation auf Stadtebene
- Prozentanteile je Kandidat, Gewinner
- Fortschrittsbalken ausgezählte Wahllokale
- Fortschrittsbalken ausgezählte Stimmen (mit akt. Briefwahlstimmendaten)


## Struktur des Codes: Was tut was?

(siehe ["Sitemap"](./sitemap.md) für den Code)


# TODO


- Upload aufs Repository

## NTH

- Umschalten Top5-Titel Ergebnis
- Zusatzfeature: Briefwahlprognostik - wieviele Stimmen fehlen vermutlich noch?
- Shapefiles KS, DA verbessern
- Datensparsamere Alternativ-CURL-Poll-Datei (zB mit dem Gesamtergebnis)
- Mehr Licht in den Choropleth-Karten farbabhängig
