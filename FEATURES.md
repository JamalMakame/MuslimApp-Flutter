# Deen — Current Features & Architecture

_Last updated: habits and memorisation (Khatmah plan, daily goal + streak, reading reminder, Hifz self-test and review list)._

Deen is a Flutter Islamic companion app. All core data is bundled locally;
nothing requires an account or a server. Remote calls are optional
enhancements (audio streaming and downloads, tafsir).

## Stack

- **State / DI / navigation:** GetX (`GetMaterialApp`, `GetxController`,
  `Obx`, `Get.toNamed`)
- **Persistence:** `get_storage` key-value store
- **Prayer times:** `adhan` (on-device calculation)
- **Location:** `geolocator` + `geocoding`
- **Compass:** `flutter_compass`
- **Notifications:** `flutter_local_notifications` (local only; permission
  deferred until the user enables prayer notifications)
- **Audio:** `audioplayers` (surah streams, per-ayah Hifz streams or
  locally downloaded MP3s)
- **Hijri dates:** `hijri` (Umm al-Qura estimate with local calibration);
  formatting via `intl`
- **Fonts (bundled):** Plus Jakarta Sans, Manrope, Amiri
- **Sharing:** `share_plus`

## Localization

Three UI locales via GetX map translations: English (`en`, default),
Arabic (`ar` — RTL), Swahili (`sw`). Scripture (Quran/Azkar Arabic) is
always RTL regardless of UI direction. Quran translation selectable:
English (Sahih Intl.), Swahili (Al-Barwani), or Arabic-only.

## Routes (`lib/app/routes/app_pages.dart`)

| Route | Screen | Controller |
|---|---|---|
| `/splash` | Splash | AppController (boot orchestrator) |
| `/onboarding` | Onboarding | — |
| `/home` | Prayer dashboard | HomeController |
| `/quran` | Quran index | QuranController |
| `/reader/:surah` | Mushaf reader | ReaderController |
| `/azkar` | Azkar categories | AzkarController |
| `/azkar-detail/:bucket` | Dhikr list + counters | AzkarDetailController |
| `/tasbeeh` | Digital tasbeeh | TasbeehController |
| `/qibla` | Compass | QiblaController |
| `/calendar` | Dual Hijri/Gregorian calendar | CalendarController |
| `/memorize/:surah` | Hifz and offline per-ayah audio | MemorizeController |
| `/habits` | Reading goal, streak, Khatmah plan, reading reminder, memorisation progress | HabitService |
| `/settings` | Settings | SettingsController (permanent) |

Navigation shell: floating 4-slot pill — Home / Quran / Azkar / Settings.
Qibla and calendar are reached from Home; Hifz from the Quran reader.

**Habits (`HabitService`, all on-device).** Every page the reader settles on
counts as read for that day (`read_log`, kept 400 days). Home shows today's
pages against the daily goal, the streak (days in a row meeting the goal,
or at least one page) and today's Khatmah portion with a Start button. The
Khatmah splits 604 pages evenly over 7–60 days; Start opens the first unread
page up to today's portion, so missed days are caught up first. An optional
daily reading reminder joins the prayer notifications (works without a
location). Hifz has a self-test: hide the ayah, reveal word by word or all,
then mark memorised (next review after 1, 3, 7, 14, 30, 60 days) or needs
review (due tomorrow); `/habits` lists ayahs due and memorised counts per surah.

## Screens

- **Splash** — native iOS emerald launch with the Deen mark and wordmark
  hands off to a full-screen Flutter splash with matching gold dome and
  progress hairline; initializes services in parallel (each bounded by a
  timeout), then routes to onboarding (first run) or home. If the bundled
  Quran/azkar data fails to load it shows an error with Retry.
- **Onboarding** — language pills, prayer location (GPS or manual city
  lookup), calculation method (12), high-latitude rule, "Adjust times &
  reminders" (per-prayer ± minutes and reminder timing), morning/evening
  azkar reminders, monthly timetable (shareable); privacy copy ("100% On-Device").
