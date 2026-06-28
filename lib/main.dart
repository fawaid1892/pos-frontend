import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/report_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/receipt_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/stock_adjustment_screen.dart';
import 'screens/stock_transfer_screen.dart';
import 'screens/report_screen.dart';
import 'screens/export_screen.dart';
import 'screens/low_stock_alert_screen.dart';
import 'widgets/sync_status_widget.dart';
import 'models/stock_adjustment.dart';
import 'services/electric_service.dart';
import 'services/seed_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Electric sync service (replaces sqflite + manual sync)
  final electricService = ElectricService();
  await electricService.init();

  // Seed initial data if database is empty (dev only)
  if (electricService.isConnected) {
    final seedService = SeedDataService();
    await seedService.seedIfEmpty();
  }

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Initialize sync provider (wraps ElectricService for UI state)
  final syncProvider = SyncProvider();
  await syncProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider.value(value: syncProvider),
      ],
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'POS Multi Branch',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeProv.themeMode,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/pos': (context) => const PosScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/receipt': (context) => const ReceiptScreen(),
        '/stock': (context) => const StockScreen(),
        '/stock-adjustment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is ProductStock) {
            return StockAdjustmentScreen(initialProduct: args);
          }
          return const StockAdjustmentScreen();
        },
        '/stock-transfer': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is ProductStock) {
            return StockTransferScreen(initialProduct: args);
          }
          return const StockTransferScreen();
        },
        '/reports': (context) => const ReportScreen(),
        '/export-report': (context) => const ExportScreen(),
        '/sync-status': (context) => const SyncStatusScreen(),
        '/low-stock-alert': (context) => const LowStockAlertScreen(),
      },
    );
  }
}
