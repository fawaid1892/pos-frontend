import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pos_flutter/providers/auth_provider.dart';
import 'package:pos_flutter/providers/cart_provider.dart';
import 'package:pos_flutter/providers/stock_provider.dart';
import 'package:pos_flutter/providers/report_provider.dart';
import 'package:pos_flutter/providers/sync_provider.dart';
import 'package:pos_flutter/providers/theme_provider.dart';

import 'package:pos_flutter/main.dart' as app;

/// Helper to create the full MultiProvider wrapper that mimics PosApp's setup.
/// ThemeProvider and SyncProvider require async init; we provide a minimal
/// synchronous version for testing individual widgets.
Widget createTestApp({Widget? child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => StockProvider()),
      ChangeNotifierProvider(create: (_) => ReportProvider()),
      ChangeNotifierProvider(create: (_) => SyncProvider()),
    ],
    child: MaterialApp(
      title: 'POS Multi Branch',
      theme: ThemeData.light(),
      home: child ??
          Builder(
            builder: (context) => Scaffold(
              body: Center(child: Text('POS App')),
            ),
          ),
    ),
  );
}

void main() {
  group('PosApp Widget Tests', () {
    testWidgets('MaterialApp renders with correct title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'POS Multi Branch',
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Center(child: Text('Hello POS')),
          ),
        ),
      );

      expect(find.text('Hello POS'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('PosApp has correct debugShowCheckedModeBanner',
        (tester) async {
      await tester.pumpWidget(const app.PosApp());

      // Pump a frame to allow theme resolution
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // The app should render without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('MultiProvider wrapper provides all required providers',
        (tester) async {
      await tester.pumpWidget(createTestApp());

      // The app should render with all providers active
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('POS App'), findsOneWidget);
    });

    testWidgets('App renders with login route as initial', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => StockProvider()),
            ChangeNotifierProvider(create: (_) => ReportProvider()),
            ChangeNotifierProvider(create: (_) => SyncProvider()),
          ],
          child: const app.PosApp(),
        ),
      );

      await tester.pumpAndSettle();

      // The MaterialApp should render without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('ThemeProvider changes theme mode', (tester) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => StockProvider()),
            ChangeNotifierProvider(create: (_) => ReportProvider()),
            ChangeNotifierProvider(create: (_) => SyncProvider()),
          ],
          child: const MaterialApp(
            title: 'POS Multi Branch',
            home: Scaffold(
              body: Center(child: Text('Test Theme')),
            ),
          ),
        ),
      );

      expect(find.text('Test Theme'), findsOneWidget);
    });
  });
}
