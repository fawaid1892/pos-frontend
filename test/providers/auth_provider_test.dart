import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    tearDown(() {
      authProvider.dispose();
    });

    test('initial state is not logged in', () {
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.token, isNull);
      expect(authProvider.userId, isNull);
      expect(authProvider.userName, isNull);
      expect(authProvider.branchId, isNull);
      expect(authProvider.branchName, isNull);
      expect(authProvider.role, isNull);
      expect(authProvider.isLoading, false);
    });

    test('login with owner email sets owner state', () async {
      final result = await authProvider.login('owner@example.com', 'password123');

      expect(result, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.token, startsWith('mock_token_owner_'));
      expect(authProvider.userId, 'user_001');
      expect(authProvider.userName, 'Owner');
      expect(authProvider.branchId, isNull);
      expect(authProvider.branchName, isNull);
      expect(authProvider.role, 'owner');
      expect(authProvider.isLoading, false);
    });

    test('login with non-owner email sets cashier state', () async {
      final result = await authProvider.login('kasir@example.com', 'password123');

      expect(result, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.token, startsWith('mock_token_kasir_'));
      expect(authProvider.userId, 'user_002');
      expect(authProvider.userName, 'Kasir');
      expect(authProvider.branchId, 'branch_001');
      expect(authProvider.branchName, 'Cabang Utama');
      expect(authProvider.role, 'cashier');
      expect(authProvider.isLoading, false);
    });

    test('login sets isLoading to true then false', () async {
      // Capture states
      final states = <bool>[];
      authProvider.addListener(() {
        states.add(authProvider.isLoading);
      });

      final future = authProvider.login('owner@example.com', 'password123');

      // After first notifyListeners, isLoading should be true
      // But we need to wait for microtask
      await Future(() {}); // Let the first notify fire
      expect(authProvider.isLoading, true);

      await future;

      expect(authProvider.isLoading, false);
    });

    test('logout clears all state', () async {
      // Login first
      await authProvider.login('owner@example.com', 'password123');
      expect(authProvider.isLoggedIn, true);

      // Logout
      await authProvider.logout();

      expect(authProvider.isLoggedIn, false);
      expect(authProvider.token, isNull);
      expect(authProvider.userId, isNull);
      expect(authProvider.userName, isNull);
      expect(authProvider.branchId, isNull);
      expect(authProvider.branchName, isNull);
      expect(authProvider.role, isNull);
    });

    test('setBranch updates branchId and branchName', () {
      expect(authProvider.branchId, isNull);
      expect(authProvider.branchName, isNull);

      authProvider.setBranch('branch_002', 'Cabang Dua');

      expect(authProvider.branchId, 'branch_002');
      expect(authProvider.branchName, 'Cabang Dua');
    });

    test('multiple logins update token correctly', () async {
      await authProvider.login('owner@example.com', 'password123');
      final firstToken = authProvider.token;
      expect(firstToken, contains('owner'));

      await authProvider.login('kasir@test.com', 'password123');
      final secondToken = authProvider.token;
      expect(secondToken, contains('kasir'));
      expect(secondToken, isNot(equals(firstToken)));
    });

    test('notifies listeners on login', () async {
      int notifyCount = 0;
      authProvider.addListener(() {
        notifyCount++;
      });

      await authProvider.login('owner@example.com', 'password123');

      // Should have notified at least twice (loading start + loading end)
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('notifies listeners on logout', () async {
      await authProvider.login('owner@example.com', 'password123');

      int notifyCount = 0;
      authProvider.addListener(() {
        notifyCount++;
      });

      await authProvider.logout();

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });
}
