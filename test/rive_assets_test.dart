import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled Rive files are runtime v7 files', () {
    for (final name in ['splash', 'celebration', 'empty']) {
      final bytes = File('assets/rive/$name.riv').readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'RIVE', reason: name);
      expect(bytes[4], 7, reason: '$name major version');
    }
  });
}
