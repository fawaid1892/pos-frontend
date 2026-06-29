import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pos_flutter/models/product.dart';
import 'package:pos_flutter/providers/auth_provider.dart';
import 'package:pos_flutter/providers/cart_provider.dart';
import 'package:pos_flutter/providers/stock_provider.dart';
import 'package:pos_flutter/providers/sync_provider.dart';
import 'package:pos_flutter/providers/theme_provider.dart';
import 'package:pos_flutter/screens/pos_screen.dart';

/// Helper to create a testable POS Screen with all required providers.
/// Uses minimal setup — the screen will be in loading state initially
/// since ProductService requires a real database.
Widget createPosScreen({
  AuthProvider? authProvider,
  CartProvider? cartProvider,
  StockProvider? stockProvider,
  SyncProvider? syncProvider,
  ThemeProvider? themeProvider,
}) {
  final auth = authProvider ?? AuthProvider();
  final cart = cartProvider ?? CartProvider();
  final stock = stockProvider ?? StockProvider();
  final theme = themeProvider ?? ThemeProvider();

  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider.value(value: stock),
        ChangeNotifierProvider.value(value: syncProvider ?? SyncProviderForTest()),
        ChangeNotifierProvider.value(value: theme),
      ],
      child: const PosScreen(),
    ),
    routes: {
      '/checkout': (context) => const Scaffold(
            body: Center(child: Text('Checkout Screen')),
          ),
      '/login': (context) => const Scaffold(
            body: Center(child: Text('Login Screen')),
          ),
      '/sync-status': (context) => const Scaffold(
            body: Center(child: Text('Sync Status')),
          ),
      '/low-stock-alert': (context) => const Scaffold(
            body: Center(child: Text('Low Stock Alert')),
          ),
    },
  );
}

/// A minimal SyncProvider for testing that doesn't connect to real services.
class SyncProviderForTest extends ChangeNotifier {
  bool _isSyncing = false;
  bool _isOnline = true;
  int _pendingCount = 0;
  int _conflictCount = 0;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingCount => _pendingCount;
  int get conflictCount => _conflictCount;
  dynamic get lastSyncResult => null;
  dynamic get syncService => null;
  dynamic get connectivityService => null;

  Future<dynamic> triggerSync() async => null;

  @override
  void dispose() {
    super.dispose();
  }
}

void main() {
  group('PosScreen Widget Tests', () {
    testWidgets('renders AppBar with branch name', (tester) async {
      final auth = AuthProvider();
      auth.setBranch('branch_001', 'Cabang Utama');

      await tester.pumpWidget(createPosScreen(authProvider: auth));

      // Just pump once without settling — the screen triggers async _loadProducts
      await tester.pump();

      expect(find.text('Cabang Utama'), findsOneWidget);
    });

    testWidgets('renders default title when branch name is null', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      expect(find.text('POS Multi Branch'), findsOneWidget);
    });

    testWidgets('shows shimmer loading on initial render', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      // ShimmerPage should be rendered since _isLoadingProducts starts as true
      // Look for any shimmer-related widget
      expect(find.byType(ShimmerPage), findsOneWidget);
    });

    testWidgets('renders search input field', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders barcode scanner FAB', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('renders action buttons in AppBar', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      // Dark mode toggle
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      // Logout button
      expect(find.byIcon(Icons.logout), findsOneWidget);

      // Cart toggle button
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);

      // Sync button
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('renders sync status icon in AppBar', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      // SyncStatusIcon should be present (renders cloud_done when idle)
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows cart view when cart icon is tapped', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      // Add a product to cart first
      final cartProvider = CartProvider();
      final product = Product(
        id: 'prod_001',
        name: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        category: 'Minuman',
        branchId: 'branch_001',
      );
      cartProvider.addProduct(product);

      // Rebuild with cart items
      await tester.pumpWidget(createPosScreen(cartProvider: cartProvider));
      await tester.pump();

      // Toggle to cart view by tapping the shopping cart icon
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pump();

      // Now the cart view should be showing
      // The checkout button should appear
      expect(find.text('Bayar'), findsOneWidget);
    });

    testWidgets('empty cart view shows EmptyStateWidget.cart', (tester) async {
      await tester.pumpWidget(createPosScreen());
      await tester.pump();

      // Tap cart icon to show empty cart view
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pump();

      // EmptyStateWidget with cart icon should show
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('Keranjang kosong'), findsOneWidget);
    });

    testWidgets('logout button triggers auth logout', (tester) async {
      final auth = AuthProvider();
      await auth.login('owner@example.com', 'password123');

      await tester.pumpWidget(createPosScreen(authProvider: auth));
      await tester.pump();

      // Should be logged in
      expect(auth.isLoggedIn, true);

      // Tap logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      // Auth should be logged out
      expect(auth.isLoggedIn, false);
    });

    testWidgets('dark mode toggle in AppBar calls ThemeProvider',
        (tester) async {
      final theme = ThemeProvider();

      await tester.pumpWidget(createPosScreen(themeProvider: theme));
      await tester.pump();

      // Initially light mode
      expect(theme.isDarkMode, false);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      // Tap dark mode toggle
      await tester.tap(find.byIcon(Icons.dark_mode));
      await tester.pump();

      // Should now be dark mode
      expect(theme.isDarkMode, true);
    });

    testWidgets('cart badge shows item count', (tester) async {
      final cart = CartProvider();
      final product = Product(
        id: 'prod_001',
        name: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        category: 'Minuman',
        branchId: 'branch_001',
      );
      cart.addProduct(product, quantity: 3);

      await tester.pumpWidget(createPosScreen(cartProvider: cart));
      await tester.pump();

      // Tap cart icon to see cart view
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pump();

      // Cart item should be shown with quantity
      expect(find.text('3'), findsWidgets);
      expect(find.text('Kopi Hitam'), findsOneWidget);
    });
  });
}
