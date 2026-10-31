# Muslim App — Product Roadmap & Direction

Direction: build incrementally — make the core, high-stakes utilities (precise
prayer times, Qibla, Quran reading) flawless and offline-capable before adding
complex features like social audio or AI. Privacy-first by design: local
location processing, no ad networks, no user tracking.

Languages: the app ships **Arabic** today; the roadmap targets **English** and
**Swahili** as first-class locales across every feature (see the cross-cutting
Localization track below — it is a Phase 1 architectural prerequisite even
though translations land progressively).

Status legend: ✅ implemented · 🔶 partially implemented · ⬜ not started

## Where We Are Today

See `FEATURES.md` for the full current-state reference. In short:

- ✅ Prayer times via `adhan` (Umm al-Qura / Shafi, location-based)
- ✅ Hijri + Gregorian date display on home card
- ✅ Quran surah index, mushaf page reading (remote scans), surah audio
- ✅ Ayah search + tafsir bottom sheet + share
- ✅ Azkar categories/list from bundled `azkar.json`, tasbeeh counter
- ⬜ Notifications, Qibla compass, offline Quran, bookmarks, widgets

---

## Phase 1 — Core Essentials (MVP)

Non-negotiable utilities used multiple times daily. Accuracy + offline
availability are critical.

### Precise Prayer Times (Salah)
- 🔶 Location-based calculation — exists (`adhan`, `geolocator`) but only
  Umm al-Qura method; needs selectable methods (MWL, ISNA, Egypt…)
- ⬜ Manual overrides / high-latitude adjustments
- ⬜ Background Adhan notifications when app is closed
- ⬜ Prayer names, countdown labels, and notification copy localized
  (ar/en/sw) — currently hardcoded Arabic strings

### Dynamic Qibla Finder
- ⬜ Magnetometer compass
- ⬜ 2D map fallback indicator
- ⬜ Compass UI labels + instructions localized (ar/en/sw)

### The Holy Quran (Reading)
- 🔶 Reading exists via remote mushaf PNG scans (requires network)
- ⬜ High-fidelity Uthmanic / Indo-Pak scripts, offline-first rendering
- ⬜ Ayah bookmarking + last-read memory
- ⬜ Quran text stays Arabic; **translation layer** for meaning —
  English (e.g. Saheeh International via api.quran.com) and Swahili
  (al-Farsy translation available on api.quran.com)
- ⬜ UI chrome around the mushaf (surah picker, bookmarks) localized;
  surah names need transliteration for en/sw

### Privacy-First Architecture
- 🔶 Location is processed locally only (geolocator → adhan on-device)
- ✅ No ad networks (none present)

**Packages:** `adhan` ✅ installed · `geolocator` ✅ installed ·
`flutter_compass` or `smooth_compass` (new) · `flutter_local_notifications`
or `awesome_notifications` (new) · `quran` / `quran_flutter` (new, offline
text)

## Phase 2 — Engagement & Daily Rituals

Personalization, audio, supplementary texts — the daily habit loop.

### Quranic Audio & Memorization
- 🔶 Surah audio streaming exists (`audioplayers`, Alafasy via mp3quran.net)
- ⬜ Offline downloads, multiple reciters (Qurra)
- ⬜ Ayah repeat loops + playback speed for Hifz
- ⬜ Player controls, reciter picker, download states localized (ar/en/sw)

### Supplications (Hisnul Muslim / Duas)
- 🔶 39 azkar categories bundled in `azkar.json` (only first 10 rendered —
  `take(10)`); per-zekr tap-to-count
- ⬜ Transliterations + multi-language translations — English translation
  available in standard Hisnul Muslim sources; **Swahili azkar translations
  will need custom content work** (no canonical public dataset)
- ⬜ Remaining 29 categories surfaced in UI

### Smart Tasbeeh Counter
- 🔶 Tap counter, 6 phrases, page-swipe reset
- ⬜ Haptic feedback per tap + milestone pulses
- ⬜ Custom targets (33/100) with reset alerts
- ⬜ Phrase list + labels localized (ar/en/sw)

