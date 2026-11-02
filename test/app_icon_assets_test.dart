import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> checkPng(String path, int size, int colorType) async {
    final bytes = await File(path).readAsBytes();
    expect(bytes.sublist(0, 8), [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
    ], reason: path);
    final header = ByteData.sublistView(bytes);
    expect(header.getUint32(16), size, reason: path);
    expect(header.getUint32(20), size, reason: path);
    expect(bytes[25], colorType, reason: '$path PNG alpha format');
    return bytes;
  }

  Future<ByteData> decodedPixels(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    frame.image.dispose();
    codec.dispose();
    return data!;
  }

  test('all iOS catalog entries are square, sized and alpha-free', () async {
    const folder = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final catalog =
        jsonDecode(await File('$folder/Contents.json').readAsString())
            as Map<String, dynamic>;
    final images = catalog['images'] as List<dynamic>;
    expect(images, hasLength(greaterThanOrEqualTo(15)));
    expect(
      images.where((image) => image['idiom'] == 'ios-marketing'),
      hasLength(1),
    );
    for (final entry in images) {
      final image = entry as Map<String, dynamic>;
      final points = double.parse((image['size'] as String).split('x')[0]);
      final scale = double.parse(
        (image['scale'] as String).replaceAll('x', ''),
      );
      final pixels = (points * scale).round();
      await checkPng('$folder/${image['filename']}', pixels, 2);
    }
    await checkPng('design/app-icon-play-store.png', 512, 2);
    await checkPng('assets/branding/app_icon.png', 1024, 2);
    final config = await File('pubspec.yaml').readAsString();
    expect(config, contains('ios: false'));
    final project = await File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsString();
    expect(
      project,
      isNot(
        contains(
          'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;',
        ),
      ),
    );
  });

  test(
    'Android legacy, adaptive and themed icons cover all densities',
    () async {
      const res = 'android/app/src/main/res';
      for (final (density, legacySize, adaptiveSize) in [
        ('mdpi', 48, 108),
        ('hdpi', 72, 162),
        ('xhdpi', 96, 216),
        ('xxhdpi', 144, 324),
        ('xxxhdpi', 192, 432),
      ]) {
        await checkPng('$res/mipmap-$density/ic_launcher.png', legacySize, 2);
        await checkPng(
          '$res/drawable-$density/ic_launcher_foreground.png',
          adaptiveSize,
          6,
        );
        await checkPng(
          '$res/drawable-$density/ic_launcher_monochrome.png',
          adaptiveSize,
          6,
        );
      }

      final foreground = await checkPng(
        '$res/drawable-mdpi/ic_launcher_foreground.png',
        108,
        6,
      );
      final mono = await checkPng(
        '$res/drawable-mdpi/ic_launcher_monochrome.png',
        108,
        6,
      );
      for (final bytes in [foreground, mono]) {
        final pixels = await decodedPixels(bytes);
        int alpha(int x, int y) => pixels.getUint8((y * 108 + x) * 4 + 3);
        expect(alpha(0, 0), 0);
        expect(alpha(54, 54), 255);
        for (var y = 0; y < 108; y++) {
          for (var x = 0; x < 108; x++) {
            if (alpha(x, y) == 0) continue;
            // Android's adaptive icon XML insets this 108dp layer by 16%.
            final dx = (x - 54) * 0.68;
            final dy = (y - 54) * 0.68;
            final distanceSquared = dx * dx + dy * dy;
            expect(
              distanceSquared,
              lessThan(33 * 33),
              reason: 'Adaptive mark escapes the Android safe circle',
            );
          }
        }
      }
      final monoPixels = await decodedPixels(mono);
      for (var channel = 0; channel < 4; channel++) {
        expect(monoPixels.getUint8((54 * 108 + 54) * 4 + channel), 255);
      }
    },
  );

  test('Android resolves its launcher and calls the app Deen', () async {
    const res = 'android/app/src/main/res';
    final manifest = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();
    expect(manifest, contains('android:label="Deen"'));
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    final xml = await File(
      '$res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsString();
    expect(xml, contains('<adaptive-icon'));
    expect(xml, contains('@color/ic_launcher_background'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('@drawable/ic_launcher_monochrome'));
    expect(xml, contains('android:inset="16%"'));
    final background = await File('$res/values/colors.xml').readAsString();
    expect(background, contains('#0E6B5C'));

    final config = await File('pubspec.yaml').readAsString();
    expect(config, contains('image_path: "assets/branding/app_icon.png"'));
    expect(
      config,
      contains(
        'adaptive_icon_foreground: '
        '"assets/branding/app_icon_foreground.png"',
      ),
    );
    expect(
      config,
      contains(
        'adaptive_icon_monochrome: '
        '"assets/branding/app_icon_monochrome.png"',
      ),
    );
    for (final name in [
      'app_icon.svg',
      'app_icon_foreground.svg',
      'app_icon_monochrome.svg',
    ]) {
      final vector = await File('assets/branding/$name').readAsString();
      expect(vector, contains('fill-rule="evenodd"'));
      expect(vector, contains('M 274.00 248.00'));
    }
  });
}
