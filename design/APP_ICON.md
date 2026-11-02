# Deen app icon

The launcher icon uses a gold mihrab (prayer niche) and eight-point star on a
deep emerald surface. It echoes the geometry and palette of the Deen splash,
but omits the wordmark and fine lines so the symbol survives launcher sizes.
The full-bleed square has no baked-in corner radius: iOS applies its own mask.

Preview: [`app-icon-preview.png`](app-icon-preview.png) (left: iOS; right:
Android's circular adaptive mask and monochrome treatment). The 512px
[`app-icon-play-store.png`](app-icon-play-store.png) is ready for Play Console.

## Native outputs

- **iOS:** All iPhone/iPad/marketing sizes listed in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`, including an
  opaque 1024px App Store icon. PNGs are RGB (no alpha channel).
- **Android 24-25:** Legacy PNGs at mdpi through xxxhdpi.
- **Android 26+:** Adaptive icon XML uses an emerald background with a
  transparent gold foreground inset by 16%. The mark, including its baseline,
  stays inside the central 66dp safe circle for circular launcher masks.
- **Android 33+:** A white alpha-only monochrome layer lets the system tint the
  launcher icon with the user's chosen theme. The separate notification icon
  retains the existing splash dome.

The Swift vector geometry generates the SVG mirrors and PNG sources under
`assets/branding/`, plus every iOS catalog size. The existing
`flutter_launcher_icons` configuration exports Android icons from those PNGs.
Its iOS export is disabled because version 0.14.4 rewrites an unrelated
Xcode asset-symbol build setting.
Regenerate from the repository root:

```sh
swift design/generate_app_icons.swift
dart run flutter_launcher_icons
flutter test --no-pub test/app_icon_assets_test.dart
```

The release branch uses Gradle 8.14.3, Android Gradle Plugin 8.13.0 and
Flutter's supported minimum SDK (24). Android Studio on this Mac selects
Java 25; use the installed Temurin 21 locally:

```sh
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
android/gradlew -p android :app:assembleDebug
```

The Flutter CLI creates its ignored Gradle wrapper scripts on first build;
this project does not check those generated scripts into source control.
The release branch's `com.jamalmakame.deen` Android application ID is left
untouched by this icon change. It is separate from earlier
`com.example.quraan_app` installs and does not migrate their local data.

Changing an icon requires a native rebuild and often a full app reinstall or
launcher cache refresh to appear on a device; a Flutter hot reload will not
change the icon. Reinstalling an app can erase its locally stored data, so do
not uninstall Deen on a personal phone just to refresh the preview.
