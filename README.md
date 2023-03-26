# obwahlen

R-Code, um den Auszählungsstand hessischer Bürgermeisterwahlen in Echtzeit abzurufen und mit Datawrapper darzustellen (Frankfurt, Kassel Darmstadt)

## Votemanager und Datawrapper sind Voraussetzung ##
Das Programm arbeitet mit den Daten, die das Programm "Votemanager" bereitstellt; es ist bei allen größeren hessischen Kommunen im Einsatz. Votemanager publiziert das Auszählungsergebnis live, sobald es vorliegt, nach verschiedenen Aggregationsebenen, bis hinunter auf die Ebene des einzelnen Stimmbezirks als "Schnellmeldung".

### Votemanager und die Briefwahlbezirke

Eine Falle, in die ich zunächst gestolpert bin: Neben normalen Stimmbezirken - die mit einem Wahllokal verbunden sind - gibt es die Briefwahlbezirke. Die haben eine Besonderheit: Sie haben rechnerisch 0 Wahlberechtigte - solange sie noch nicht ausgezählt sind, fällt die Berechnung der Wahlbeteiligung in einem Stadtteil immer zu niedrig aus!

### Datawrapper

Wir setzen Datawrapper zur Ausgabe der Grafiken ein, das auch unter Last äußerst stabil läuft und eigentlich immer gut aussieht (corona-erprobt). Um die Grafiken vom Skript aktualisieren zu lassen, muss man in DataWRAPPER einen API-Token generieren und im R-Environment hinterlegen - dazu das Paket ```DatawRappr``` von [Github](https://github.com/munichrocker/DatawRappr) installieren, laden, und ```datawrapper_auth("abcdef")``` aufrufen (statt "abcdef" natürlich das API-Token.)

Die Datawrapper-Darstellungen müssen derzeit noch von Hand angelegt werden - im Fall der Karten mit einem korrekten Shapefile als .geojson. Mehr bei [Datawrapper](https://academy.datawrapper.de/article/145-how-to-upload-your-own-map); wie man mit QGIS aus einem .shp-File ein .geojson mit Zentrierpunkten und Tabellen erstellt, [ist stichpunktartig hier dokumentiert](howto_shapefile.md)

## Ordnerstruktur

- **R** enthält den Code
- **index** enthält die Konfigurationsdatei index.csv und Unterordner mit den Indexdateien: Kandidaten, Stadtteile, Stimmbezirke, Datawrapper-Zuordnungen. 
- **daten** wird vom Code beschrieben und enthält den aktuellen Datenstand.

## Daten aufarbeiten

### Ziele

Grafiken: 
* Säulengrafik erste (top); Ergebnis nach derzeitigem Auszählungsstand mit "Fortschrittsbalken"

* Balkengrafik für alle Kandidierenden
* Symbol-Karte Stadtteil-Sieger und für jeden Kandidierenden eine Choropleth-Karte mit dem Ergebnis nach Stadtteil
* Tabelle nach Kandidaten (3 beste, 3 schlechteste Stadtteile)
* Tabelle alle Ergebnisse nach Stadtteil 

### Aktualisierung via CORS/GBucket

Der normale Weg, eine Datawrapper-Grafik anzuzeigen, ist: pushe die Daten auf den Datawrapper-Server - mit dw_data_to_chart() - und aktualisiere. 

Alternativ kann die Grafik aus live bereitgestellten Daten in einem Google Bucket bestückt werden. Die Adressen der Dateien, die an die Grafiken übergeben werden müssen, sind: 

- https://d.data.gcp.cloud.hr.de/obwahl_top.csv
- https://d.data.gcp.cloud.hr.de/obwahl_kand_tabelle.csv
- https://d.data.gcp.cloud.hr.de/obwahl_ergaenzt.csv
- https://d.data.gcp.cloud.hr.de/obwahl_hochburgen.csv
- https://d.data.gcp.cloud.hr.de/obwahl_stadtteile.csv

### Konfiguration

Das Programm holt sich seine Daten aus einer Konfigurationsdatei - entweder für den Live- oder den Testbetrieb, was über die Variable TEST im Progammcode umgestellt wird. Die Indizes für die jeweile Wahl - Kandidatinnen und Kandidaten, Stadtteile und Wahllokal-Zuordnungen - liegen in einem Unterordner mit dem Namen der Wahl, als CSV oder XLSX. 

- Konfigurationsdatei ```index/config.csv``` - eine CSV-Datei mit den Spalten "name" und "value" für die Konfigurations-Variablen und ihre Werte. 

name | value (Erklärung)
----|----
wahl_name | Name der Wahl, z.B. ob_ffm_2023. Auch Name der Unterordner.
stimmbezirke_url | Die Votemanager-URL, unter der eine CSV-Datei mit den Ergebnissen und dem Meldungsstand nach Stimmbezirk abrufbar ist. (Beim Testen auf eine eigene URL oder einen Dateipfad umbiegen)
wahlberechtigt | Anzahl der vom Wahlamt gemeldeten Wahlberechtigten am Tag der Wahl; derzeit nicht benötigt (wäre für Schätzung der Wahlbeteiligung erforderlich)
briefwahl | Anzahl der vom Wahlamt gemeldeten Briefwahlstimmen insgesamt am Tag der Wahl; derzeit nicht benötigt (wäre für Schätzung der Wahlbeteiligung erforderlich)
kandidaten_fname | Filename der Tabelle mit den Kandidaten
zuordnung_fname | Filename der Tabelle mit den Wahlbezirken und der Zuordnung zu Stadtteilen
stadtteile_fname | Filename einer Liste mit Stadtteilen und Nummer
startdatum | Zeitpunkt, ab dem die Wahlauszählung laufen soll
top | Anzahl der führenden Kandidatinnen, die die erste Säulengrafik und die Anzahl der Ergebnis Balken in den Tooltipps der Karten steuert
top_id | Datawrapper-ID für die Säulengrafik für das derzeitige Ergebnis der führenden (top) Kandidatinnen und Kandidaten
karte_sieger_id | Datawrapper-ID der Symbolkarte mit den Siegern nach Stadtteil
karte_kand1_id | Die Datawrapper-IDs für die Choropleth-Karten der Kandidatinnen; für jede eine Karte - nummeriert nach der Reihenfolge auf dem Wahlzettel (wie in der Indexdatei ```kandidaten.xlsx``` hinterlegt)
...karte_kandn_id |
tabelle_alle_id | Die Datawrapper-ID für die Balkengrafik mit allen Kandidierenden - die technisch eigentlich eine Tabelle ist und deswegen tabelle_alle_id heißt
hochburgen_id | Die Datawrapper-ID für die Tabelle mit den besten und schlechtesten Stadtteilergebnissen nach Kandidat
tabelle_stadtteile_id | Die Datawrapper-ID für die Tabelle mit den Gesamtergebnissen
social1_id | Für Social Media: ID der Top-Säulengrafik
social2_id | Für Social Media: ID einer Kopie der Gesamt-Tabelle/Balkengrafik

- Tabelle kandidaten.xlsx (im Unterordner mit dem Wahlnamen) enthält folgende Spalten: 
Spalte | Wert
---- | ----
Nummer | laufende Nr. des Kandidierenden nach Wahlzettel als ID
Vorname | (und ggf. Doktortitel)
Name | 
Parteikürzel | Kurzform der Partei des Kandidaten (z.B. "PARTEI" statt "Partei für Arbeit, Rechtsstaat, Tierschutz, Elitenförderung und basisdemokratische Initiative"")
Partei | Vollständiger Parteiname (derzeit nicht verwendet)
Farbwert | Die Kampagnenfarbe bzw. die Farbe für die Darstellungen des Kandidierenden als Hex-RGB-String, also z.B. "#B92837"
URL | Verlinkung auf den Hintergrundartikel zum Kandidaten (derzeit nicht verwendet)

- Die Stadtteil-Datei kann man aus QGIS exportieren, wenn man das Shapefile erstellt (CSV oder XLSX):

Spalte | Wert
---- | ----
nr | Laufende Nummer, ID des Stadtteils
name | Name des Stadtteils (dient auch als ID, also auf Tippfehler achten!)
lon | Längengrad des Zentrierpunkts für den Stadtteil
lat | Breitengrad des Zentrierpunkts für den Stadtteil

- Die Stimmbezirks-Datei enthält die Zuordnungen für die Wahlbezirke zu Stadtteilen und wird aus der Open-Data-Beispieldatei des votemanagers erstellt: 

Spalte | Wert
---- | ----
nr | ID des Stimmbezirks
ortsteilnr | ID des Stadtteils
ortsteil | Name des Stadtteils

Nicht benötigte Spalten können in der Tabelle bleiben, sollten aber möglichst nicht "name" oder so heißen. 

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

## Vorbereitung einer Wahl

- Shapefile für die Stadt besorgen; Stimmbezirksebene; Stadtteile
- Stadtteile aggregieren, GEOJSON generieren
- Ordner für die Wahl im Index-Ordner; Datei Kandidaten, Stadtteile (mit Geokoordinaten für die Zentrumspunkte), Stimmbezirke (mit Zuordnung Stadtteil)
- Kopien für die vier Grafiken anlegen: Top, alle Stimmen, Hochburgen, Stadtteile. Link zum Wahlamt nicht vergessen.
- Leerdatei Ergebnisse nach Stadtteil vorbereiten
- Kopie der Sieger-Karte mit GEOJSON anlegen; GEOJSON hochladen, Leerdatei hochladen. Link zum Wahlamt korrigieren. 
- Eine erste Kopie der Choropleth-Karten nach Kandidat: Wahlamt-Link ändern und Karte und Leerdatei hochladen, dann kopieren. 
- Kopien für alle Kandidierenden anlegen. Jeweils die Werte-Spalte des jeweiligen Kandidaten auswählen; benennen, um sie zuordnen zu können. (Farben und Namen werden automatisch nachgetragen.)
- Indexdatei vorbereiten: Wahlname, Anzahl TOP, Dateinahmen der Index-Dateien, Datawrapper-IDs für die Karten und Diagramme

## TODO

- Analyse: Weshalb hängt das Polling manchmal hinterher?
- Aufruf mit Parametern ermöglichen ("main.R obwahl_ffm_2023")
- Oneshot-Variante für Kassel

- Auswertung Briefwahldaten

## Nice-To-Have 

- Zusatzfeature: Briefwahlprognostik - wieviele Stimmen fehlen vermutlich noch?
- Shapefiles KS, DA verbessern
- Vergleich letzte Kommunalwahl regulär