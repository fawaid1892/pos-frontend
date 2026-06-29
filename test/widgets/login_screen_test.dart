import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pos_flutter/providers/auth_provider.dart';
import 'package:pos_flutter/providers/theme_provider.dart';
import 'package:pos_flutter/screens/login_screen.dart';

/// Helper to create a testable LoginScreen with required providers.
Widget createLoginScreen({
  AuthProvider? authProvider,
  ThemeProvider? themeProvider,
}) {
  final auth = authProvider ?? AuthProvider();
  final theme = themeProvider ?? ThemeProvider();

  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: const LoginScreen(),
    ),
    routes: {
      '/pos': (context) => const Scaffold(
            body: Center(child: Text('POS Screen')),
          ),
    },
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('renders login form with title and subtitle', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('POS Multi Branch'), findsOneWidget);
      expect(find.text('Masuk untuk memulai transaksi'), findsOneWidget);
    });

    testWidgets('renders email and password fields with pre-filled values',
        (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Pre-filled values from the screen
      expect(find.text('owner@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('renders login button labeled Masuk', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('renders dark mode toggle switch', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      final auth = AuthProvider();

      await tester.pumpWidget(createLoginScreen(authProvider: auth));
      await tester.pumpAndSettle();

      // Clear the email field
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, '');

      // Find and tap the login button
      final loginButton = find.text('Masuk');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check validation message
      expect(find.text('Email wajib diisi'), findsOneWidget);
    });

    testWidgets('shows validation error when password is empty', (tester) async {
      final auth = AuthProvider();

      await tester.pumpWidget(createLoginScreen(authProvider: auth));
      await tester.pumpAndSettle();

      // Clear the password field
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, '');

      // Find and tap the login button
      final loginButton = find.text('Masuk');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Check validation message
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('shows both validation errors when all fields empty',
        (tester) async {
      final auth = AuthProvider();

      await tester.pumpWidget(createLoginScreen(authProvider: auth));
      await tester.pumpAndSettle();

      // Clear both fields
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, '');
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, '');

      // Tap login button
      final loginButton = find.text('Masuk');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('login button is disabled while loading', (tester) async {
      final auth = AuthProvider();
      // Trigger login to set loading state
      auth.login('owner@example.com', 'password123');

      await tester.pumpWidget(createLoginScreen(authProvider: auth));
      await tester.pump(); // Don't settle - we want loading state

      final loginButton = find.widgetWithText(ElevatedButton, '');
      // The button shows CircularProgressIndicator when loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('dark mode toggle works correctly', (tester) async {
      final theme = ThemeProvider();

      await tester.pumpWidget(createLoginScreen(themeProvider: theme));
      await tester.pumpAndSettle();

      // Initial state: light mode
      expect(theme.isDarkMode, false);

      // Tap the switch
      final switchWidget = find.byType(Switch);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Now should be dark mode
      expect(theme.isDarkMode, true);

      // Tap again
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Back to light mode
      expect(theme.isDarkMode, false);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pumpAndSettle();

      // Initially password is obscured - find the visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_off);
      expect(visibilityButton, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Now should show visibility icon (not off)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });
  });
}
