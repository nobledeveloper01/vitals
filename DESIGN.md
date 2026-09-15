# Vitals — design system

**The floor:** a 10" clinic tablet with 3 GB of RAM, three years old, propped on a desk
under one window; and a patient's 5" 720p phone with 2 GB, in a pocket on a bus. Both
in Nigerian daylight. Every rule below is drawn for 2027 and has a floor for 2022.

## Principles

1. **The record is the surface.** Clinical data sits on the page; everything else —
   chrome, controls, navigation — floats above it as glass, so what matters is never
   under what merely operates.
2. **Depth is information.** Glass has three depths and each means one thing: the
   page's record, a card of facts, a control that acts. Nothing is elevated for looks.
3. **Colour is reserved.** The gradient is the brand and the only decoration. Meaning
   colours — attention, danger, done — appear only on the thing they mean, never on a
   region.
4. **Motion explains.** Every animation shows a cause: a fact arriving, a card opening
   from the row it came from, a transfer progressing. Nothing animates to be noticed.
5. **Complete without glass.** A device that cannot blur gets solid surfaces and the same
   app. A user who asked for less motion gets none, including the splash.
6. **Honest about what is known.** A trend is drawn; it is never interpreted. Sync says
   when another device was last met, never "synced".

## Colour

Built around the two states clinical work communicates: *attention* and *fine*. The
brand is a single gradient — deep teal into violet — and the meaning colours are set
against it, not drawn from it.

### The mesh

The page is a **gradient mesh**: three soft radial washes over a base, slow to the eye,
fixed in place. Glass panels blur it.

| Stop | Light | Dark |
|---|---|---|
| base | `#F4F7FA` | `#0A0F16` |
| wash A (top-left) | `#D7EFF2` teal | `#0F3A44` teal |
| wash B (right) | `#E6E0F7` violet | `#2B1E5A` violet |
| wash C (bottom) | `#F9EBE3` coral, faint | `#3A1F2E` coral, faint |

The washes are drawn once into a raster and cached; nothing about them moves.

### Glass

| Depth | Fill (light / dark) | Blur | Border | What it is |
|---|---|---|---|---|
| `glassLow` | `#FFFFFF` 55% / `#FFFFFF` 6% | 18 | 1 px `#FFFFFF` 60% / 10% | A card of facts on the page |
| `glassMid` | `#FFFFFF` 70% / `#FFFFFF` 10% | 24 | 1 px `#FFFFFF` 75% / 14% | A control, a sheet, the navigation |
| `glassHigh` | `#FFFFFF` 85% / `#FFFFFF` 16% | 30 | 1 px `#FFFFFF` 90% / 20% | A dialog, the lock screen |

**Solid floor.** When `Motion.glass` is off — by device class, by battery, or by the
user — each depth is drawn as its solid twin with no blur:

| Depth | Solid light | Solid dark |
|---|---|---|
| `glassLow` | `#FFFFFF` | `#131A24` |
| `glassMid` | `#F8FAFC` | `#1B2431` |
| `glassHigh` | `#FFFFFF` | `#24303F` |

Text is drawn on glass **over the mesh's darkest wash**, and the contrast test in CI
measures every text colour against every fill composited on every wash — light and
dark, glass and solid. 7:1 for clinical values, 4.5:1 for everything else.

### Roles

| Role | Light | Dark | |
|---|---|---|---|
| `textPrimary` | `#0B1220` | `#F2F6FA` | |
| `textSecondary` | `#4A5568` | `#B4BFCC` | |
| `textOnAccent` | `#FFFFFF` | `#07111A` | |
| `accent` | `#0F6E7A` | `#5FD3DF` | Teal; the primary action |
| `accentEnd` | `#5B3FA8` | `#B39CFF` | Violet; the gradient's far end |
| `attention` | `#9A5B00` | `#F5B54A` | A reading outside its reference range |
| `danger` | `#B3261E` | `#FF8A80` | A danger sign the nurse must answer |
| `fine` | `#1C7A3C` | `#7BE0A0` | Recorded, in range, done |
| `hairline` | `#C8D2DE` | `#2E3A48` | Where a step in depth is too subtle to read |

