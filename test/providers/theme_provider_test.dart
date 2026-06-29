import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    test('initial theme mode is light', () {
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('toggleTheme switches from light to dark', () async {
      expect(themeProvider.isDarkMode, false);

      await themeProvider.toggleTheme();

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
    });

    test('toggleTheme switches from dark to light', () async {
      // Start from dark
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);

      // Toggle back
      await themeProvider.toggleTheme();

      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('toggleTheme toggles back and forth', () async {
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);

      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, false);

      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);
    });

    test('setThemeMode sets light mode', () async {
      await themeProvider.setThemeMode(ThemeMode.light);

      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('setThemeMode sets dark mode', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
    });

    test('setThemeMode sets system mode', () async {
      await themeProvider.setThemeMode(ThemeMode.system);

      expect(themeProvider.themeMode, ThemeMode.system);
      expect(themeProvider.isDarkMode, false); // system != dark
    });

    test('notifies listeners on toggle', () async {
      int notifyCount = 0;
      themeProvider.addListener(() {
        notifyCount++;
      });

      await themeProvider.toggleTheme();

      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('notifies listeners on setThemeMode', () async {
      int notifyCount = 0;
      themeProvider.addListener(() {
        notifyCount++;
      });

      await themeProvider.setThemeMode(ThemeMode.dark);

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });
}
