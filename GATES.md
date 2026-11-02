# Gates: Deen Phase 2 calendar and memorization

Scope: Ship a truthful offline-first Hijri calendar and a working Quran memorization flow, preserving local data, en/ar/sw UI, and four-slot navigation.

- [x] G1: Calendar offsets preserve the real Gregorian date, grid alignment, and upcoming event order.
  CHECK: flutter test --no-pub test/calendar_test.dart && printf 'calendar checks passed\n'
  EXPECT: calendar checks passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=76e895ee719a5da9ff95e1fb6a592794c09a779269d13599d25a562a00067b81; exit=0; EXPECT=matched; output-sha256=0e2ee453771ccefa1ac2a4af010d7e594526ada419ed56c880ebccffdadc6513; output-bytes=694; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G2: Offline audio downloads survive interruptions without advertising partial files as complete, and playback loop transitions are correct.
  CHECK: flutter test --no-pub test/memorize_test.dart && printf 'audio checks passed\n'
  EXPECT: audio checks passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=70ff3c1bcef884f4e9118d2cdb8ce9c3d55a1eaf2ca8b779d964ad5b183d75c5; exit=0; EXPECT=matched; output-sha256=64075bb771baaee07a0524bdfb8d833837fee4d722a3e4582cf9a12961801933; output-bytes=898; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G3: Calendar and Hifz screens and navigation render without Flutter or GetX errors in English, Arabic and Swahili.
  CHECK: flutter test --no-pub test/phase2_widget_test.dart && printf 'widget checks passed\n'
  EXPECT: widget checks passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=8a950b0024ea273ac97b11de520cee8b41c40a65eb532e5ae882aa0248dcd57e; exit=0; EXPECT=matched; output-sha256=ef486ec8d8c4ec2580fdc6cf96097b51094bee0273edadd19a8b29aa663c27f8; output-bytes=391; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G4: Code formatting, static analysis, and existing unit/widget tests pass.
  CHECK: dart format --output=none --set-exit-if-changed lib/app test && flutter analyze --no-pub && flutter test --no-pub test && printf 'static checks passed\n'
  EXPECT: static checks passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=0c3c68bf7d669fcebeddee55a657fee35eb9e16d029a8788837220b5f52b4a52; exit=0; EXPECT=matched; output-sha256=0df1ab2ff6d87f97bad7771863429f3503bff8173bb5bafac5e855d853fb18b8; output-bytes=3223; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G5: Calendar and Hifz retain the approved design language without claiming observed moon sightings or offline audio until files are verified.
  EVIDENCE: Compared optional widget snapshots (DEEN_VISUAL_QA=true) with approved Stitch 12/13 PNGs; emerald/gold/ivory cards and four-slot nav carry through. UI says "Umm al-Qura estimate" and verifies cached files before displaying "downloaded"; it omits the mockup's unsupported "Sighting Confirmed", "Auto-sync enabled" and transliteration claims.

## iOS splash follow-up

- [x] G6: iOS opens on Deen's emerald and gold launch artwork instead of a white blank screen.
  CHECK: flutter test --no-pub test/splash_test.dart && printf 'splash regressions passed\n'
  EXPECT: splash regressions passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=63c3fa49012378190b4a0b818e185a1d1ec589b6bfb305f57f1493e5326f471e; exit=0; EXPECT=matched; output-sha256=fcf10082ee2af37d5fd80e0b0e0f5fb8c611ae68f6831d4873a3e880f2691413; output-bytes=606; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G7: Xcode compiles both updated native storyboards.
  CHECK: xcrun ibtool --errors --warnings --compile "$(mktemp -d)/LaunchScreen.storyboardc" ios/Runner/Base.lproj/LaunchScreen.storyboard && xcrun ibtool --errors --warnings --compile "$(mktemp -d)/Main.storyboardc" ios/Runner/Base.lproj/Main.storyboard && printf 'native storyboards compiled\n'
  EXPECT: native storyboards compiled
  EVIDENCE: automatic-evidence=v1; definition-sha256=dcf57716ab9d54e30a2f1ad668d2c753dae787149e9112ca56253984e2819ac8; exit=0; EXPECT=matched; output-sha256=676470c8b1448f8b579ac22fdbdbf344a77e1ba6b0a12651d6edd9466202ff7f; output-bytes=624; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G8: Splash changes preserve the existing app's formatting, analysis and unit/widget behavior.
  CHECK: dart format --output=none --set-exit-if-changed lib/app test && flutter analyze --no-pub && flutter test --no-pub test && printf 'splash suite passed\n'
  EXPECT: splash suite passed
  EVIDENCE: automatic-evidence=v1; definition-sha256=a33743605b5f4f908e1ef5a4684b3fad6f642cfc6b72973767bb18f2dbd39cf2; exit=0; EXPECT=matched; output-sha256=df21810490315437a562a2e198538728d4034bc9e0cba193763912d93e6937e2; output-bytes=3960; shell=/bin/sh; cwd=/Users/jamalmakame/Developer/MuslimApp-Flutter; path=9348647a42d1/32 entries

