Notizen: Erstellen eines .geojson-Shapefiles in WGS84 aus einem Standard-Shapefile im falschen Koordinatensystem mit QGIS

1. Shapefile in QGIS importieren 

2. GEOJSON im richtigen Koordinatensystem erstellen
Dazu Rechtsklick auf den Layer; Export/Objekte speichern als... Format GeoJSON, KBS (Koordinatensystem): EPSG:4326 - WGS 84, exportieren.

3. Stadtteile generieren
Menü "Vektor", "Geometrieverarbeitungswerkzeuge", "Auflösen" - und dann in der Dialogbox auswählen "Felder auflösen [optional]", und dann die Attribute hinzufügen, nach denen zusammengeführt werden soll. 

Nach den Attributen schauen - die Ortsteilnr. ist ein String, kein Integer! Rechtsklick auf den neuen Layer; Eigenschaften..., dann den "Felder..."-Editor, da oben auf das kleine Abakus-Symbol klicken, Namen für das neue Feld in Ausgabefeldname (z.B. "nr"), dann in Feld Ausdruck eintragen"to_int(Ortsbezirk)" - und OK klicken. Neues Feld wird angelegt. Dann das alte Feld löschen (auswählen, oben Klick auf Löschen-Feld).

- Rechtsklick auf den Layer; Exportieren als GEOJSON - nicht vergessen, das Bezugssystem auf WGS84 umzustellen!
- Rechtsklick auf den Layer; Export als XLSX - ggf. Geo-Attribute abschalten

4. Mittelpunkte der Stadtteile

Menü "Vektor", "Geometrie-Werkzeuge", "Zentroide"

Dann noch Geokoordinaten der Zentroidpunkte: Rechte Seite die Toolbox, dort "Vektortabelle" aufklappen, "X/Y-Felder zu Attributen hinzufügen"

- Rechtsklick auf den neu erzeugten Layer, exportieren als XLSX bzw CSV

5. CSV-/XLSX-Dateien putzen

- Brauchen eine Stadtteil-Datei mit nr,name,lon,lat (erzeugt aus den Zentroiden)
- Brauchen einen Wahlbezirks-Zuordnung


6. Reparatur der Darmstadt-Karte

- Laden (falsche Geometrie - das erst zum Schluss fixen!)
- Vereinfachen: Fläche
- Auflösen
- Löcher löschen

# Nachschlag: Wiesbaden

Hier hatte ich zwei Shapefiles: 
- einen für die Ortsbezirke
- einen für die Stimmbezirke

Das Matching der beiden Layer funktioniert über: 

- Menü Vektor/Datenmanagement/Attribute über Position verknüpfen.

Oben: Ortsbezirke
Unten: Wahlbezirke

Auswahlkriterium: "enthält" bzw. "sind innerhalb"

Wenn wie bei Wiesbaden Fehler in den Shapes sind, crasht das Ganze. Der Versuch zu reparieren (mit der Toolbox-Funktion "Geometrie reparieren") funktionierte nicht; also erst einmal: prüfen, dann matchen nur mit den gültigen, und von Hand die fehlenden ergänzen. 