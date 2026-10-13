# Roadmap

## Offen

### 1.1 CPU-Kerne einzeln
Auslastung je Kern als Mini-Balken in der CPU-Karte.

### 1.2 Netzwerk je Schnittstelle
Download/Upload getrennt nach Interface statt nur `network/all`.

### 1.3 Swap
Belegter Auslagerungsspeicher in der RAM-Karte.

## Verworfen

| Nr. | Idee | Grund |
|---|---|---|
| 2.1 | Einstellungsdialog für Sensoren | Viel Code für selten geänderte Werte; `all`-Sensoren laufen ohne Anpassung |
| 2.2 | Farbe bei hoher Auslastung | 100 % beim Kompilieren sind gewollt, ständige Warnfarben stumpfen ab; nur die Temperatur wird gefärbt |
| 2.3 | Verlauf länger als 10 Minuten | Zeigt kaum Mehrwert für die Momentaufnahme, mehr Punkte je Diagramm |

## Erledigt

- Leiste: CPU (Auslastung, Temperatur), GPU (Auslastung, VRAM), RAM (belegt, %), Netz (↓, ↑) mit Kennung und fester Breite
- Tooltip mit einer Zeile je Gruppe
- Detailansicht mit einer Karte je Gruppe, 10-Minuten-Verlauf und Zusatzwerten (Kerne/Threads, Lüfter, Leistung, Gesamtspeicher)
- Desktop zeigt direkt die große Ansicht
- CPU-Temperatur gelb ab 75 °C, rot ab 85 °C
