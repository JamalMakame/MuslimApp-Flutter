# Animations

Deen animates with Flutter itself and can play Rive files instead wherever a
designer supplies one.

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

Rive files are only shipped if their licence allows it; record each one's
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
