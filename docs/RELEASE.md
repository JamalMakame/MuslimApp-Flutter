# Releasing Deen to Google Play and the App Store

App ID on both stores: **`com.jamalmakame.deen`**, display name **Deen**.
The ID can never change after the first upload.

Privacy policy URL for both store listings (the repo is public):
https://github.com/JamalMakame/MuslimApp-Flutter/blob/main/docs/PRIVACY.md

## Version

Bump `version:` in `pubspec.yaml` before every upload: `1.0.1+2` means the
version name 1.0.1 and build number 2. Both stores refuse a build number they
have already seen.

## Android

### One-time: the upload key

Create it once and back it up (password manager plus an offline copy). If
you lose it, Play has to reset it, which takes days.

```sh
keytool -genkey -v -keystore ~/keys/deen-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (gitignored, never commit it):

```properties
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=upload
storeFile=/Users/<you>/keys/deen-upload.jks
```

Without this file a release build is signed with the debug key; it installs
on a phone but Play rejects it. Enrol in Play App Signing when you create the
app (Google keeps the real signing key; yours is only the upload key).

### Build and upload

Gradle 8.14 runs on JDK 17–24; Android Studio's bundled JDK 25 fails with
"incompatible with Gradle". Point Flutter at JDK 21 once:

```sh
flutter config --jdk-dir=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
```

```sh
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console
(internal testing first, then production).

### Play Console forms

- **Data safety:** location is collected? No — it is processed on the device
  only and never leaves it except to the OS geocoder. No data shared, no
  account, data can be deleted in the app. Encrypted in transit: yes (HTTPS).
- **Exact alarms:** the app declares `SCHEDULE_EXACT_ALARM` so prayer
  reminders fire on time. If the declaration is refused, remove it from
  `AndroidManifest.xml`; reminders then fall back to inexact alarms and can be
  a few minutes late.
- **Content rating, target audience (all ages), ads (none), app access (no
  login).**
- Store listing: short and full description in English, Arabic and Swahili,
  512×512 icon (`assets/branding/app_icon.png` scaled), 1024×500 feature
  graphic, at least 2 phone screenshots.

## iOS

### One-time

- Apple Developer Program membership (paid yearly).
- In App Store Connect create the app with bundle ID `com.jamalmakame.deen`.
- In Xcode, open `ios/Runner.xcworkspace`, select Runner → Signing &
  Capabilities, tick "Automatically manage signing" and choose your team.

### Build and upload

```sh
flutter build ipa --release
```

Then upload `build/ios/ipa/*.ipa` with Xcode's Organizer or the Transporter
app, test it in TestFlight, and submit for review.

### App Store Connect forms

- **App Privacy:** "Data Not Collected" (location is used on the device only).
- **Export compliance:** already answered in `Info.plist`
  (`ITSAppUsesNonExemptEncryption = NO`; the app only uses HTTPS).
- Age rating, category (Reference or Lifestyle), screenshots for 6.9" and
  6.5" iPhones (and iPad, since the app runs on iPad).

## Before each release

```sh
dart format --output=none --set-exit-if-changed lib/app test
flutter analyze
flutter test
```

Then on a real phone: prayer reminders arrive with the app closed, the Qibla
compass turns, audio downloads, dark mode, all three languages.

## App icon

The source is `assets/branding/app_icon.svg` (plus the adaptive foreground and
monochrome layers next to it). After changing the PNGs, regenerate every size:

```sh
dart run flutter_launcher_icons
```
