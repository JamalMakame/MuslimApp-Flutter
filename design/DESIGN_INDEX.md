# Design Index — Screens

Stitch project `8790583281255569810` · Design system `assets/14074008453126267617`
("Muslim App Emerald & Gold"). Approved app title: **Deen**.

Design language spec: [`DESIGN.md`](DESIGN.md)
Artifacts: `screens/NN-<name>.png` (mockup render) + `.html` (full source
with Tailwind tokens — use for exact spacing/colors in Flutter).

| # | Screen | PNG / HTML | Stitch screen ID | Intended Flutter route |
|---|--------|------------|------------------|------------------------|
| 01 | Splash | `01-splash` | `7d5941e975ed4bb0817a49e3c8f894f2` | `/splash` |
| 02 | Welcome & Onboarding | `02-onboarding` | `5a8e7ffd466f4690ad5b976e4bc057ec` | `/onboarding` (first-run only) |
| 03 | Salah Times — Home | `03-home` | `1f1affe681b940cfbfba93a9042d905f` | `/home` (tab 0) |
| 04 | Quran Index | `04-quran-index` | `bf6d8b00220a4025b1d736741d03cb7d` | `/quran` (tab 1) |
| 05 | Quran Reader (Al-Fatihah) | `05-reader` | `2712376381374ab7b117aac487e9e7a5` | `/reader/:surah` |
| 06 | Tafsir bottom sheet | `06-tafsir` | — (state of reader) | Bottom sheet over `/reader/:surah` |
| 07 | Azkar categories | `07-azkar` | — | `/azkar` (tab 2) |
| 08 | Azkar detail / counter | `08-azkar-detail` | — | `/azkar-detail/:bucket` |
| 09 | Tasbeeh counter | `09-tasbeeh` | — | `/tasbeeh` (from Azkar tab / instant-dhikr card) |
| 10 | Qibla compass | `10-qibla` | — | `/qibla` (from Home) |
| 11 | Settings | `11-settings` | — | `/settings` (nav pill) |
| 12 | Hijri Calendar | `12-calendar` | `1843bccb37cb4ab3a68e34bd6a245c58` | `/calendar` (from Home Hijri date) |
| 13 | Memorize / Audio (Hifz) | `13-memorize` | `11dc40b25ea241f696d993b7b364a544` | `/memorize/:surah` (from Reader) |

On iOS, `LaunchScreen.storyboard` shows a static emerald Deen mark before
Flutter can render `/splash`. Regenerate the matching native and Flutter dome
artwork with `swift ios/generate_splash.swift`.
Launcher icon artwork and native export instructions: [`APP_ICON.md`](APP_ICON.md).

## Navigation model

The approved floating pill has four slots: **Home · Quran · Azkar · Settings**.
On smaller screens it shows icons with accessible tooltips.

Qibla is a pushed route from Home (no nav pill state of its own — mockup
shows Home active). Tafsir is a modal sheet, not a route.

## Key components to extract as shared widgets

- `PrayerHeroCard` — emerald gradient, gold frame, countdown pill (03)
- `PrayerTimeTile` — white card, gold-tint active state (03)
- `SurahTile` — gold-ring number circle, Makki/Madani chip (04)
- `MushafCanvas` — white card, gold inner frame, basmala cartouche, ayah medallions (05)
- `AudioPlayerBar` — scrubber + reciter + speed chip (05)
- `TafsirSheet` — 20px radius, grab handle, dimmed scrim (06)
- `CategoryCard` — gold icon badge + count (07)
- `DhikrCard` — stacked supplication card w/ counter CTA, completed state (08)
- `TasbeehDial` — SVG-style rings, big numeral, tap surface (09)
- `CompassDial` — degree ticks, Kaaba marker, emerald needle (10)
- `SettingsGroup` / `SettingsRow` — grouped card rows, switches, chevrons (11)
- `FloatingNavPill` — shared bottom nav (03–05, 07–11)

## Design data used in mockups

Location Zanzibar, Tanzania · Sat 31 Oct 2026 · 9 Jumada al-Ula 1448 ·
Fajr 05:12 / Sunrise 06:24 / Dhuhr 12:09 / Asr 15:27 / Maghrib 18:24 /
Isha 19:38 · Qibla 256° WSW · 3,412 km to Makkah.

## Localization note

Mockups are English LTR. Arabic text blocks already render `dir="rtl"`
inside cards — in Flutter, Arabic/Quran text widgets must force RTL
locally while app-level direction follows the selected locale
(ar → RTL, en/sw → LTR).