### Islamic (Hijri) Calendar
- 🔶 Hijri date string on home card (`hijri` package, `ar` format only)
- ⬜ Dual calendar view, significant dates (Ramadan, Eid, Ashura),
  moon-sighting offsets
- ⬜ Month/day names rendered in the active locale (`intl` is already
  installed and supports en/sw date formatting)

**Packages:** `just_audio` + `audio_service` (new — evaluate migrating from
`audioplayers` for background/lock-screen controls) · `vibration` /
`haptic_feedback` (new) · `hive` / `isar` / `objectbox` (new, local DB) ·
`hijri` ✅ installed

## Phase 3 — Knowledge & Context

Scholarly resources, search, community integration.

### Tafsir & Word-by-Word
- 🔶 Tafsir via `api.quran.com/v4/verses/{id}/tafsirs` (first result only,
  unnamed source)
- ⬜ Named tafsir collections — Ibn Kathir exists in Arabic and English;
  **Swahili tafsir resources are scarce** (may fall back to translated
  commentary or mark content ar/en only)
- ⬜ Word-by-word grammar — api.quran.com provides per-word translations
  in English; Swahili per-word data is unlikely to exist

### Advanced Global Search
- 🔶 Remote ayah text search via `api.quran.com/v4/search` (fires per
  keystroke — needs debounce)
- ⬜ Semantic search across translations + hadith collections
- ⬜ Language-scoped search (search Arabic text AND active-locale
  translations separately)

### Verified Hadith Library
- ⬜ Sahih al-Bukhari, Sahih Muslim, Nawawi's 40, with authenticity grades
- ⬜ Translations: Arabic + English readily available (e.g. Sunnah.com
  datasets); **Swahili hadith translations are rare** — likely ar/en only
  initially

### Mosque & Halal Finder
- ⬜ Map APIs → nearby masjids + halal dining
- ⬜ POI labels, distance strings, and empty states localized (ar/en/sw)

**Packages:** `google_maps_flutter` / `flutter_map` + Overpass/Places (new) ·
`sqlite3` / `sqflite` (new, local Tafsir/Hadith FTS) · `flutter_html` / `xml`
(new — tafsir already returns HTML text, currently rendered as plain string)

## Phase 4 — Personalization, UX & Ecosystem (Advanced)

Premium experience via OS features + accessibility.

### System Integration & Widgets
- ⬜ Home/lock screen widgets for next prayer — widget strings localized
  (ar/en/sw) since they render outside Flutter's Directionality
- ⬜ WearOS / watchOS mini-apps (Qibla + notifications)

### Spiritual Analytics (Private Tracking)
- ⬜ Local-only habit dashboard (salah, pages read, fasting)
- ⬜ Chart axes, streak labels, milestones localized (ar/en/sw)

### Accessibility & UI Polish
- ⬜ True-black OLED dark mode (for night reading)
- ⬜ Dyslexia-friendly fonts, scalable text for elderly users
- ⬜ Font fallback per script: Arabic Quran font vs. Latin (en/sw) UI font —
  `google_fonts` covers Latin; Arabic strings need an Arabic-capable family
  (Cairo/almarai already used)

### Contextual Push Notifications
- ⬜ "Ayah/Hadith of the Day" pushes in the user's chosen language, with
  user-controlled frequency

---

## Localization (i18n) — Cross-Cutting Track

Not a phase — an architectural prerequisite. The current codebase has
**Arabic hardcoded throughout** (`'ar'` locale in `main.dart`, `DateFormat`,
hardcoded `Text('الصلاة التالية')`-style strings, forced `TextDirection.rtl`).
Retrofitting gets exponentially harder as screens grow, so the i18n
foundation lands in Phase 1 even though translated *content* arrives
progressively.

### Foundation (Phase 1)
- ⬜ Extract all hardcoded strings into ARB resource files (official
  `gen_l10n` flow via `flutter_localizations`, or `easy_localization`)
