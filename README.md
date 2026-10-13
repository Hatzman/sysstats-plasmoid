# System Stats – Plasma 6 Widget

Zeigt CPU-, GPU-, Arbeitsspeicher- und Netzwerkauslastung – kompakt in der Kontrollleiste, mit 10-Minuten-Verlauf auf dem Desktop bzw. im Popup. Ersetzt die einzelnen Systemmonitor-Widgets von Plasma durch eines.

| Gruppe | Leiste | Detailansicht zusätzlich |
|---|---|---|
| CPU | Auslastung, Temperatur (gelb ab 75 °C, rot ab 85 °C) | Kerne, Threads |
| GPU | Auslastung, VRAM | Lüfter, Leistung, VRAM gesamt |
| RAM | belegt, belegt % | Gesamt |
| Netz | Download, Upload | Maximum der letzten 10 Minuten |

Die Werte kommen aus denselben Sensoren wie Plasmas Systemmonitor (`ksystemstats`); benötigt KQuickCharts (`kquickcharts`, bei Plasma meist schon installiert).

## Einrichtung

```sh
kpackagetool6 -t Plasma/Applet -i .   # Update: -u statt -i
```

Danach „System Stats“ über *Miniprogramme hinzufügen* in Leiste oder Desktop ziehen. Auf dem Desktop lässt sich der Hintergrund im Bearbeitungsmodus ausblenden. Nach Updates ggf. `systemctl --user restart plasma-plasmashell`.
