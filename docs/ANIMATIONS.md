# Animations

Deen animates with Flutter itself and plays Rive files in three places. The
three bundled files are Deen's own artwork, generated from code by
`tool/build_rive.py` (no editor or third-party art; same licence as the app).
Change the drawing or timing there and run `python3 tool/build_rive.py`; a
designer's file with the same name can replace any of them.

## Rive slots

`DeenRive(name, fallback: …)` (`lib/app/ui/widgets/motion.dart`) plays
`assets/rive/<name>.riv` when that file is bundled, and the built-in Flutter
animation otherwise. Adding a file needs no code change: put it in
`assets/rive/` with the name below and rebuild.

The file's main artboard should have a state machine called `main` (it
autoplays); without one, the artboard's first animation plays.

| File | Where | What it should do | Size | Built-in fallback |
| --- | --- | --- | --- | --- |
| `splash.riv` | Splash screen emblem, while data loads | Loop: emblem or rosette, calm motion, transparent background, works on the emerald gradient | 208 × 208 | Rotating star rosette and a breathing dome emblem |
| `celebration.riv` | Full screen, over everything, for 4 s: all five prayers marked, daily reading goal met, a tasbeeh round finished | Play once (about 3 s): burst from the top, transparent background; the banner text is drawn by the app | Full screen (cover) | Confetti in gold, emerald and white |
| `empty.riv` | Empty bookmarks, no search results | Loop, gentle; transparent background | 140 × 120 | An icon that pops in |

**Bundled now** (`tool/build_rive.py`):

- `splash.riv` (256 × 256, 4 s loop): an emerald and gold eight-point star
  rosette turning in opposite directions around a crescent with a small star,
  a breathing gold glow and eight orbiting dots that light up in turn.
- `celebration.riv` (360 × 640, 3.5 s, once): a gold star with an emerald
  centre pops and spins away, a gold ring expands, and 44 pieces of confetti
  (strips, dots and stars in the Deen palette) burst out, flutter and fall.
- `empty.riv` (200 × 160, 3 s loop): an open book bobbing under a crescent
  with twinkling four-point sparkles.

The script writes the Rive runtime binary format (v7) directly; the type and
property keys come from the `rive` package's `lib/src/generated/` sources.
The runtime draws the first drawable on top, so the script reverses sibling
shapes when writing. Rive's native code doesn't load in `flutter test`, so
preview a change in a browser with `@rive-app/canvas` or on a device.

A file from anywhere else is only shipped if its licence allows it; record each one's
source and licence in `assets/licenses/` and register it in `lib/main.dart`
`_registerLicences`.

## Built-in motion

- **Page transitions:** fade, 280 ms (`GetMaterialApp.defaultTransition`).
- **Lists:** Home, Habits and the prayer tracker fade and slide their cards
  in one after another (`staggered`, `FadeSlideIn`).
- **Taps:** cards, the nav pill and the tasbeeh dial shrink while pressed
  (`Pressable`); nav and prayer check-offs give a haptic tick.
- **Numbers and progress:** the tasbeeh count pops on every tap; prayer
  check circles bounce; progress rings and bars fill.
- **Milestones:** `celebrate()` / `celebrateIf()`
  (`lib/app/ui/widgets/celebration.dart`) show the banner with confetti (or
  `celebration.riv`) and a haptic.
