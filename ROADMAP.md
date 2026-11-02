# Muslim App — Product Roadmap & Direction

> Status reflects the code on `main` (checked item by item against the app,
> November 2026). `FEATURES.md` describes current behaviour screen by screen.
> Device QA on real Android/iOS hardware is still outstanding.

Direction: build incrementally — make the core, high-stakes utilities (precise
prayer times, Qibla, Quran reading) flawless and offline-capable before adding
complex features like social audio or AI. Privacy-first by design: local
location processing, no ad networks, no user tracking.

Languages: the app ships **English** (default), **Arabic** (RTL) and
**Swahili** as first-class UI locales (see the cross-cutting Localization
track below). Religious text stays Arabic; Quran meaning is offered in
English and Swahili.

Status legend: ✅ implemented · 🔶 partially implemented · ⬜ not started

## Where We Are Today

See `FEATURES.md` for the full current-state reference. In short:

- ✅ Prayer times via `adhan` on-device, 5 calculation methods + madhab
- ✅ Android prayer notifications: a week of one-shot reminders at each
  day's real times, localized, renewed app-wide
- ✅ Qibla compass with accuracy-based calibration badge + geodesic fallback
- ✅ Offline Quran text (Uthmani) with English/Swahili translation,
  bookmarks, last-read tracked as you scroll, offline search (ar/en/sw)
- ✅ Hifz: 4 per-ayah reciters, repeat loops, speed, offline downloads
- ✅ Azkar (all 39 source categories), tasbeeh with targets and haptics
- ✅ Dual Hijri/Gregorian calendar with occasions and day adjustment
- ✅ Light / Dark (true-black) / System theme
- ⬜ High-latitude rules, hadith library, word-by-word, mosque finder,
  widgets, analytics, background audio

---

## Phase 1 — Core Essentials (MVP)

Non-negotiable utilities used multiple times daily. Accuracy + offline
availability are critical.

### Precise Prayer Times (Salah)
- ✅ Location-based calculation (`adhan`, `geolocator`, GPS or city
  lookup) with selectable methods: Umm al-Qura, MWL, Egypt, Karachi, ISNA;
  Shafi/Hanafi madhab
- ⬜ Manual minute overrides / high-latitude adjustments
- 🔶 Prayer notifications when the app is closed — Android: scheduled
  one-shot reminders for the next 7 days at each day's computed times,
  renewed on launch/resume and when location, method, madhab or language
  change. Plain notification sound (no full Adhan audio); iOS untested
- ✅ Prayer names, countdown labels, and notification copy localized
  (ar/en/sw)

### Dynamic Qibla Finder
- ✅ Magnetometer compass (`flutter_compass`); calibration badge shows
  "calibrated" only when the sensor reports ≤ 30° heading error
- 🔶 Fallback without a compass — geodesic bearing + distance card and a
  compass-unavailable state; no 2D map
- ✅ Compass UI labels + instructions localized (ar/en/sw)

### The Holy Quran (Reading)
- ✅ Offline-first reading of bundled Uthmani text (Amiri font) in a
  mushaf-style reader; no network needed
- ⬜ Indo-Pak script option / page-faithful mushaf layout
- ✅ Start anywhere: Go to surah + ayah / juz / hizb / page, search
  shortcuts (`juz 5`, `page 300`, `2:255-260`), `deen://quran/2/255`
  links, live Juz/Hizb/Page chips, Continue reading + Ayah of the Day on
  Home ([docs/FEATURE_REVIEW.md](docs/FEATURE_REVIEW.md) phase 1)
- ✅ Surah bookmarks + last-read memory (saved as you scroll; Continue
  Reading resumes at that ayah)
- ✅ Quran text stays Arabic; bundled **translation layer** — English
  (Sahih International) and Swahili (Al-Barwani), or Arabic only
- ✅ UI chrome (surah index, sort, search, bookmarks) localized; surah
  names transliterated/translated for en/sw

### Privacy-First Architecture
- ✅ Location is processed locally only (geolocator → adhan on-device);
  no account, no server, no analytics
- ✅ No ad networks (none present)

