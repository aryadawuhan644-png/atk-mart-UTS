import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atkmart_mobile/main.dart';
import 'package:atkmart_mobile/theme/app_theme.dart';

void main() {
  test('uses the vibrant blue palette with balanced supporting colors', () {
    final theme = AppTheme.light;

    expect(AppColors.primary, const Color(0xFF011C6B));
    expect(AppColors.accent, const Color(0xFF007F87));
    expect(AppColors.accentWarm, const Color(0xFFA85D00));
    expect(AppColors.warning, const Color(0xFFA85D00));
    expect(AppColors.accentEarth, const Color(0xFF955A0B));
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.accent);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.dividerColor, AppColors.border);
  });

  testWidgets('product form switches remain tappable on decorated cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const FormProdukPage()),
    );
    await tester.pumpAndSettle();

    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(2));
    await tester.ensureVisible(switches.first);
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
