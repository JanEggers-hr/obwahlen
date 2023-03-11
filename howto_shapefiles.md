1. Shapefile in QGIS importieren 

2. GEOJSON im richtigen Koordinatensystem erstellen
Dazu Rechtsklick auf den Layer; Koordinatensystem WGS84, exportieren

3. Stadtteile generieren
Menü "Vektor", "Geometrieverarbeitungswerkzeuge", "Auflösen" - und dann in der Dialogbox auswählen "Felder auflösen [optional]", und dann die Attribute hinzufügen, nach denen zusammengeführt werden soll. 

In KS beispielsweise gab es die 


- Rechtsklick auf den Layer; Exportieren als GEOJSON - nicht vergessen, das Bezugssystem auf WGS84 umzustellen!
- Rechtsklick auf den Layer; Export als XLSX - ggf. Geo-Attribute abschalten

4. Mittelpunkte der Stadtteile

Menü "Vektor", "Geometrie-Werkzeuge", "Zentroide"

Dann noch Geokoordinaten der Zentroidpunkte: Rechte Seite die Toolbox, dort "Vektortabelle" aufklappen, "X/Y-Felder zu Attributen hinzufügen"

- Rechtsklick auf den neu erzeugten Layer, exportieren als XLSX bzw CSV

5. CSV-/XLSX-Dateien putzen

- Brauchen eine Stadtteil-Datei mit nr,name,lon,lat (erzeugt aus den Zentroiden)
- Brauchen einen Wahlbezirks-Zuordnung