**Packages:** `adhan` ✅ · `geolocator` ✅ · `flutter_compass` ✅ ·
`flutter_local_notifications` + `timezone` ✅ · offline text is bundled JSON
in `assets/json/` (no Quran package needed)

## Phase 2 — Engagement & Daily Rituals

Personalization, audio, supplementary texts — the daily habit loop.

### Quranic Audio & Memorization
- ✅ Surah audio streaming in the reader (`audioplayers`, Alafasy via
  mp3quran.net) with seek and speed
- ✅ Offline per-surah downloads (resumable, verified) and 4 per-ayah
  reciters for Hifz: Alafasy, Abdul Basit, Al-Husary, Al-Minshawi
- ✅ Ayah repeat loops + playback speed for Hifz
- ✅ Player controls, reciter picker, download states localized (ar/en/sw)
- ⬜ Background / lock-screen playback controls

### Supplications (Hisnul Muslim / Duas)
- ✅ All 39 bundled `azkar.json` categories surfaced (mapped to display
  collections + Other); per-zekr tap-to-count, auto-advance, daily progress
- ⬜ Transliterations + multi-language translations — English translation
  available in standard Hisnul Muslim sources; **Swahili azkar translations
  will need custom content work** (no canonical public dataset). Azkar are
  Arabic only today

### Smart Tasbeeh Counter
- ✅ Tap dial, 5 phrases with transliteration + meaning, laps, daily total,
  streak — persisted
- ✅ Haptic feedback per tap + milestone pulse (toggleable)
- ✅ Targets 33/100 with lap completion
- ✅ Phrase list + labels localized (ar/en/sw)

### Islamic (Hijri) Calendar
- ✅ Hijri + Gregorian dates on the home card
- ✅ Dual calendar month view, White Days and upcoming occasions (Ramadan,
  Eid, Ashura…), local −2…+2 day moon-sighting adjustment
- ✅ Month/day names rendered in the active locale

**Packages:** `audioplayers` ✅ (evaluate `just_audio` + `audio_service`
for background/lock-screen controls) · haptics via Flutter's
`HapticFeedback` ✅ · persistence via `get_storage` ✅ (a local DB is only
needed for hadith/tafsir FTS) · `hijri` ✅

## Phase 3 — Knowledge & Context

Scholarly resources, search, community integration.

### Tafsir & Word-by-Word
- ✅ Named tafsir: Ibn Kathir from quran.com (`/tafsirs/{14|169}/by_ayah`,
  Arabic / English abridged), cached locally after first load; offline
  state when never fetched
- 🔶 More collections / Swahili — **Swahili tafsir resources are scarce**;
  Swahili users get the English text
- ⬜ Word-by-word grammar — api.quran.com provides per-word translations
  in English; Swahili per-word data is unlikely to exist

### Advanced Global Search
- ✅ Offline ayah search over the bundled corpus — Arabic (diacritics,
  Quranic marks and Uthmani spellings folded), English and Swahili
  translations, and verse references (`2:255`, `٢:٢٥٥`); jumps to and
  highlights the ayah
- ⬜ Semantic search across translations + hadith collections
- ✅ Language-scoped search (Arabic text and the translations are matched
  separately and labelled)

### Verified Hadith Library
- ⬜ Sahih al-Bukhari, Sahih Muslim, Nawawi's 40, with authenticity grades
  (only a curated daily-hadith list of 16 referenced narrations exists)
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
- ✅ True-black OLED dark mode (Light / Dark / System setting)
- 🔶 Scalable Quran text (small / medium / large); no dyslexia-friendly
  font or app-wide text scaling
- ✅ Font per script: bundled Amiri for Quran/azkar Arabic, Plus Jakarta
  Sans + Manrope for the Latin UI

### Contextual Push Notifications
- 🔶 Hadith of the Day and Dua of the Day cards on Home (rotate daily,
  Arabic with references); no push notification or frequency setting

---

## Localization (i18n) — Cross-Cutting Track

Not a phase — an architectural prerequisite, now in place. UI strings live
in GetX translation maps (`lib/app/i18n/app_translations.dart`) with every
key present in en, ar and sw.

