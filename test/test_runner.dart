/// Test runner that discovers and runs all tests in the test directory.
///
/// Usage:
///   flutter test test/test_runner.dart
///   or simply: flutter test
library;

import 'models/branch_test.dart' as branch_test;
import 'models/product_test.dart' as product_test;
import 'models/transaction_test.dart' as transaction_test;
import 'providers/auth_provider_test.dart' as auth_provider_test;
import 'providers/cart_provider_test.dart' as cart_provider_test;
import 'providers/theme_provider_test.dart' as theme_provider_test;
import 'widgets/login_screen_test.dart' as login_screen_test;
import 'widgets/pos_screen_test.dart' as pos_screen_test;

void main() {
  branch_test.main();
  product_test.main();
  transaction_test.main();
  auth_provider_test.main();
  cart_provider_test.main();
  theme_provider_test.main();
  login_screen_test.main();
  pos_screen_test.main();
}