- [x] G9: Compare native and Flutter splash composition against the approved design on narrow and full-size phone layouts.
  EVIDENCE: Reviewed the 208pt native transparent Deen mark, both compiled native storyboards and Flutter widget snapshots at 393x852 and 320x568 in en/ar/sw. The gradient fills the viewport, mark and wordmark are centered, Arabic remains RTL, status bar text is light and both native backdrops are emerald. Physical-iPhone launch still needs a visual check.

## Offline Quran search

- [ ] G10: Search the bundled Quran without HTTP across Arabic and both translations, including diacritics, exact verse references, deduplication and result limits.
  CHECK: flutter test --no-pub test/quran_search_test.dart && printf 'offline corpus search passed\n'
  EXPECT: offline corpus search passed
  EVIDENCE: pending

- [ ] G11: The Quran index searches without stale state, distinguishes empty queries from no matches and opens the selected ayah in the reader across en/ar/sw phone layouts.
  CHECK: flutter test --no-pub test/quran_search_widget_test.dart && printf 'offline search UI passed\n'
  EXPECT: offline search UI passed
  EVIDENCE: pending

- [ ] G12: Offline search preserves format, analysis and all existing unit/widget tests.
  CHECK: dart format --output=none --set-exit-if-changed lib/app test && flutter analyze --no-pub && flutter test --no-pub test && printf 'offline search suite passed\n'
  EXPECT: offline search suite passed
  EVIDENCE: pending

- [ ] G13: EN/AR/SW phone views retain the approved Quran index visual language, readable match sources, Arabic RTL and honest offline/limited-result copy.
  EVIDENCE: pending

## Deen launcher icon

- [ ] G14: All referenced iOS and Android launcher assets have valid sizes, transparency, and an adaptive safe zone; Android shows Deen.
  CHECK: flutter test --no-pub test/app_icon_assets_test.dart && printf 'launcher resources valid\n'
  EXPECT: launcher resources valid
  EVIDENCE: pending

- [ ] G15: The iOS simulator app compiles with the updated AppIcon catalog.
  CHECK: xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath "$(mktemp -d /tmp/deen-icon-gate-ios.XXXXXX)" CODE_SIGNING_ALLOWED=NO build -quiet && printf 'iOS launcher compiled\n'
  EXPECT: iOS launcher compiled
  EVIDENCE: pending

- [ ] G16: The Android debug APK packages Deen's adaptive and monochrome launcher icons without changing release configuration.
  CHECK: cd android && JAVA_HOME=$(/usr/libexec/java_home -v 21) ./gradlew :app:assembleDebug && "$HOME/Library/Android/sdk/build-tools/36.0.0/aapt2" dump badging ../build/app/outputs/apk/debug/app-debug.apk | grep -F "application-label:'Deen'" && "$HOME/Library/Android/sdk/build-tools/36.0.0/aapt2" dump resources ../build/app/outputs/apk/debug/app-debug.apk | grep -F 'drawable/ic_launcher_monochrome' && printf 'Android launcher compiled\n'
  EXPECT: Android launcher compiled
  EVIDENCE: pending

- [x] G17: The mihrab-star mark remains legible at launcher sizes and Android circular/themed masks do not crop it.
  EVIDENCE: Inspected design/app-icon-preview.png at 60/40/29px and the 1024px iOS and 512px Play Store exports; Android's 16% adaptive inset and decoded alpha bounds are covered in test/app_icon_assets_test.dart. User chose mihrab-star over the already-merged dome icon.