### Foundation (Phase 1)
- ✅ All UI strings extracted into translation resources (GetX maps
  rather than ARB); every key is present in en, ar and sw
- ✅ Language switcher in onboarding and settings; choice persisted
- ✅ Direction derived from the active locale (ar = RTL, en/sw = LTR);
  scripture always RTL
- ✅ Locale-aware formatting via `intl` (dates, times)

### Content Per Language (what actually exists upstream)

| Content | Arabic | English | Swahili |
|---|---|---|---|
| UI strings / feature labels | source | translate once | translate once |
| Quran text | canonical (never translated) | — | — |
| Quran translation of meaning | — | Saheeh International etc. (api.quran.com) | al-Farsy (api.quran.com) |
| Tafsir | full collections | Ibn Kathir EN | scarce — custom or omit |
| Azkar (Hisnul Muslim) | bundled ✅ | standard EN translations exist | custom translation needed |
| Hadith | full | full | rare — ar/en initially |
| Daily card content (Hadith/Dua of the Day) | bundled ✅ | not yet translated | not yet translated |

Rule: where Swahili content has no upstream source, ship the UI in Swahili
but keep the religious text in Arabic + English fallback — never machine-
translate Quran/hadith silently.

### Packages
GetX translations ✅ · `flutter_localizations` ✅ · `intl` ✅

**Packages:** `home_widget` (new) · `fl_chart` (new, analytics graphs) ·
`flutter_screenutil` (new, foldable/tablet scaling) · dark mode is built
in (`AppColors` / `AppTheme.current`), no package needed

---

## Development Lifecycle Summary

| Phase | Focus | Complexity | Tech Stack Impact | Current State |
|---|---|---|---|---|
| 1 | Core Utilities | Low–Med | Local sensors, native alarms | ~85% — high-latitude rules, full Adhan audio, iOS notification QA, 2D map fallback, Indo-Pak script left |
| 2 | Habit Building | Medium | Audio pipelines, local SQL | ~80% — azkar translations/transliteration and background audio left |
| 3 | Content & Community | Med–High | Network APIs, FTS engines | ~35% — tafsir + offline search done; hadith library, maps, word-by-word missing |
| 4 | OS Integration | High | Widgets, wearables, state sync | ~20% — dark mode, script fonts, daily cards done; widgets, wearables, analytics missing |

## Tech Stack Blueprint

```
┌──────────────────────────────────────────────────────────┐
│                      FLUTTER UI                          │
└──────────────────────────┬───────────────────────────────┘
                           │
      ┌────────────────────┴────────────────────┐
      ▼                                         ▼
┌───────────┐                             ┌───────────┐
│ SERVICES  │ adhan ✅ · geolocator ✅     │  STORAGE  │ get_storage ✅
│ & SENSORS │ flutter_compass ✅           │ & CACHING │ sqflite ⬜ (Hadith FTS)
└───────────┘                             └───────────┘
                           │
      ┌────────────────────┴────────────────────┐
      ▼                                         ▼
┌───────────┐                             ┌───────────┐
│   AUDIO   │ audioplayers ✅ →            │  SYSTEM   │ home_widget ⬜
│ PIPELINE  │ just_audio + audio_service ⬜│INTEGRATION│ local_notifications ✅
└───────────┘                             └───────────┘
```

## Immediate Next Steps

The original Phase 1 list (i18n, notifications, method picker, Qibla,
offline Quran, splash resilience) is done. Next, ordered by user impact
vs. effort:

1. **Device QA** — run `integration_test/` and a manual pass on a real
   Android phone and an iPhone (notifications firing with the app closed,
   compass accuracy, downloads). Then the store release in
   [docs/RELEASE.md](docs/RELEASE.md).
2. **High-latitude rules + minute overrides** in prayer settings.
3. **Azkar English translation + transliteration** (Swahili later, custom
   content).
4. **Background / lock-screen audio** (`audio_service`).
5. **Hadith library** (Nawawi's 40 first, then Bukhari/Muslim, ar/en)
   with local FTS.
6. **Next-prayer home-screen widget** (`home_widget`).
