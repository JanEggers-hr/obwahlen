# Was ist wo? Die Sitemap für das Projekt

## Programme
...liegen im Ordner "R":

* **main.R**: Hauptprogramm, das alle Funktionen aufruft: Lies die Konfigurationsdateien ein. Schaue nach neuen Daten, lade sie herunter, verarbeite sie, gibt sie aus, versendet Teams-Messages, loggt jede Aktion in der Datei "obwahl.log"" mit. Die anderen R-Dateien sind über die "source()"-Funktion eingebunden - als Includes, gewissermaßen.
  * **lies_konfiguration.R ** liest die Konfiguration für das Programm (Start der Wahl, Daten über Wahlberechtigte, Datawrapper-IDs) und liest die Index-Dateien ein: Kandidaten, Stadtteile, Wahllokale, Kommunalwahl-Ergebnisse. 
  * **lies_aktuellen_stand.R**: Funktionen, um auf neue Daten zu überprüfen, sie herunterzuladen und zu archivieren. 
  * **aktualisiere_karten.R**: Funktionen, um die Datawrapper-Karten zu aktualisieren. 
  * **messaging.R**: Funktionen, die über Teams Status- und Fehlermeldungen ausgeben. 
* **its_alive.R**: Programm, das über einen CRON-Job alle zwei Minuten aufgerufen wird - und nachschaut, wann das letzte mal etwas in die Logdatei "obwahl.log" geschrieben wurde. Wenn das länger als zwei Minuten her ist, ist das Skript vermutlich stehen geblieben - und das Skript versendet einen Alarm über Teams. 
  
Im Ordner "R" gibt es einen Unterordner "Vorbereitung", der diese Skripte enthält:

* generiere_testdaten.R
* teste-curl-polling.R - Testskript, um veränderte Daten über einen CURL-Aufruf so schnell wie möglich zu erkennen (sekundengenau)
* prepare.R - generiert die Datawrapper-Skripte und -karten und Indexdaten. 

## Wo man welche Funktionen findet (und was sie tun)
### lies_aktuellen_stand.R

- archiviere(dir) - Hilfsfunktion, schreibt geholte Stimmbezirks-Daten auf die Festplatte
- hole_letztes_df(dir) - Hilfsfunktion, holt die zuletzt geschriebene Stimmbezirks-Datei aus dem Verzeichnis zurück  
- check_for_timestamp(url) - liest das Änderungsdatum der Datei unter der URL aus
- lies_stimmbezirke(url) - liest aus der Datei unter der URL die Stimmbezirke
- aggregiere_stadtteildaten(stimmbezirke_df) - aggregiert auf Ortsteil-Ebene
- berechne_führende



### aktualisiere_karten.R
## Wie das Programm arbeitet

```main.R``` wird einmal aufgerufen und arbeitet dann, bis die Wahl vorbei ist
oder ein Fehler auftritt: 

- Lies zunächst die Konfigurationsdatei ein und hole Index-Dateien
- Starte eine Schleife, solange nicht alle Stimmbezirke ausgezählt sind
  - Checke, ob sich der Zeitstempel der Daten verändert hat (```check_timestamp()```)
  - Lies sie ein (```lies_gebiet()```)

