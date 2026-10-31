# Design System: Muslim App — Phase 1 Redesign

A premium Islamic companion app. Mobile-first, 393 × 852 canvas, English LTR
mockups (Arabic RTL adaptation happens at Flutter build time — layout must be
direction-agnostic).

## 1. Visual Theme & Atmosphere

Quiet reverence. The app should feel like a beautifully bound mushaf — deep
emerald like mosque carpet and Ottoman tile, gold like illuminated
manuscript borders, ivory like fine paper. Calm, unhurried, respectful.
Density moderate (6/10) — content breathes; nothing cramped. Motion gentle
(3/10) — soft fades and slides only. No gimmicks: this is an app people open
five times a day at sacred moments.

One hero moment per screen maximum. The prayer-time hero card is the visual
centerpiece of Home — it may carry a subtle emerald→deep-emerald gradient
with a gold hairline frame; everywhere else is flat surfaces + hairlines.

## 2. Color Palette & Roles

- **Deep Emerald** `#0E6B5C` — primary: nav active state, primary buttons,
  hero card base, key numerals.
- **Emerald Depth** `#0A4A3F` — hero card gradient tail, pressed states,
  dark surface variant.
- **Manuscript Gold** `#C9A24B` — THE accent: icons, badges, countdown ring,
  dividers on dark, star/motif ornaments. Use sparingly — gold is jewelry,
  not paint.
- **Ivory Canvas** `#F8F6F1` — app background. Never pure white screens.
- **Pure Surface** `#FFFFFF` — cards, sheets, inputs.
- **Ink** `#12211D` — primary text. Never pure black.
- **Sage Muted** `#5F7169` — secondary text, captions, metadata.
- **Hairline** `#E4E0D5` — 1px borders/dividers on light surfaces.
- **Gold Tint** `#F4EBD7` — selected states, soft highlight fills.
- **Status set:** Emerald `#0E6B5C` on `#E4F2EC` (active/current prayer),
  Amber `#8A6B1F` on `#F7EFD9` (upcoming/warning), Clay `#A34D3C` on
  `#F9E8E4` (error/blocked).

Dark-mode tokens are defined for the Flutter build (Phase 4) but all Stitch
mockups render LIGHT.

## 3. Typography

- **Headline font:** PLUS JAKARTA SANS — screen titles, prayer names, hero
  numerals. Titles 22/700, sections 16/600.
- **Body font:** MANROPE — UI text, 14px base, captions 12px.
- **Numerals:** tabular, prominent — prayer times 15/600; the hero countdown
  is 34/700 in Emerald on light or Ivory on the emerald card.
- **Micro-labels:** 11px/600, uppercase, 0.08em tracking, Sage Muted —
  section eyebrows like "NEXT PRAYER", "DAILY INSPIRATION".
- Build-time pairing (documented, not renderable in Stitch): Cairo/Almarai
  for Arabic UI, an Uthmanic mushaf face for Quran pages.

## 4. Components

- **APP SHELL:** content screens get a clean top area (screen title +
  context, no heavy app bars) and a **floating pill bottom nav** — 3 items
  (Home / Quran / Azkar), floating 16px above bottom edge, full-radius
  (999px), white surface with soft shadow, active item = Emerald fill pill
  with white icon+label, inactive = Sage icon only.
- **PRAYER HERO CARD** (Home centerpiece): full-width, 24px radius, subtle
  emerald→deep-emerald gradient, gold hairline inner frame (1px, 8%
  opacity), ornament: thin geometric star motif top-right corner at 10%
  opacity. Content: eyebrow "NEXT PRAYER", prayer name 22/700 Ivory, time
  34/700 Ivory tabular, countdown "in 2h 14m" in Gold Tint pill, sub-line
  "current: Asr" small Ivory 80%.
- **PRAYER TIME TILES:** 5 equal tiles in one row inside a white card
  (16px radius, hairline border) — each tile = micro-icon or label, prayer
  name 12/600 Ink, time 14/700 Emerald; the *current* prayer tile gets a
  Gold Tint fill + gold left tick. Sunrise shown small in the card footer.
- **DAILY INSPIRATION GRID:** 2×2 white cards (16px radius, hairline) —
  Hadith of the Day, Ayah of the Day, Name of Allah, Dua of the Day; each
  card = small gold icon, micro-label, one preview line truncated.
