# AGENTS.md

Guidance for coding agents working on **System Stats** — a KDE Plasma 6 widget (plasmoid) that
shows CPU, GPU, RAM and network load: compact in the panel, with 10-minute history charts on the
desktop / in the popup. Pure QML, no build step, no dependencies beyond Plasma 6 / Kirigami /
KQuickCharts / `org.kde.ksysguard.sensors` + `.formatter` (ship with Plasma's system monitor).
Single developer. Sister project: `../sabstats-plasmoid` (same conventions).

This is a **German-language project**: comments, commit messages, `README.md` and every
user-facing string are German. Keep it that way. (This file is English only because that is
the common convention for agent instructions.)

This file describes the **current state** only. History is in `git log`.

## Working style

**A question is not a work order.** When the developer asks something, investigate and answer,
then **propose** concrete changes and stop. An explicit instruction ("mach das", "bau X") is
the go-ahead. Before proposing features, check the *Verworfen* table in `ROADMAP.md` — rejected
ideas must not come back.

## Commands

Run everything from the **repo root**.

```bash
qmllint contents/ui/main.qml                          # syntax/lint, must report no errors
kpackagetool6 -t Plasma/Applet -u .                   # update the installed copy (-i for first install)
systemctl --user restart plasma-plasmashell           # Plasma caches QML; needed after every update
journalctl --user --since "-1min" | grep -i sysstats  # runtime QML errors
kstatsviewer --list                                   # available sensor ids
```

There is no test suite and no `plasmoidviewer`. Live geometry of the installed widgets (to
confirm they render) via
`qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '…'`.

## Layout

| Path | Contents |
|---|---|
| `metadata.json` | Plugin id `org.hatzman.sysstats`, icon `utilities-system-monitor`. |
| `contents/ui/main.qml` | Everything: sensors, history, both representations. |

## How `main.qml` works

- **Sensors:** one `Sensors.Sensor` per value, `updateRateLimit: rate` (2 s). `cpu/all/*`,
  `gpu/all/*`, `memory/physical/*`, `network/all/*` so it runs on other machines unchanged;
  only GPU fan/power are fixed to `gpu/gpu0` (`ponytail`). No settings dialog.
- **History:** `Timer` every 2 s → `sample()` appends to `hist` (`cpu, temp, gpu, vram, ram,
  down, up`, last `maxSamples` = 300 = 10 min, RAM only). Lives on the root, so it keeps
  recording while the popup is closed. Always replaced (copy + reassign), never mutated in place.
- **`groups`:** one object per group (CPU, GPU, RAM, NET) with `name` (panel label), `title`,
  `icon`, `pre` (panel prefix like „↓ “), `widest` (realistic longest panel text per value, sets
  the fixed column width), `vals` (two values, optional
  `color`), `series` (`data` + `color` per chart line), `max` (y-axis), `extra` (small text line).
  Both representations are driven by it — add a value there, not in the views. Repeaters use
  `model: groups.length` + `groups[index]` so delegates survive the 2-s updates.
- **Colours:** only the CPU temperature is coloured (`tempColor`: neutral ≥ `tempWarn` 75 °C,
  negative ≥ `tempCrit` 85 °C). High load is deliberately not coloured.
- **Representations:** desktop (`Planar`) shows `fullRepresentation` directly, the panel shows
  `compactRepresentation`. `backgroundHints` includes `ConfigurableBackground`: on the desktop the
  background can be toggled in edit mode (Plasma stores it per widget).
  - Compact: per group a dimmed label and two left-aligned values right behind it; column width
    fixed from `widest` (`FontMetrics.advanceWidth`) so the panel doesn't jump, the slack sits at
    the group's end. `Formatter.maximumLength` was too generous (gap between label and value).
    Tooltip has one line per group.
  - Full: header (popup only, hidden on the desktop), one section per group, separated by `Kirigami.Separator` — no card fill, so popup
    and desktop keep one uniform background (title, values with colour dots of their series in
    their own row, `LineChart` with
    one `ArraySource` per series via `Instantiator`, right-anchored with width ∝ sample count for
    a fixed time axis, extra line). Plasma builds it lazily in the popup — QML errors in it only
    appear in the journal after the popup was opened once (the desktop instance builds it at start).

## Conventions

- 4-space indent, double quotes, arrow functions, German comments only where the *why* isn't obvious.
- Colours only from `Kirigami.Theme`, sizes from `Kirigami.Units` — no hard-coded colours.
- Value formatting via the sensor's `formattedValue` / `Formatter.formatValue` (same output as
  Plasma's own system monitor widgets).
- Deliberate shortcuts are marked `// ponytail: <limit>, <upgrade path>`.

## ROADMAP.md workflow

`ROADMAP.md`: **Offen** (`### N.M Titel`), **Verworfen** (table with reason), **Erledigt**
(one line per feature). Move items there when done or rejected; keep `README.md` and this file
current in the same commit.

## Data & safety

- No secrets in this repo.
- Commit directly to `main` (no PR flow) and push. Once an assigned change is done (lint clean,
  installed, journal clean, `README.md` updated if user-visible), commit and push without asking —
  unless the approach changed fundamentally.
