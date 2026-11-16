import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LC Lab 其他 App 圖示在 assets 裡，且已列入 pubspec', () {
    expect(File('assets/other_apps/tarot.png').existsSync(), isTrue);
    expect(File('assets/other_apps/english.png').existsSync(), isTrue);
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/other_apps/'));
  });
}