- **SURAH TILE:** white row card, 12px radius — left: number in a gold-ring
  circle (36px, Emerald numeral); middle: surah name 16/700 Ink + "X ayahs"
  caption; right: Makki/Madani chip (Kaaba/Madinah glyph on Gold Tint).
- **SEARCH + SEGMENTED TOGGLE:** rounded-12 search field on Ivory with
  hairline border and magnifier icon; below it a segmented control "Surahs |
  Ayat" — active segment Emerald fill + white text, inactive Ivory.
- **AZKAR CARD:** 3-column grid cards — white, 16px radius, centered: gold
  ornament icon, category name 13/600 Ink, count caption.
- **AZKAR COUNTER ROW:** full-width white card: zekr text right-aligned
  15px/1.7 Ink, reference caption Sage, then a full-width Emerald pill
  button showing remaining count — pressed decrements; at 0 it becomes
  disabled Sage "Done".
- **TASBEEH DIAL:** centered large circular dial ~180px — Emerald ring with
  gold inner ring, counter numeral 56/700 Emerald center, phrase name above
  18/700; tap = increment (subtle scale pulse); phrase pager dots below;
  "Reset" text button with refresh glyph.
- **QIBLA DIAL:** large centered compass dial ~240px — ivory face, gold
  degree ticks, Emerald needle pointing to Kaaba glyph marker; below:
  "Qibla bearing 256°" 20/700 + "3,412 km to Makkah" caption + a 2D static
  map strip fallback.
- **SETTINGS ROWS:** grouped white cards (16px radius, hairline): label
  left + control right (chevron for pickers, switch for toggles); group
  eyebrows uppercase micro-labels; destructive/danger rows in Clay.
- **BOTTOM SHEETS:** 20px top radius, grab handle, title, scrollable body,
  one primary Emerald action.
- **BUTTONS:** primary = Emerald fill, white text, 12px radius, 48px height;
  secondary = white + hairline border, Ink text; tertiary = Emerald text
  only. Icon buttons circular.
- **CHIPS/PILLS:** status pills 8px radius, tint bg + colored text; small
  24px info chips for times.

## 5. Layout

24px side padding (20px inside cards). Vertical rhythm 8/12/16/24. Cards
never touch edges. Screen structure: title/context → hero or primary
content → supporting sections with micro-label eyebrows → floating nav.
Empty states: one line of copy + one action. Skeleton shimmer loaders, no
spinners.

## 6. Motion

200–300ms ease-out fades/slides. Tasbeeh dial scale pulse on tap. Compass
needle eases to bearing. Nothing bounces; nothing spins forever.

## 7. Iconography & Ornament

Thin-line icons (24px), stroke 1.75px. Ornaments: 8-pointed star motif,
subtle arabesque corner flourishes — ALWAYS ≤10% opacity, only on hero
surfaces and section headers. Kaaba glyph for Makki/Qibla, mosque-dome
glyph for Madani/navigation. No photographs of people anywhere.

## 8. Banned

No emojis in UI. No stock photos of people. No pure-black screens, no neon,
no glassmorphism, no heavy drop shadows, no full-bleed gradients outside
the hero card, no three equal KPI-style cards, no marketing hero sections,
no page-level tab bars (segmented control inside content is fine).

## 9. Sample Data (use exactly)

Location: Zanzibar, Tanzania. Date: Saturday 31 October 2026 ·
9 Jumada al-Ula 1448. Prayer times: Fajr 05:12 · Sunrise 06:24 ·
Dhuhr 12:09 · Asr 15:27 · Maghrib 18:24 · Isha 19:38. Next: Maghrib —
"in 2h 14m". Qibla bearing: 256° · 3,412 km to Makkah.
Surahs: 1 Al-Fatihah (7, Makki) · 2 Al-Baqarah (286, Madani) ·
3 Aal-Imran (200, Madani) · 112 Al-Ikhlas (4, Makki) ·
113 Al-Falaq (5, Makki) · 114 An-Nas (6, Makki).
Azkar categories: Morning Adhkar, Evening Adhkar, After Prayer, Sleep,
Waking, Adhan, Travel, Ruqyah (Quran), Ruqyah (Sunnah), Gratitude.
Tasbeeh phrases: SubhanAllah, Alhamdulillah, Allahu Akbar, La ilaha
illallah, Astaghfirullah.
