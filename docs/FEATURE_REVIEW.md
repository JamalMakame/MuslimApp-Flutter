# Deen — feature review: how each feature works and how to complete it

Written November 2026, against `main` after the store-release merge
(PR #8). Each section covers **how it works today** (with files),
**limits**, and **improvements**, marked **S/M/L** for small/medium/large
effort. A prioritised plan is at the end.

`FEATURES.md` is the short reference of what the app does; this document
explains the internals and what is missing.

---

## 1. Quran: navigation ("start anywhere")

### How it works today
- **Data.** `QuranService.load()` reads three bundled files at boot
  (`quran_ar_uthmani.json`, `quran_en_sahih.json`, `quran_sw_barwani.json`)
  into per-surah lists. Each ayah in the JSON already carries `juz`,
  `page` (604-page Madani mushaf), `hizbQuarter`, `manzil`, `ruku` and
  `sajda`. `quran_meta.json` also lists the start ayah of every juz (30),
  hizb quarter (240), page (604), ruku (556) and manzil (7), plus the
  15 sajdas. **`Ayah.fromJson` keeps only `juz`, `page` and `sajda`.**
- **Entry points into the reader (`/reader/:surah?ayah=n`):**
  1. Quran index → tap a surah → opens at ayah 1.
  2. Search → "Ayat" segment → a result, or typing `2:255` → opens at that
     ayah, scrolls to it and highlights it (`ReaderController.initialAyah`,
     `scrollToAyah`).
  3. "Continue reading" card → last saved surah/ayah. The position is saved
     when scrolling stops (`saveVisiblePosition`, Arabic and translation
     anchors).
  4. Hifz (`/memorize/:surah`) opens at the last ayah *practised* in that
     surah (`kMemPosition`), not at a chosen ayah.
- **Reader layout.** The whole surah is one `ListView` with a single
  `Text.rich` holding every ayah (Arabic flow with medallions), followed by
  every translation. All ayahs are built at once, which is what makes
  `Scrollable.ensureVisible` work.
- **Bookmarks** are per **surah** (`kBookmarks: Set<surah>`), not per ayah.
- **Audio in the reader** streams the full-surah Alafasy MP3 from
  mp3quran and always starts at 0:00.

### Limits
- There is no "Go to…" control: no way to pick surah + ayah, juz, hizb or
  page without knowing to type `2:255` in the search box.
- No Juz / Hizb / Page browsing. The index has a single hard-coded
  "Juz 30" divider; the reader's Juz/Page chips show the surah's
  *starting* juz/page, not the current one.
- Reading stops at the end of a surah: no "next surah" / "previous surah",
  so a juz that spans surahs can't be read in one go.
- Tapping an ayah does nothing except the TAFSIR link. There is no menu to
  copy, share, bookmark, play from this ayah or memorise from this ayah.
- Surah audio can't start at a chosen ayah and doesn't highlight the ayah
  being recited (the surah MP3 has no timing data).
- Only one "last read", and bookmarks can't point to an ayah or carry a
  note.
- Long surahs: one `Text.rich` for 286 ayahs (Al-Baqarah) is heavy on
  low-end phones and can't be lazily built.

### Improvements
| # | Improvement | Effort |
|---|---|---|
| Q1 | **"Go to" sheet** reachable from the index and reader: surah picker + ayah number (validated against the surah's count), or juz 1–30, hizb 1–60 (with quarters), or page 1–604. Each resolves to `(surah, ayah)` with the bundled start tables and opens `/reader/s?ayah=a`. | S |
| Q2 | **Keep the missing ayah fields** (`hizbQuarter`, `manzil`, `ruku`) in `Ayah` and add `QuranService.juzStart(n)`, `hizbStart(n)`, `pageStart(n)`, `locate(surah, ayah)`. No new assets. | S |
| Q3 | **Juz tab in the Quran index** (Surahs / Juz / Ayat): 30 juz with their start ayah and Arabic opening words, expandable into hizb quarters. | M |
| Q4 | **Live position chips:** the reader's Juz / Page / Hizb chips follow the ayah at the reading line; a thin marker appears where a juz or hizb starts inside a surah. | S |
| Q5 | **Ayah action menu** (long-press an ayah or its medallion): copy (Arabic + translation + reference), share, bookmark, play from here, memorise from here (opens Hifz at that ayah), tafsir. | M |
| Q6 | **Ayah bookmarks with optional note and colour**, a Bookmarks screen, and migration of today's surah bookmarks to ayah 1 of that surah. | M |
| Q7 | **Next / previous surah** buttons at the end and start of the reader, plus a **continuous reading** mode that loads the following surah under the current one (needed for reading a juz). | M |
| Q8 | **Play from any ayah with highlight:** in the reader, use the per-ayah CDN audio that Hifz already uses (`ayahAudioUrl`), chain ayah to ayah, highlight and auto-scroll the ayah being recited, and play downloaded files when available. The full-surah stream stays as a fallback. | M |
| Q9 | **Lazy reader:** render one block per ayah (Arabic + translation) in a `ListView.builder` / `scrollable_positioned_list`, so jumping to ayah 280 doesn't build 280 ayahs first. This is required for Q7 and makes Q4/Q8 simple. | M |
| Q10 | **Mushaf page mode:** swipe through the 604 pages using the bundled `page` field, with the page number and juz in the header. Text-based (no images), so it reflows with text size. | L |
| Q11 | **Deep links:** `deen://quran/2/255`, so shared ayahs and reminders open the exact place. | S |
| Q12 | **Reading history:** the last 10 places read, not only one. | S |

---

## 2. Quran: search

**Today.** `QuranService.searchAyahs` builds an in-memory index on first
use: normalised Uthmani (harakat stripped, alef/ya/ta-marbuta folded), an
alef-free "skeleton" form and a Uthmani-waw form, plus lower-cased English
and Swahili. Arabic queries match the Arabic; Latin queries match the
translations, preferring the UI language. `2:255` (Western or Arabic-Indic
digits) jumps to that ayah. Results are capped at 80, in mushaf order.
Surah-name search is a separate filter in `QuranController.visibleSurahs`.

**Limits.** No ranking (Al-Fatihah results always come first); no
highlighting of the matched words in Arabic; no multi-word "all words"
matching (the query is matched as one phrase); no root search; no search
history; `2:255-260` ranges and "juz 5" / "page 300" aren't understood.

**Improvements.**
- S1 Understand `juz 5`, `page 300`, `hizb 12` and `2:255-260` in the
  search box (reuses Q2). **S**
- S2 All-words matching, then rank exact phrase matches first. **S**
- S3 Highlight the matched words in Arabic and translation results. **M**
- S4 Recent searches and "search in this surah" from the reader. **S**
- S5 Arabic root search (needs a bundled morphology table, ~1 MB). **L**

---

## 3. Quran: translations and tafsir

**Today.** English (Sahih International) and Swahili (Al-Barwani) are
bundled; the reader shows them after the Arabic. Tafsir is Ibn Kathir from
api.quran.com (Arabic edition 14 for Arabic UI, abridged English 169
otherwise; Swahili users get English), fetched per ayah and cached in
`get_storage`.

**Limits.** The translation appears only after the full Arabic, not
ayah by ayah. Tafsir is online-only until it has been opened once, and
there is no Swahili tafsir. There is no word-by-word or transliteration.

**Improvements.**
- T1 **Interleaved layout** option: each ayah followed by its translation
  (comes with Q9). **S** once Q9 exists.
- T2 Download tafsir for a whole surah for offline use. **M**
- T3 Transliteration line (bundled, ~1.5 MB). **M**
- T4 Word-by-word meanings on tap (bundled wbw data, ~6 MB). **L**
- T5 More translations as optional downloads (e.g. Pickthall, Yusuf Ali,
  a second Swahili), after checking licences. **M**

---

## 4. Quran: audio and Hifz (memorisation)

**Today.**
- Reader: one surah MP3 (Alafasy, mp3quran) with play/pause, seek and
  speed. Playback stops when the reader closes; no lock-screen controls.
- Hifz (`MemorizeController`): per-ayah playback from cdn.islamic.network
  with four reciters, repeat N times, auto-advance, speed, prev/next,
  position saved per surah. Whole-surah download with resume and size
  check (`AudioCacheService`); playback prefers the local file.

**Limits.** Hifz covers one surah at a time, starting from the saved ayah:
no **from ayah X to ayah Y** range, no "repeat the range", no gap between
repeats, and no hide-the-text self-test. Reciter choice in Hifz and the
reader are separate (the reader is always Alafasy). No background/lock
screen audio.

**Improvements.**
- H1 **Range practice:** pick start and end ayah (and "start here" from the
  reader's ayah menu, Q5); repeat each ayah N times, then the whole range
  M times. **M**
- H2 **Self-test mode:** hide the text, reveal word by word or ayah by
  ayah, and mark "memorised" / "needs review". **M**
- H3 **Memorisation progress:** ayahs/surahs marked memorised, with a
  simple spaced-review list ("review today"). **M**
- H4 **One reciter setting** used by the reader and Hifz, with a pause
  option between repeats. **S**
- H5 **Background and lock-screen audio** (`audio_service` +
  `just_audio`), for both the reader and Hifz. **L**

---

## 5. Reading habits (new)

Nothing tracks reading beyond "last read" today.
- R1 **Khatmah planner:** choose to finish in N days; the app splits the
  Quran by pages and shows today's portion with a "Start" button that
  opens the reader at the right ayah (uses Q1/Q2). **M**
- R2 **Daily reading goal and streak** (pages or ayahs per day), shown on
  Home next to the prayer card. **S**
- R3 **Optional daily reminder** to read, using the existing notification
  service. **S**

---

## 6. Prayer times and reminders

**Today.** `PrayerService` computes the six times with `adhan` for the
saved coordinates. Methods: Umm al-Qura (default), MWL, Egypt, Karachi,
ISNA; Shafi'i or Hanafi Asr. Home recomputes every 30 s and on settings
changes. `PrayerReminderController` schedules one-shot notifications for
the next 7 days (≤ 35, under iOS's limit of 64), exact on Android when
allowed. Location comes from GPS or a typed city (`geocoding`).

**Phase 4 (built).** 12 methods (adds Dubai, Kuwait, Qatar, Singapore,
Diyanet, Tehran, Moonsighting Committee), a high-latitude rule, per-prayer
± minutes, per-prayer reminders (off, at the time, or 5–30 min before),
morning/evening azkar reminders 20 min after Fajr/Asr, a shareable
monthly timetable, and a "you've moved" prompt (> 30 km, GPS only).
Still open: P3 adhan sound, P6 widget.

**Limits before phase 4.** No high-latitude rule, no per-prayer minute adjustments,
fewer methods than users expect (Tehran, Gulf, Kuwait, Qatar, Singapore,
Turkey, Moonsighting Committee are missing), and no per-prayer reminder
on/off switch or "N minutes before" option. The adhan sound is the system
default. There is no monthly timetable. Location doesn't update when the
user travels unless they change it.

**Improvements.**
- P1 **More methods + high-latitude rule + per-prayer minute offsets**
  (all supported by `adhan`). **S**
- P2 **Per-prayer reminders:** on/off for each prayer and "at time" or
  "N minutes before". **S**
- P3 **Adhan sound** choice for reminders (bundled short adhan, Android
  channel sound and iOS sound file under 30 s). **M**
- P4 **Monthly timetable** screen, shareable. **S**
- P5 **"You've moved" prompt:** when GPS is the source and the position
  is more than ~30 km from the saved one on app open, offer to update.
  **S**
- P6 **Home-screen widget** for the next prayer (`home_widget`). **L**

---

## 7. Qibla

**Today.** `QiblaController` combines `flutter_compass` heading with the
great-circle bearing to the Kaaba from the saved location, shows distance
to Makkah and an accuracy chip from the sensor's reported accuracy, and
falls back to the bearing in degrees when there's no compass.

**Improvements.** Q-a: vibrate and turn the needle gold when aligned
within ±3°. **S** Q-b: a figure-8 calibration animation when accuracy is
low. **S** Q-c: an optional camera/map view. **L**, low priority.

---

## 8. Azkar

**Today.** `azkar.json` has 39 Arabic categories with 170 items. Ten are
mapped into display buckets (`AzkarService.mapping`: morning, evening,
after prayer, sleep, waking, adhan, travel, ruqyah ×2, gratitude); the
other 25 or so fall into "Other". Each item has Arabic, a reference and a
repeat count; the detail screen counts taps, auto-advances and saves
today's progress per bucket.

**Limits.** Arabic only: no translation or transliteration, which
matters for English and Swahili users. "Other" hides useful categories
(istighfar, salawat, hajj/umrah, illness, fear). There are no favourites
and no morning/evening reminders.

**Improvements.**
- A1 **English translation + transliteration** for the morning, evening,
  after-prayer and sleep sets first (curated content), then Swahili. **M**
  (content work, not code)
- A2 **Split "Other"** into named buckets: Istighfar, Salawat, Hajj &
  Umrah, Illness & distress, Daily manners. **S**
- A3 **Morning/evening azkar reminders** after Fajr and Asr, using the
  prayer times. **S**
- A4 **Favourites** and a "My azkar" list. **S**

---

## 9. Tasbeeh

**Today.** Five phrases, targets 33 or 100, lap counting, daily total,
streak and haptics, all saved.

**Improvements.** T-a: custom phrase and custom target. **S** T-b: the
after-prayer sequence (33 / 33 / 34 with automatic phrase switch). **S**
T-c: history of daily totals for the last 30 days. **S**

---

## 10. Calendar

**Today.** A Hijri/Gregorian month grid using the `hijri` package (Umm
al-Qura) with a saved −2…+2 day adjustment, White Days, and ten fixed
occasions (`CalendarController._fixed`) with days-until.

**Improvements.** C-a: reminders for occasions and White-Days fasting.
**S** C-b: tap a day to see its prayer times. **S** C-c: a note that the
dates are calculated, with a link to the adjustment. **S**

---

## 11. Home, daily cards and settings

**Today.** Home shows the next-prayer countdown, the day's times, Qibla,
Hadith of the Day (16 bundled hadith rotating by date), Dua of the Day
(from real supplications in azkar) and both dates. Settings cover
language, theme, text size, translations, reciter and data clearing.

**Improvements.**
- D1 **Ayah of the Day** card that opens the reader at that ayah (uses the
  "start anywhere" path). **S**
- D2 Show the **Continue reading** card on Home too. **S**
- D3 **Hadith library:** start with An-Nawawi's 40 (ar/en/sw), searchable,
  replacing the 16-item rotation. **M** (content + licence)
- D4 Backup and restore of bookmarks, notes and progress to a file. **M**

---

## 12. Quality and release

- No CI: add a GitHub Actions workflow running format, analyze and tests
  on each PR. **S**
- No crash reporting: Sentry for Flutter, with consent wording added to
  the privacy policy. **S**
- `integration_test/` isn't run anywhere automatically. **S** to add to
  CI on an emulator; **M** to keep green.

---

## Prioritised plan

Ordered by what users will feel most, with "start anywhere" first. Each
phase is one branch and one PR.

Phase 1 is built: Go to sheet, search shortcuts, live chips, `deen://quran`
links, Ayah of the Day and Continue reading on Home. It also fixed sajda
ayahs, which were never marked because the corpus stores `sajda` as an
object, not `true`.

Phase 2 is built: lazy per-ayah reader with the translation under each
ayah, the ayah menu, ayah bookmarks with notes and a Bookmarks screen,
previous / next surah and the Juz tab. "Play from here" (ayah-by-ayah
audio with highlight, the core of Q8) came with the menu. Continuous
reading across surahs (rest of Q7) is not built; the footer's next-surah
button covers it for now.

Phase 3 is built: one reciter setting (H4), Hifz range with repeats (H1)
and background / lock-screen audio through `audio_service` (H5) for the
reader and Hifz. Audio still stops when you leave the reader or Hifz
screen; a pause between repeats (rest of H4) is not built.

| Phase | Contents | Why first |
|---|---|---|
| **1. Start anywhere** | Q2 data, Q1 Go-to sheet, S1 search shortcuts, Q4 live chips, Q11 deep links, D1 Ayah of the Day, D2 Continue on Home | Small changes on existing data; every later feature reuses `locate()` and the Go-to path |
| **2. Ayah-level reader** | Q9 lazy per-ayah reader, T1 interleaved translation, Q5 ayah menu, Q6 ayah bookmarks + notes, Q7 next/previous surah and continuous reading, Q3 Juz tab | Q9 is the base for the rest; this makes the reader feel complete |
| **3. Listen from anywhere** | Q8 play from any ayah with highlight, H4 one reciter setting, H1 range Hifz, H5 background/lock-screen audio | Audio is the most requested gap after navigation |
| **4. Prayer completeness** | P1 methods/high-latitude/offsets, P2 per-prayer reminders, P5 moved prompt, P4 timetable, A3 azkar reminders | Needed for users outside East Africa and the Gulf |
| **5. Habits and memorisation** | R1 khatmah planner, R2 goal/streak, R3 reminder, H2 self-test, H3 progress | Builds on phases 1–3 |
| **6. Content** | A1 azkar translations, A2 split Other, D3 Nawawi 40, T2 offline tafsir, T3 transliteration | Mostly curation and licence checks, can run alongside |
| **7. Platform** | CI, crash reporting, P6 widget, Q10 page mode, P3 adhan sound | Larger or optional |
