# obwahlen PRE

**DIES IST IM AUGENBLICK NUR EINE NOCH NICHT ANGEPASSTE KOPIE DES REFERENDUMS-CODES** - bitte nicht nutzen und wundern! Anpassung spätestens zur [1. Runde der OB-Wahl in Frankfurt am 5. März 2023](https://frankfurt.de/aktuelle-meldung/meldungen/direktwahl-oberbuergermeisterin-oberbuergermeister-frankfurt/). 

R-Code, um den Auszählungsstand hessischer Bürgermeisterwahlen in Echtzeit abzurufen und mit Datawrapper darzustellen

## Ordnerstruktur

- **R** enthält den Code
- **index** enthält Index-, Konfigurations-, und Template-Dateien
- **daten** wird vom Code beschrieben und enthält den aktuellen Datenstand.

## Daten aufarbeiten

### Ziele

Folgende Grafiken wären denkbar: 
* Balkengrafik Ergebnis nach derzeitigem Auszählungsstand mit "Fortschrittsbalken"
* Choropleth Stadtteil-Sieger
* Choropleth Ergebnis nach Kandidat
* Choropleth Wahlbeteiligung
* Choropleth Briefwahl
* Tabelle nach Stadtteil 
* Tabelle nach Kandidaten (Erste drei? fünf?)

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


## Struktur des Codes

### Hauptroutinen

- **update_all.R** ist das Skript für den CRON-Job. Es pollt nach Daten, ruft die Abruf-, Aggregations- und Auswertungsfunktionen auf und gibt Meldungen aus. 
- **lies_aktuellen_stand.R** enthält Funktionen, die die Daten lesen, aggregieren und archivieren
- **aktualisiere_karten.R** enthält die Funktionen zur Datenausgabe
- **messaging.R** enthält Funktionen, die Teams-Updates und -Fehlermeldungen generieren

### Hilfsfunktionen

- **generiere_testdaten.R** ist ein Skript, das zufällige, aber plausible CSV-Daten auf Stimmbezirks-Ebene zum Testen generiert
