import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/models/transaction.dart';

void main() {
  group('TransactionItem Model', () {
    test('constructor assigns fields correctly', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 2,
        discount: 1000.0,
      );

      expect(item.productId, 'prod_001');
      expect(item.productName, 'Kopi Hitam');
      expect(item.barcode, '8991234567890');
      expect(item.price, 15000.0);
      expect(item.quantity, 2);
      expect(item.discount, 1000.0);
    });

    test('constructor defaults quantity to 1 and discount to 0', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
      );

      expect(item.quantity, 1);
      expect(item.discount, 0.0);
    });

    test('subtotal calculates correctly without discount', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 3,
      );

      expect(item.subtotal, 45000.0);
    });

    test('subtotal calculates correctly with discount', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 3,
        discount: 5000.0,
      );

      // (15000 * 3) - 5000 = 45000 - 5000 = 40000
      expect(item.subtotal, 40000.0);
    });

    test('subtotal with zero quantity', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 0,
      );

      expect(item.subtotal, 0.0);
    });

    test('subtotal with discount greater than total', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 10000.0,
        quantity: 1,
        discount: 15000.0,
      );

      expect(item.subtotal, -5000.0);
    });

    test('toJson returns correct map including subtotal', () {
      final item = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 2,
        discount: 1000.0,
      );

      final json = item.toJson();

      expect(json['productId'], 'prod_001');
      expect(json['productName'], 'Kopi Hitam');
      expect(json['barcode'], '8991234567890');
      expect(json['price'], 15000.0);
      expect(json['quantity'], 2);
      expect(json['discount'], 1000.0);
      expect(json['subtotal'], 29000.0); // (15000*2) - 1000
    });

    test('fromJson creates TransactionItem correctly', () {
      final json = {
        'productId': 'prod_001',
        'productName': 'Kopi Hitam',
        'barcode': '8991234567890',
        'price': 15000.0,
        'quantity': 2,
        'discount': 1000.0,
        'subtotal': 29000.0,
      };

      final item = TransactionItem.fromJson(json);

      expect(item.productId, 'prod_001');
      expect(item.productName, 'Kopi Hitam');
      expect(item.barcode, '8991234567890');
      expect(item.price, 15000.0);
      expect(item.quantity, 2);
      expect(item.discount, 1000.0);
    });

    test('fromJson defaults quantity to 1 and discount to 0.0 when null', () {
      final json = {
        'productId': 'prod_001',
        'productName': 'Kopi Hitam',
        'barcode': '8991234567890',
        'price': 15000.0,
      };

      final item = TransactionItem.fromJson(json);

      expect(item.quantity, 1);
      expect(item.discount, 0.0);
    });

    test('fromJson handles int price as num', () {
      final json = {
        'productId': 'prod_001',
        'productName': 'Kopi Hitam',
        'barcode': '8991234567890',
        'price': 15000, // int
        'quantity': 1,
      };

      final item = TransactionItem.fromJson(json);

      expect(item.price, isA<double>());
      expect(item.price, 15000.0);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 3,
        discount: 2000.0,
      );

      final json = original.toJson();
      final reconstructed = TransactionItem.fromJson(json);

      expect(reconstructed.productId, original.productId);
      expect(reconstructed.productName, original.productName);
      expect(reconstructed.barcode, original.barcode);
      expect(reconstructed.price, original.price);
      expect(reconstructed.quantity, original.quantity);
      expect(reconstructed.discount, original.discount);
    });
  });

  group('Transaction Model', () {
    final sampleItems = [
      TransactionItem(
        productId: 'prod_001',
        productName: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        quantity: 2,
      ),
      TransactionItem(
        productId: 'prod_002',
        productName: 'Nasi Goreng',
        barcode: '8991234567891',
        price: 25000.0,
        quantity: 1,
      ),
    ];

    final now = DateTime(2025, 1, 15, 10, 30, 0);

    test('constructor assigns fields correctly', () {
      final transaction = Transaction(
        id: 'trx_001',
        branchId: 'branch_001',
        cashierId: 'user_001',
        cashierName: 'Owner',
        items: sampleItems,
        total: 55000.0,
        discountTotal: 5000.0,
        taxRate: 0.11,
        taxAmount: 5500.0,
        grandTotal: 60500.0,
        paymentMethod: 'Tunai',
        paymentReference: null,
        amountPaid: 70000.0,
        change: 9500.0,
        createdAt: now,
        receiptNumber: 'RCP-2025-0001',
      );

      expect(transaction.id, 'trx_001');
      expect(transaction.branchId, 'branch_001');
      expect(transaction.cashierId, 'user_001');
      expect(transaction.cashierName, 'Owner');
      expect(transaction.items.length, 2);
      expect(transaction.total, 55000.0);
      expect(transaction.discountTotal, 5000.0);
      expect(transaction.taxRate, 0.11);
      expect(transaction.taxAmount, 5500.0);
      expect(transaction.grandTotal, 60500.0);
      expect(transaction.paymentMethod, 'Tunai');
      expect(transaction.paymentReference, isNull);
      expect(transaction.amountPaid, 70000.0);
      expect(transaction.change, 9500.0);
      expect(transaction.createdAt, now);
      expect(transaction.receiptNumber, 'RCP-2025-0001');
    });

    test('constructor defaults discountTotal, taxRate, taxAmount to 0', () {
      final transaction = Transaction(
        id: 'trx_002',
        branchId: 'branch_001',
        cashierId: 'user_001',
        cashierName: 'Owner',
        items: [],
        total: 0.0,
        grandTotal: 0.0,
        paymentMethod: 'Tunai',
        amountPaid: 0.0,
        change: 0.0,
        createdAt: now,
      );

      expect(transaction.discountTotal, 0.0);
      expect(transaction.taxRate, 0.0);
      expect(transaction.taxAmount, 0.0);
      expect(transaction.paymentReference, isNull);
      expect(transaction.receiptNumber, isNull);
    });

    test('toJson returns correct map', () {
      final transaction = Transaction(
        id: 'trx_001',
        branchId: 'branch_001',
        cashierId: 'user_001',
        cashierName: 'Owner',
        items: sampleItems,
        total: 55000.0,
        discountTotal: 5000.0,
        taxRate: 0.11,
        taxAmount: 5500.0,
        grandTotal: 60500.0,
        paymentMethod: 'Tunai',
        paymentReference: null,
        amountPaid: 70000.0,
        change: 9500.0,
        createdAt: now,
        receiptNumber: 'RCP-2025-0001',
      );

      final json = transaction.toJson();

      expect(json['id'], 'trx_001');
      expect(json['branchId'], 'branch_001');
      expect(json['cashierId'], 'user_001');
      expect(json['cashierName'], 'Owner');
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, 2);
      expect(json['total'], 55000.0);
      expect(json['discountTotal'], 5000.0);
      expect(json['taxRate'], 0.11);
      expect(json['taxAmount'], 5500.0);
      expect(json['grandTotal'], 60500.0);
      expect(json['paymentMethod'], 'Tunai');
      expect(json['paymentReference'], null);
      expect(json['amountPaid'], 70000.0);
      expect(json['change'], 9500.0);
      expect(json['createdAt'], now.toIso8601String());
      expect(json['receiptNumber'], 'RCP-2025-0001');
    });

    test('fromJson creates Transaction correctly', () {
      final json = {
        'id': 'trx_001',
        'branchId': 'branch_001',
        'cashierId': 'user_001',
        'cashierName': 'Owner',
        'items': [
          {
            'productId': 'prod_001',
            'productName': 'Kopi Hitam',
            'barcode': '8991234567890',
            'price': 15000.0,
            'quantity': 2,
            'discount': 0.0,
            'subtotal': 30000.0,
          },
        ],
        'total': 30000.0,
        'discountTotal': 0.0,
        'taxRate': 0.0,
        'taxAmount': 0.0,
        'grandTotal': 30000.0,
        'paymentMethod': 'Tunai',
        'paymentReference': null,
        'amountPaid': 50000.0,
        'change': 20000.0,
        'createdAt': '2025-01-15T10:30:00.000',
        'receiptNumber': 'RCP-2025-0001',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 'trx_001');
      expect(transaction.branchId, 'branch_001');
      expect(transaction.cashierId, 'user_001');
      expect(transaction.cashierName, 'Owner');
      expect(transaction.items.length, 1);
      expect(transaction.items[0].productName, 'Kopi Hitam');
      expect(transaction.total, 30000.0);
      expect(transaction.discountTotal, 0.0);
      expect(transaction.taxRate, 0.0);
      expect(transaction.taxAmount, 0.0);
      expect(transaction.grandTotal, 30000.0);
      expect(transaction.paymentMethod, 'Tunai');
      expect(transaction.paymentReference, isNull);
      expect(transaction.amountPaid, 50000.0);
      expect(transaction.change, 20000.0);
      expect(transaction.createdAt, DateTime(2025, 1, 15, 10, 30, 0));
      expect(transaction.receiptNumber, 'RCP-2025-0001');
    });

    test('fromJson handles nullable fields with defaults', () {
      final json = {
        'id': 'trx_001',
        'branchId': 'branch_001',
        'cashierId': 'user_001',
        'cashierName': 'Owner',
        'items': [],
        'total': 0.0,
        'grandTotal': 0.0,
        'paymentMethod': 'QRIS',
        'amountPaid': 0.0,
        'change': 0.0,
        'createdAt': '2025-01-15T10:30:00.000',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.discountTotal, 0.0);
      expect(transaction.taxRate, 0.0);
      expect(transaction.taxAmount, 0.0);
      expect(transaction.paymentReference, isNull);
      expect(transaction.receiptNumber, isNull);
    });

    test('fromJson handles int values by converting to double', () {
      final json = {
        'id': 'trx_001',
        'branchId': 'branch_001',
        'cashierId': 'user_001',
        'cashierName': 'Owner',
        'items': [],
        'total': 30000, // int
        'discountTotal': 0,
        'taxRate': 0,
        'taxAmount': 0,
        'grandTotal': 30000, // int
        'paymentMethod': 'Tunai',
        'amountPaid': 50000, // int
        'change': 20000, // int
        'createdAt': '2025-01-15T10:30:00.000',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.total, isA<double>());
      expect(transaction.total, 30000.0);
      expect(transaction.grandTotal, 30000.0);
      expect(transaction.amountPaid, 50000.0);
      expect(transaction.change, 20000.0);
    });

    test('toJson and fromJson round-trip preserves data', () {
      final original = Transaction(
        id: 'trx_001',
        branchId: 'branch_001',
        cashierId: 'user_001',
        cashierName: 'Owner',
        items: sampleItems,
        total: 55000.0,
        discountTotal: 5000.0,
        taxRate: 0.11,
        taxAmount: 5500.0,
        grandTotal: 60500.0,
        paymentMethod: 'QRIS',
        paymentReference: 'REF-123',
        amountPaid: 60500.0,
        change: 0.0,
        createdAt: now,
        receiptNumber: 'RCP-2025-0001',
      );

      final json = original.toJson();
      final reconstructed = Transaction.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.branchId, original.branchId);
      expect(reconstructed.cashierId, original.cashierId);
      expect(reconstructed.cashierName, original.cashierName);
      expect(reconstructed.items.length, original.items.length);
      expect(reconstructed.total, original.total);
      expect(reconstructed.discountTotal, original.discountTotal);
      expect(reconstructed.taxRate, original.taxRate);
      expect(reconstructed.taxAmount, original.taxAmount);
      expect(reconstructed.grandTotal, original.grandTotal);
      expect(reconstructed.paymentMethod, original.paymentMethod);
      expect(reconstructed.paymentReference, original.paymentReference);
      expect(reconstructed.amountPaid, original.amountPaid);
      expect(reconstructed.change, original.change);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.receiptNumber, original.receiptNumber);
    });
  });
}
