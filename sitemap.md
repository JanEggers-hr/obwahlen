# Was ist wo? Die Sitemap für das Projekt

## Programme
...liegen im Ordner "R":

* **main.R**: Hauptprogramm, das alle Funktionen aufruft: Lies die Konfigurationsdateien ein. Schaue nach neuen Daten, lade sie herunter, verarbeite sie, gibt sie aus, versendet Teams-Messages, loggt jede Aktion in der Datei "obwahl.log"" mit. Die anderen R-Dateien sind über die "source()"-Funktion eingebunden - als Includes.
* **main_oneshot.R** Version des Hauptprogramms, das nur einmal durchläuft, alles aktualisiert und sich dann verabschiedet
  * **lies_konfiguration.R ** liest die Konfiguration für das Programm (Start der Wahl, Daten über Wahlberechtigte, Datawrapper-IDs) und liest die Index-Dateien ein: Kandidaten, Stadtteile, Wahllokale, Kommunalwahl-Ergebnisse. 
  * **lies_aktuellen_stand.R**: Funktionen, um auf neue Daten zu überprüfen, sie herunterzuladen und zu archivieren. 
  * **aktualisiere_karten.R**: Funktionen, um die Datawrapper-Karten zu aktualisieren. 
  * **messaging.R**: Funktionen, die über Teams Status- und Fehlermeldungen ausgeben. 
* **its_alive.R**: Programm, das über einen CRON-Job alle zwei Minuten aufgerufen wird - und nachschaut, wann das letzte mal etwas in die Logdatei "obwahl.log" geschrieben wurde. Wenn das länger als zwei Minuten her ist, ist das Skript vermutlich stehen geblieben - und das Skript versendet einen Alarm über Teams. 
  
Im Ordner "R" gibt es einen Unterordner "Vorbereitung", der diese Skripte enthält:

* generiere_testdaten.R - erstelle fiktive Daten einer fortschreitenden Auszählung, um die Programme testen zu können. 
* teste-curl-polling.R - Testskript, um veränderte Daten über einen CURL-Aufruf so schnell wie möglich zu erkennen (sekundengenau) 

## Wie das Programm arbeitet

```main.R``` wird einmal aufgerufen und arbeitet dann, bis die Wahl vorbei ist
oder ein Fehler auftritt: 