- **Home** — emerald hero card with next-prayer countdown, prayer tiles
  (current prayer highlighted gold), sunrise row, Continue reading card
  (last-read ayah with its juz/page; opens the reader there), Qibla card,
  Ayah of the Day (40 well-known ayahs, rotates daily, opens the reader at
  that ayah), Hadith of the Day / Dua of the Day cards (rotate daily, tap
  for full text), Hijri + Gregorian dates.
- **Quran index** — search field, Surahs / Juz / Ayat segment (Juz: 30
  juz, each expanding into its 8 hizb-quarter starts), Go to and Bookmarks
  buttons,
  continue-reading card (last-read persisted), 114 surah tiles with gold-ring numbers,
  Makki/Madani chips, revelation order, sort toggle, Juz-30 divider.
- **Reader** — surah cartouche + basmala (suppressed for Al-Fatihah,
  where ayah 1 is the basmala, and At-Tawbah which has none), then one
  block per ayah, built lazily as it scrolls in (`scrollable_positioned_list`):
  number medallion (sajda in emerald), Arabic with ۞ at every hizb
  quarter, its translation underneath, TAFSIR link, bookmark marker.
  Long-press or "⋯" opens the ayah menu: play from here, bookmark /
  remove, add / edit note, copy, share (Arabic, translation, reference
  and a `deen://` link), tafsir, memorise from here (Hifz at that ayah).
  Header: Go to, bookmark the ayah being read. Juz / Hizb / Page chips
  follow the reading line (tap to Go to). Footer: previous / next surah.
  Audio bar: full surah (Alafasy stream) or ayah-by-ayah from the chosen
  ayah with the Hifz reciter (downloaded files when present), highlighting
  and scrolling to the ayah being recited; play/pause/seek/speed.
- **Audio everywhere** — one reciter setting (Settings → Default
  reciter) used by the reader's ayah-by-ayah playback and Hifz; with a
  reciter other than Alafasy the reader's play button recites ayah by
  ayah. Playback continues with the screen locked or the app in the
  background (`audio_service` foreground service on Android, `audio`
  background mode on iOS) with notification / lock-screen play, pause,
  previous / next ayah and stop.
- **Bookmarks** (`/bookmarks`, index header) — bookmarked ayahs newest
  first with Arabic snippet and note; edit note, delete, tap to open.
  Older surah bookmarks are migrated to ayah 1 of that surah.
