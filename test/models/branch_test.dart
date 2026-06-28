import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/models/branch.dart';

void main() {
  group('Branch Model', () {
    test('constructor assigns fields correctly', () {
      final branch = Branch(
        id: 'branch_001',
        name: 'Cabang Utama',
        address: 'Jl. Merdeka No. 1',
        phone: '021-12345678',
      );

      expect(branch.id, 'branch_001');
      expect(branch.name, 'Cabang Utama');
      expect(branch.address, 'Jl. Merdeka No. 1');
      expect(branch.phone, '021-12345678');
    });

    test('constructor allows nullable address and phone', () {
      final branch = Branch(
        id: 'branch_002',
        name: 'Cabang Kedua',
      );

      expect(branch.id, 'branch_002');
      expect(branch.name, 'Cabang Kedua');
      expect(branch.address, isNull);
      expect(branch.phone, isNull);
    });

    test('toJson returns correct map', () {
      final branch = Branch(
        id: 'branch_001',
        name: 'Cabang Utama',
        address: 'Jl. Merdeka No. 1',
        phone: '021-12345678',
      );

      final json = branch.toJson();

      expect(json, {
        'id': 'branch_001',
        'name': 'Cabang Utama',
        'address': 'Jl. Merdeka No. 1',
        'phone': '021-12345678',
      });
    });

    test('toJson returns map with null address and phone', () {
      final branch = Branch(
        id: 'branch_002',
        name: 'Cabang Kedua',
      );

      final json = branch.toJson();

      expect(json, {
        'id': 'branch_002',
        'name': 'Cabang Kedua',
        'address': null,
        'phone': null,
      });
    });

    test('fromJson creates Branch correctly', () {
      final json = {
        'id': 'branch_001',
        'name': 'Cabang Utama',
        'address': 'Jl. Merdeka No. 1',
        'phone': '021-12345678',
      };

      final branch = Branch.fromJson(json);

      expect(branch.id, 'branch_001');
      expect(branch.name, 'Cabang Utama');
      expect(branch.address, 'Jl. Merdeka No. 1');
      expect(branch.phone, '021-12345678');
    });

    test('fromJson handles null address and phone', () {
      final json = {
        'id': 'branch_002',
        'name': 'Cabang Kedua',
        'address': null,
        'phone': null,
      };

      final branch = Branch.fromJson(json);

      expect(branch.id, 'branch_002');
      expect(branch.name, 'Cabang Kedua');
      expect(branch.address, isNull);
      expect(branch.phone, isNull);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'branch_003',
        'name': 'Cabang Tiga',
      };

      final branch = Branch.fromJson(json);

      expect(branch.id, 'branch_003');
      expect(branch.name, 'Cabang Tiga');
      expect(branch.address, isNull);
      expect(branch.phone, isNull);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = Branch(
        id: 'branch_001',
        name: 'Cabang Utama',
        address: 'Jl. Merdeka No. 1',
        phone: '021-12345678',
      );

      final json = original.toJson();
      final reconstructed = Branch.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.address, original.address);
      expect(reconstructed.phone, original.phone);
    });
  });
}