- Lies zunächst die Konfigurationsdatei ein und hole Index-Dateien (mehr zu denen unten)
- Starte eine Schleife, solange nicht alle Stimmbezirke ausgezählt sind
  - Checke, ob sich der Zeitstempel der Daten verändert hat (```check_timestamp()```)
  - Lies sie ein (```lies_stimmbezirke()```), archiviere sie und rechne sie in die benötigten Tabellen um (```berechne_kand_tabelle, aggregiere_stadtteildaten, berechne_ergänzt, berechne_hochburgen)
  - Gib dann die ersten drei Grafiken aus: die Top-5-Grafik, die Balkengrafik mit allen Kandidierenden und die Tabelle mit den Stadtteil-Ergebnissen
  - Nutze die Stadtteil-Ergebnis-Tabelle, um eine Teams-Meldung mit dem aktuellen Stand und dem Ergebnis evtl. ausgezählter Stadtteile zu versenden
  - Aktualisiere dann die Karten: eine Sieger-Karte und die Choropleth-Karten für alle Kandiderenden.
  - Falls keine aktuellen Daten da sind: touchiere einmal kurz die Datei "obwahl.log" (die ja von der its_alive.R überwacht wird, wenn ein entsprechender Cronjob läuft) und beginne dann von vorn

Es gibt eine Version namens **main_oneshot.R**, die nur einmal durchläuft, ohne auf ein neues Datum zu prüfen. Die ist gut dafür, nachzuaktualisieren. 

## Wo man welche Funktionen findet (und was sie tun)

### messaging.R
- teams_meldung()
- teams_error()
- teams_warnung()

geben über Teams Meldungen aus, z.B. wenn eine neue Auszählung vorliegt.

### lies_aktuellen_stand.R

- archiviere(dir) - Hilfsfunktion, schreibt geholte Stimmbezirks-Daten auf die Festplatte
- hole_letztes_df(dir) - Hilfsfunktion, holt die zuletzt geschriebene Stimmbezirks-Datei aus dem Verzeichnis zurück  (derzeit nicht benötigt)
- vergleiche_stand(alt_df,neu_df) - berechnet Spaltensummen und vergleicht die Daten
- check_for_timestamp(url) - liest das Änderungsdatum der Datei unter der URL aus
- lies_stimmbezirke(url) - liest aus der Datei unter der URL die Stimmbezirke
- aggregiere_stadtteildaten(stimmbezirke_df) - aggregiert auf Ortsteil-Ebene
- berechne_ergänzt(url) - ergänzt die Stadtteildaten mit den Namen der Kandidierenden, Prozentwerten - und Spalten für die führenden n Kandidierenden (diese Tabelle braucht man für die Choropleth- und Sieger-Karten, die im Mouseover-Tooltipp genau diese Informationen darstellen)
- berechne_kand_tabelle() - die Stimmen- und Prozente-Tabelle mit allen Kandidaten, für die Top-Säulen und Alle-Balkengrafik
- berechne_hochburgen() - eine Tabelle mit den jeweils drei stärksten und drei schwächsten Stadtteilen

- hole_wahldaten() - Sammel-Aufruf. Berechnet alle Tabellen und aktualisiert alle Grafiken, und setzt eine Teams-Meldung ab, wenn es ein Update gab

### aktualisiere_karten.R

Hilfsfunktionen:
- generiere_auszählungsbalken() gibt einen HTML-String zurück, der den Fortschrittsbalken enthält: wie viele der Stimmbezirke sind gezählt?
- generiere_auszählung_nurtext() - nur die Ziffern, kein Balken
- font_colour() - eine Hilfsfunktion, die einen RGB-Hex-Farbwert (#12a7bc o.ä.) nimmt und eine Textfarbe zurückgibt, die man darauf lesen kann - weiß oder schwarz. Wird für den Switcher benutzt. 
- aufhellen() - gibt eine aufgehellte Farbe zurück; für die Choropleth-Karten
- link_text() produziert einen HTML-String mit einem Button und dem Link zu einer Karte.

- generiere_switcher() baut aus all dem den HTML-String für die Karten - mit den Buttons mit Links. 
- karten_body_html() generiert den HTML-Code für das Tooltip-Mouseover (mit den kleinen Balkengrafiken für die ersten (top) Kandidierenden im Stadtteil)
- vorbereitung_alle_karten() setzt für (existierende!) Karten die Metadaten: Farbskala für die Choroplethen bzw. Farbwerte für die Sieger-Karte; Switcher-Buttons im Intro-Absatz, Tooltip mit den Balkengrafiken. 

- generiere_socialmedia() exportiert zwei Karten als PNG - wenn der Code auf dem Server läuft, werden sie in ein übers Netz zugängliches Google-Bucket kopiert und der Link auf die PNGs in einen String gepackt, der dann in die Teams-Update-Meldung kommt. 

- aktualisiere_top() - aktualisiere und publiziere die Säulen-Grafik der top (top) Kandidaten
- aktualisiere_tabelle_alle() -  aktualisiere, vermetadate und publiziere die Balkengrafik mit allen Stimmen für alle Kandidaten
- aktualisiere_karten() - Die Sieger- und die Choropleth-Karten aktualisieren und publizieren
- aktualisiere_hochburgen() - Die Tabelle mit den Hochburgen nach Kandidat
- aktualisiere_ergebnistabelle() - Baut und publiziert die vielen kleinen HTML-Strings mit den Ergebnissen für die gesamte Stadt und jeden Stadtteil als Text. Gibt die Tabelle zurück; die wird auch für die Teams-Nachricht genutzt.

  


