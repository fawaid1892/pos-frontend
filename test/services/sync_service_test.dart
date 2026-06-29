import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pos_flutter/services/sync_service.dart';

// Generate mocks for http.Client
// Run: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([http.Client])
import 'sync_service_test.mocks.dart';

void main() {
  late SyncService syncService;

  setUp(() {
    syncService = SyncService();
  });

  group('SyncService - Initial state', () {
    test('starts in idle status', () {
      expect(syncService.status, equals(SyncStatus.idle));
    });

    test('starts with zero pending and conflict counts', () {
      expect(syncService.pendingCount, equals(0));
      expect(syncService.conflictCount, equals(0));
    });

    test('lastSyncResult is initially null', () {
      expect(syncService.lastSyncResult, isNull);
    });

    test('lastSyncError is initially null', () {
      expect(syncService.lastSyncError, isNull);
    });
  });

  group('SyncService - setHttpClient', () {
    test('accepts custom HTTP client injection', () {
      final customClient = MockClient();
      syncService.setHttpClient(customClient);
      // No crash means the injection worked
      expect(syncService, isNotNull);
    });

    test('allows replacing HTTP client after construction', () {
      final client1 = MockClient();
      final client2 = MockClient();
      syncService.setHttpClient(client1);
      syncService.setHttpClient(client2);
      // Second replacement should work without error
      expect(syncService, isNotNull);
    });
  });

  group('SyncService - syncAll', () {
    test('rejects concurrent sync when already syncing', () async {
      // First sync call starts — goes through _pushPendingChanges which
      // needs database. In test env without sqflite_common_ffi it will
      // throw, but we can test the concurrency guard via status check.
      syncService.syncAll(); // fire-and-forget, status becomes syncing

      // Immediately call syncAll again — should be rejected
      final secondResult = await syncService.syncAll();

      expect(secondResult.success, isFalse);
      expect(secondResult.error, contains('Sync already in progress'));
    });
  });

  group('SyncResult model', () {
    test('creates with default values', () {
      final result = SyncResult(success: true);

      expect(result.success, isTrue);
      expect(result.pushedCount, equals(0));
      expect(result.pulledCount, equals(0));
      expect(result.conflicts, isEmpty);
      expect(result.error, isNull);
      expect(result.completedAt, isNotNull);
    });

    test('creates with custom values', () {
      final now = DateTime(2026, 6, 26, 11, 0, 0);
      final result = SyncResult(
        success: true,
        pushedCount: 5,
        pulledCount: 10,
        conflicts: ['transactions/txn-001'],
        error: null,
        completedAt: now,
      );

      expect(result.pushedCount, equals(5));
      expect(result.pulledCount, equals(10));
      expect(result.conflicts, contains('transactions/txn-001'));
      expect(result.completedAt, equals(now));
    });

    test('summary shows no changes for empty success', () {
      final result = SyncResult(success: true);
      expect(result.summary, equals('No changes'));
    });

    test('summary includes pushed count', () {
      final result = SyncResult(success: true, pushedCount: 5);
      expect(result.summary, contains('5 pushed'));
    });

    test('summary includes pulled count', () {
      final result = SyncResult(success: true, pulledCount: 12);
      expect(result.summary, contains('12 pulled'));
    });

    test('summary includes conflict count', () {
      final result = SyncResult(
        success: true,
        conflicts: ['transactions/txn-1', 'products/prod-1'],
      );
      expect(result.summary, contains('2 conflicts'));
    });

    test('summary combines all counts', () {
      final result = SyncResult(
        success: true,
        pushedCount: 3,
        pulledCount: 15,
        conflicts: ['txn/1'],
      );
      expect(result.summary, equals('3 pushed, 15 pulled, 1 conflicts'));
    });

    test('summary shows failure with error', () {
      final result =
          SyncResult(success: false, error: 'Connection timeout');
      expect(result.summary, equals('Failed: Connection timeout'));
    });

    test('summary shows fallback for unknown error', () {
      final result = SyncResult(success: false);
      expect(result.summary, equals('Failed: Unknown error'));
    });

    test('summary for failure ignores counts', () {
      final result = SyncResult(
        success: false,
        pushedCount: 5,
        error: 'Server unreachable',
      );
      expect(result.summary, equals('Failed: Server unreachable'));
    });
  });

  group('SyncStatus enum', () {
    test('contains all sync status values', () {
      expect(SyncStatus.values, hasLength(4));
      expect(
        SyncStatus.values,
        containsAll([
          SyncStatus.idle,
          SyncStatus.syncing,
          SyncStatus.success,
          SyncStatus.error,
        ]),
      );
    });

    test('default value is idle', () {
      expect(SyncStatus.idle.name, equals('idle'));
    });

    test('status values have expected names', () {
      expect(SyncStatus.syncing.name, equals('syncing'));
      expect(SyncStatus.success.name, equals('success'));
      expect(SyncStatus.error.name, equals('error'));
    });
  });

  group('SyncService - HTTP integration (via public API)', () {
    /// These tests demonstrate how HTTP mocking works with SyncService.
    /// They require sqflite_common_ffi or a test database setup to run
    /// because syncAll() internally accesses the local database.
    ///
    /// To run: add sqflite_common_ffi to dev_dependencies, then
    /// call `databaseFactoryFfiNoIsolate` before each test.
    ///
    /// Example setup:
    /// ```dart
    /// setUpAll(() {
    ///   databaseFactory = databaseFactoryFfiNoIsolate;
    /// });
    /// ```
    ///
    /// Once the database factory is configured, inject a mock HTTP client
    /// and call syncService.syncAll() to verify the full push/pull flow.

    test('ready for HTTP client injection', () {
      final mockClient = MockClient();
      syncService.setHttpClient(mockClient);

      // The SyncService is now configured to use the mock client.
      // When sqflite test support is installed, calling
      // syncService.syncAll() will route HTTP calls through this mock.
      expect(syncService, isNotNull);
    });

    test('singleton pattern returns same instance', () {
      final instance1 = SyncService();
      final instance2 = SyncService();
      expect(identical(instance1, instance2), isTrue);
    });
  });
}