**The brand gradient** runs `accent → accentEnd` at 135°. It is used on the mark, the
splash, the primary button, and the progress of a transfer. Nowhere else.

**Colour never carries meaning alone.** Attention has a triangle, danger a filled
octagon, fine a tick, and a word beside each.

## Typography

**Inter** for the interface, `tabular-nums` on every number. Clinical values are set
in **JetBrains Mono** so a 9 and a 0 are never confused at arm's length.

| Style | Size | Weight | Use |
|---|---|---|---|
| display | 28 | 700 | The patient's name at the top of the record |
| headline | 22 | 600 | Section heads; the answer on a verification |
| value | 24 mono | 500 | A reading — BP, weight, temperature |
| title | 17 | 600 | Card titles, row titles |
| body | 16 | 400 | Everything read |
| secondary | 14 | 400 | Dates, attribution, hints |
| small | 13 | 500 | Chips, units |

Every style scales with the platform's text size up to 200% and is checked at 200% in
CI. Nothing truncates; a value that will not fit wraps its label, never its digits.

## Layout

- **Targets:** 48 dp minimum; 56 dp for anything a nurse taps between patients; 64 dp
  for the two that end a workflow — *Record* and *Send*.
- **Tablet:** three panes — the due list, the patient, the encounter. **Phone:** one pane,
  with the same widgets stacked.
- **Radius:** 20 on cards, 28 on sheets, 14 on chips, 12 on inputs.
- **Spacing:** 4, 8, 12, 16, 24, 32, 48.
- **One primary action per screen, pinned.** It is the accent gradient, 64 dp, and the
  only gradient-filled control on the screen.

## Motion

| Token | Duration | Curve | Use |
|---|---|---|---|
| `quick` | 120 ms | ease-out | Press, chip toggle |
| `move` | 240 ms | spring (damping 0.85) | A card opening from its row; a sheet rising |
| `arrive` | 320 ms | ease-out | A fact appearing in a list; a reading joining a trend |
| `sweep` | 900 ms | ease-in-out | The splash's gradient sweep, once |

- Shared-element transitions from a row to its record, on both platforms.
- The trend line **draws** when it appears; it does not fade in.
- A transfer's progress is a ring in the brand gradient, and the ring completes before
  the tick appears.
- **Reduce Motion:** every duration becomes zero, the splash cuts, and the ring becomes
  a count. The trend is drawn complete. `Motion.reduced` is read at act time, so
  toggling it in Settings takes effect without a relaunch.
- **Glass off:** blur is skipped and the solid twin is drawn. `Motion.glass` defaults
  on for devices with ≥ 4 GB and a GPU tier the platform reports as high, off below,
  and the user can override either way in Settings.

## The mark

A rounded square in the brand gradient with a single **pulse line** — one beat, drawn
in white, ending in a dot. The dot is the reading; the line is the trend it sits on.
Drawn by `scripts/brandmark.py` at every size the platforms want, and the splash is
the mark on the mesh with the gradient sweeping through it once.

## What every screen must have

- The page mesh, then glass (or solid) in the right depth for what it holds
- One primary action, pinned, 64 dp, gradient
- Light and dark authored together; contrast asserted on every wash in CI
- The attribution chip on anything written: who, when, on which device
- A forward path from every error and every empty state
- Reduce Motion and glass-off honoured without a relaunch

## What no screen may have

- A diagnosis, a risk, a triage colour, a recommendation, a dose
- Meaning colour on a region — only on the thing it means
- A second gradient-filled control
- Blur as decoration, or on the record itself
- Text under 13 sp, or a value that truncates
- "Synced", "verified", "safe", "genuine" — `make copy-check` reads every string
