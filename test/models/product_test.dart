import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/models/product.dart';

void main() {
  group('Product Model', () {
    const testId = 'prod_001';
    const testName = 'Kopi Hitam';
    const testBarcode = '8991234567890';
    const testPrice = 15000.0;
    const testCategory = 'Minuman';
    const testImageUrl = 'https://example.com/kopi.jpg';
    const testStock = 50;
    const testBranchId = 'branch_001';

    test('constructor assigns all fields correctly', () {
      final product = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        imageUrl: testImageUrl,
        stock: testStock,
        branchId: testBranchId,
      );

      expect(product.id, testId);
      expect(product.name, testName);
      expect(product.barcode, testBarcode);
      expect(product.price, testPrice);
      expect(product.category, testCategory);
      expect(product.imageUrl, testImageUrl);
      expect(product.stock, testStock);
      expect(product.branchId, testBranchId);
    });

    test('constructor defaults stock to 0', () {
      final product = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        branchId: testBranchId,
      );

      expect(product.stock, 0);
    });

    test('constructor allows nullable imageUrl', () {
      final product = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        branchId: testBranchId,
      );

      expect(product.imageUrl, isNull);
    });

    test('toJson returns correct map', () {
      final product = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        imageUrl: testImageUrl,
        stock: testStock,
        branchId: testBranchId,
      );

      final json = product.toJson();

      expect(json['id'], testId);
      expect(json['name'], testName);
      expect(json['barcode'], testBarcode);
      expect(json['price'], testPrice);
      expect(json['category'], testCategory);
      expect(json['imageUrl'], testImageUrl);
      expect(json['stock'], testStock);
      expect(json['branchId'], testBranchId);
    });

    test('toJson handles null imageUrl', () {
      final product = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        branchId: testBranchId,
      );

      final json = product.toJson();

      expect(json['imageUrl'], isNull);
    });

    test('fromJson creates Product correctly', () {
      final json = {
        'id': testId,
        'name': testName,
        'barcode': testBarcode,
        'price': testPrice,
        'category': testCategory,
        'imageUrl': testImageUrl,
        'stock': testStock,
        'branchId': testBranchId,
      };

      final product = Product.fromJson(json);

      expect(product.id, testId);
      expect(product.name, testName);
      expect(product.barcode, testBarcode);
      expect(product.price, testPrice);
      expect(product.category, testCategory);
      expect(product.imageUrl, testImageUrl);
      expect(product.stock, testStock);
      expect(product.branchId, testBranchId);
    });

    test('fromJson handles null imageUrl', () {
      final json = {
        'id': testId,
        'name': testName,
        'barcode': testBarcode,
        'price': testPrice,
        'category': testCategory,
        'imageUrl': null,
        'stock': testStock,
        'branchId': testBranchId,
      };

      final product = Product.fromJson(json);

      expect(product.id, testId);
      expect(product.imageUrl, isNull);
    });

    test('fromJson handles null stock with default', () {
      final json = {
        'id': testId,
        'name': testName,
        'barcode': testBarcode,
        'price': testPrice,
        'category': testCategory,
        'stock': null,
        'branchId': testBranchId,
      };

      final product = Product.fromJson(json);

      expect(product.stock, 0);
    });

    test('fromJson parses price as num and converts to double', () {
      final json = {
        'id': testId,
        'name': testName,
        'barcode': testBarcode,
        'price': 15000, // int in JSON
        'category': testCategory,
        'stock': testStock,
        'branchId': testBranchId,
      };

      final product = Product.fromJson(json);

      expect(product.price, isA<double>());
      expect(product.price, 15000.0);
    });

    test('copyWith creates a copy with updated fields', () {
      final original = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        imageUrl: testImageUrl,
        stock: testStock,
        branchId: testBranchId,
      );

      final modified = original.copyWith(name: 'Kopi Susu', price: 18000.0);

      expect(modified.id, original.id);
      expect(modified.name, 'Kopi Susu');
      expect(modified.barcode, original.barcode);
      expect(modified.price, 18000.0);
      expect(modified.category, original.category);
      expect(modified.imageUrl, original.imageUrl);
      expect(modified.stock, original.stock);
      expect(modified.branchId, original.branchId);
    });

    test('copyWith with no arguments returns identical copy', () {
      final original = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        branchId: testBranchId,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.barcode, original.barcode);
      expect(copy.price, original.price);
      expect(copy.category, original.category);
      expect(copy.stock, original.stock);
      expect(copy.branchId, original.branchId);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = Product(
        id: testId,
        name: testName,
        barcode: testBarcode,
        price: testPrice,
        category: testCategory,
        imageUrl: testImageUrl,
        stock: testStock,
        branchId: testBranchId,
      );

      final json = original.toJson();
      final reconstructed = Product.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.barcode, original.barcode);
      expect(reconstructed.price, original.price);
      expect(reconstructed.category, original.category);
      expect(reconstructed.imageUrl, original.imageUrl);
      expect(reconstructed.stock, original.stock);
      expect(reconstructed.branchId, original.branchId);
    });
  });
}