- **Go to sheet** — surah + ayah (validated against the surah's length),
  juz 1–30, hizb 1–60 or mushaf page 1–604; resolves to the first ayah
  from the bundled juz/hizb-quarter/page data. In the reader, the same
  surah scrolls in place and another surah replaces the reader.
- **Ayat search shortcuts** — `2:255`, `2:255-260`, `juz 5`, `hizb 12`,
  `page 300` (also `الجزء`/`حزب`/`صفحة` and `juzuu`/`hizbu`/`ukurasa`,
  Arabic-Indic digits): a juz lists its 8 quarter starts, a hizb its 4,
  a page or range its ayahs.
- **Quran links** — `deen://quran/2/255`, `deen://quran/2:255`,
  `deen://quran/36`, `deen://quran?juz=30|hizb=12|page=300` open the
  reader there (Android intent filter, iOS URL scheme, `app_links`); a
  link that starts the app waits until Home is up.
- **Tafsir sheet** — modal bottom sheet: ayah text, Sahih Intl. quote,
  Ibn Kathir commentary (remote w/ graceful offline state), Share/Copy/Done.
- **Azkar categories** — daily progress card, 11-collection grid
  (39 source categories mapped to display buckets), Instant Dhikr card.
- **Azkar detail** — numbered dhikr cards (Arabic + source + repeat),
  TAP TO COMPLETE buttons, auto-advance toggle, completion states,
  persisted daily progress.
- **Tasbeeh** — phrase picker (5 adhkar), Arabic + transliteration +
  meaning, large progress-ring dial, lap/cycle, daily total, streak,
  haptics toggle — all persisted.
- **Qibla** — painted compass dial (gold ticks, Kaaba marker, emerald
  needle), bearing + distance to Makkah, calibration chip, geodesic
  fallback section, compass-unavailable state on sensorless devices.
- **Calendar** — dual Hijri/Gregorian month grid, White Days and upcoming
  Islamic occasions; saves a -2 to +2 day local Hijri adjustment without
  changing the actual Gregorian date. Moon phases are estimates, not
  verified sightings.
- **Hifz** — per-ayah playback, reciter selection, repeat loops, speed,
  seeking, auto-advance and locally saved position. Per-surah downloads
  resume after interruption; only verified complete sets show as offline.
  Incomplete ayahs can still play from the local cache. Deletion requires
  confirmation. Transliteration is not yet bundled or shown.
- **Settings** — Prayer (method/madhab/notifications/location),
  Appearance (language/theme/text size), Quran & Audio (reciter, ayah
  audio, translations, translation language), Data & Privacy (clear
  local data (including downloaded audio after confirmation), privacy
  sheet), version footer.

## Services (`lib/app/services/`)

- `storage_service` — get_storage wrapper, typed keys
- `location_service` — GPS + city-name geocoding → `PlaceInfo`
- `prayer_service` — `adhan`-based `PrayerDay` (slots, current/next,
  countdown, Hijri/Gregorian dates)
- `notification_service` — tz-scheduled one-shot prayer reminders for the
  next 7 days at each day's real times (localized; renewed app-wide)
- `quran_service` — bundled surah/ayah data + translations, offline
  ar/en/sw search, last read + bookmarks, remote tafsir with local cache,
  audio URL building and download manifest
- `audio_cache_service` — validates local MP3s, downloads per ayah via
  temporary files, resumes interrupted downloads and verifies full surahs
- `hijri_date_service` — converts dates using a locally persisted offset
- `azkar_service` — bundled azkar.json → 10 display buckets + Other,
  daily-done persistence

## Bundled data (`assets/json/`)

`surahs.json` (114 merged metadata), `quran_ar_uthmani.json`,
`quran_en_sahih.json`, `quran_sw_barwani.json`, `azkar.json`,
`quran_meta.json`, `chapters_en.json`.

## Remote endpoints (optional)

- `api.quran.com` — Ibn Kathir tafsir (cached in storage)
- `server8.mp3quran.net/afs` — Alafasy per-surah audio
- `cdn.islamic.network/quran/audio/{128|192}` — on-demand per-ayah Hifz
  MP3s (Abdul Basit is served at 192 only)

## Design

Stitch-generated spec: `design/DESIGN.md`, artifacts in
`design/screens/` (13 PNG + HTML), mapping in `design/DESIGN_INDEX.md`.
Emerald `#0E6B5C` / gold `#C9A24B` / ivory `#F8F6F1` palette.

## Tests

- `integration_test/app_test.dart` — full Phase-1 flow (onboarding →
  home → qibla → quran → reader → tafsir → azkar → detail → tasbeeh →
  settings → ar/en locale round-trip).
- `integration_test/locale_test.dart` — locale switch.
- `integration_test/tour_test.dart` — per-screen screenshot tour.
- `test/` — unit and widget tests: offline search, reminders scheduling,
  calendar, Hifz, splash, Phase 4 behaviour and a dark-mode screen pass
  (`flutter test test`).
- `test/calendar_test.dart` — calibrated dates, grid and event ordering.
- `test/memorize_test.dart` — repeat decisions, mocked MP3 downloads,
  interruption, stale cache and local-data cleanup.
- `test/phase2_widget_test.dart` — calendar navigation, Arabic RTL and
  narrow-screen Hifz layout without native audio or HTTP.

Audio requires a connection for first play unless downloaded. Native
streaming and lock-screen controls are not covered by widget tests;
background audio controls remain a future phase.
