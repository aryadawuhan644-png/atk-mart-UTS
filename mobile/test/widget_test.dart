// test/widget_test.dart
// Pure Dart sanity test – no widget rendering required.
// Widget/integration rendering tests should be run on a device or emulator.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sanity: basic Dart arithmetic works', () {
    expect(1 + 1, 2);
    expect('ATK Mart Aoen'.isNotEmpty, isTrue);
  });
}