- ⬜ `Locale` switcher in settings; persist choice locally
- ⬜ Remove forced `TextDirection.rtl` — derive direction from the active
  locale (ar = RTL, en/sw = LTR)
- ⬜ Locale-aware formatting via existing `intl` (dates, times, digits)

### Content Per Language (what actually exists upstream)

| Content | Arabic | English | Swahili |
|---|---|---|---|
| UI strings / feature labels | source | translate once | translate once |
| Quran text | canonical (never translated) | — | — |
| Quran translation of meaning | — | Saheeh International etc. (api.quran.com) | al-Farsy (api.quran.com) |
| Tafsir | full collections | Ibn Kathir EN | scarce — custom or omit |
| Azkar (Hisnul Muslim) | bundled ✅ | standard EN translations exist | custom translation needed |
| Hadith | full | full | rare — ar/en initially |
| Daily card content (حديث اليوم etc.) | hardcoded lists | translate the bundled lists | translate the bundled lists |

Rule: where Swahili content has no upstream source, ship the UI in Swahili
but keep the religious text in Arabic + English fallback — never machine-
translate Quran/hadith silently.

### Packages
`flutter_localizations` + `gen_l10n` ARB (official, recommended) or
`easy_localization` · `intl` ✅ already installed

**Packages:** `home_widget` (new) · `fl_chart` (new, analytics graphs) ·
`flutter_screenutil` (new, foldable/tablet scaling) · `adaptive_theme` /
`flex_color_scheme` (new, dark mode)

---

## Development Lifecycle Summary

| Phase | Focus | Complexity | Tech Stack Impact | Current State |
|---|---|---|---|---|
| 1 | Core Utilities | Low–Med | Local sensors, native alarms | ~40% — prayer times done; notifications, Qibla, offline Quran missing |
| 2 | Habit Building | Medium | Audio pipelines, local SQL | ~50% — audio + azkar + tasbeeh exist; haptics, translations, local DB missing |
| 3 | Content & Community | Med–High | Network APIs, FTS engines | ~25% — basic tafsir + search exist; hadith, maps, word-by-word missing |
| 4 | OS Integration | High | Widgets, wearables, state sync | 0% — not started |

## Tech Stack Blueprint

```
┌──────────────────────────────────────────────────────────┐
│                      FLUTTER UI                          │
└──────────────────────────┬───────────────────────────────┘
                           │
      ┌────────────────────┴────────────────────┐
      ▼                                         ▼
┌───────────┐                             ┌───────────┐
│ SERVICES  │ adhan ✅ · geolocator ✅     │  STORAGE  │ isar / sqflite
│ & SENSORS │ flutter_compass ⬜           │ & CACHING │ ⬜ (Hadith/Tafsir)
└───────────┘                             └───────────┘
                           │
      ┌────────────────────┴────────────────────┐
      ▼                                         ▼
┌───────────┐                             ┌───────────┐
│   AUDIO   │ audioplayers 🔶 →            │  SYSTEM   │ home_widget ⬜
│ PIPELINE  │ just_audio + audio_service ⬜│INTEGRATION│ local_notifications ⬜
└───────────┘                             └───────────┘
```

## Immediate Next Steps (Phase 1 completion)

Ordered by user impact vs. effort:

1. **i18n foundation first** — extract hardcoded Arabic strings into ARB
   resources + locale switcher *before* the codebase grows. Everything new
   then ships trilingual from day one.
2. **Prayer notifications** — `flutter_local_notifications` + scheduled Adhan;
   highest daily-value gap in the current build.
3. **Calculation method picker** — expose `adhan`'s methods in a settings
   sheet; persist choice locally.
4. **Qibla compass** — `flutter_compass` + bearing math from stored coords.
5. **Offline Quran** — bundle mushaf images or a `quran` text package; cache
   fetched pages.
6. **Splash resilience** — add timeout + offline fallback so the app opens
   without network (fix the fragilities listed in `FEATURES.md`).
