import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/models/product.dart';
import 'package:pos_flutter/models/transaction.dart';
import 'package:pos_flutter/providers/cart_provider.dart';

void main() {
  group('CartProvider', () {
    late CartProvider cartProvider;

    setUp(() {
      cartProvider = CartProvider();
    });

    tearDown(() {
      cartProvider.dispose();
    });

    test('initial state is empty cart', () {
      expect(cartProvider.isEmpty, true);
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.total, 0.0);
      expect(cartProvider.discountTotal, 0.0);
      expect(cartProvider.taxRate, 0.0);
      expect(cartProvider.taxableAmount, 0.0);
      expect(cartProvider.taxAmount, 0.0);
      expect(cartProvider.grandTotal, 0.0);
      expect(cartProvider.selectedPaymentMethod, 'Tunai');
      expect(cartProvider.paymentReference, isNull);
    });

    group('addProduct', () {
      test('adds a new product to the cart', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);

        expect(cartProvider.isEmpty, false);
        expect(cartProvider.items.length, 1);
        expect(cartProvider.items[0].productId, 'prod_001');
        expect(cartProvider.items[0].productName, 'Kopi Hitam');
        expect(cartProvider.items[0].barcode, '8991234567890');
        expect(cartProvider.items[0].price, 15000.0);
        expect(cartProvider.items[0].quantity, 1);
      });

      test('adds product with custom quantity', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product, quantity: 3);

        expect(cartProvider.items.length, 1);
        expect(cartProvider.items[0].quantity, 3);
        expect(cartProvider.itemCount, 3);
      });

      test('increments quantity when adding same product', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        cartProvider.addProduct(product);

        expect(cartProvider.items.length, 1);
        expect(cartProvider.items[0].quantity, 2);
      });

      test('increments quantity by specified amount when adding same product', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product, quantity: 2);
        cartProvider.addProduct(product, quantity: 3);

        expect(cartProvider.items.length, 1);
        expect(cartProvider.items[0].quantity, 5);
      });

      test('adds multiple different products', () {
        final product1 = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );
        final product2 = Product(
          id: 'prod_002',
          name: 'Nasi Goreng',
          barcode: '8991234567891',
          price: 25000.0,
          category: 'Makanan',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product1);
        cartProvider.addProduct(product2);

        expect(cartProvider.items.length, 2);
        expect(cartProvider.itemCount, 2);
      });
    });

    group('removeItem', () {
      test('removes an existing item from the cart', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        expect(cartProvider.items.length, 1);

        cartProvider.removeItem('prod_001');
        expect(cartProvider.items.length, 0);
        expect(cartProvider.isEmpty, true);
      });

      test('does nothing when removing non-existent item', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        expect(cartProvider.items.length, 1);

        cartProvider.removeItem('non_existent');
        expect(cartProvider.items.length, 1);
      });
    });

    group('updateQuantity', () {
      test('updates quantity of existing item', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        cartProvider.updateQuantity('prod_001', 5);

        expect(cartProvider.items[0].quantity, 5);
      });

      test('removes item when quantity set to 0 or negative', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);

        cartProvider.updateQuantity('prod_001', 0);
        expect(cartProvider.items.length, 0);

        // Re-add and test with negative
        cartProvider.addProduct(product);
        cartProvider.updateQuantity('prod_001', -1);
        expect(cartProvider.items.length, 0);
      });

      test('does nothing when updating non-existent item', () {
        cartProvider.updateQuantity('non_existent', 5);
        expect(cartProvider.items.length, 0);
      });
    });

    group('clearCart', () {
      test('clears all items and resets state', () {
        final product1 = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );
        final product2 = Product(
          id: 'prod_002',
          name: 'Nasi Goreng',
          barcode: '8991234567891',
          price: 25000.0,
          category: 'Makanan',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product1);
        cartProvider.addProduct(product2);
        cartProvider.setCartDiscount(5000.0);
        cartProvider.setTaxRate(0.11);
        cartProvider.setPaymentMethod('QRIS');
        cartProvider.setPaymentReference('REF-123');

        cartProvider.clearCart();

        expect(cartProvider.isEmpty, true);
        expect(cartProvider.items, isEmpty);
        expect(cartProvider.discountTotal, 0.0);
        expect(cartProvider.taxRate, 0.0);
        expect(cartProvider.selectedPaymentMethod, 'Tunai');
        expect(cartProvider.paymentReference, isNull);
      });
    });

    group('totals calculation', () {
      test('total is sum of all item subtotals', () {
        final product1 = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );
        final product2 = Product(
          id: 'prod_002',
          name: 'Nasi Goreng',
          barcode: '8991234567891',
          price: 25000.0,
          category: 'Makanan',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product1); // 1 * 15000 = 15000
        cartProvider.addProduct(product2); // 1 * 25000 = 25000

        expect(cartProvider.total, 40000.0);
      });

      test('total accounts for quantity and discounts', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product, quantity: 3);
        cartProvider.setItemDiscount('prod_001', 5000.0);

        // (15000 * 3) - 5000 = 40000
        expect(cartProvider.total, 40000.0);
      });

      test('grandTotal with tax and no cart discount', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 100000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        cartProvider.setTaxRate(0.11); // 11% PPN

        expect(cartProvider.total, 100000.0);
        expect(cartProvider.taxableAmount, 100000.0);
        expect(cartProvider.taxAmount, 11000.0);
        expect(cartProvider.grandTotal, 111000.0);
      });

      test('grandTotal with tax and cart discount', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 100000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        cartProvider.setTaxRate(0.11);
        cartProvider.setCartDiscount(10000.0);

        // taxableAmount = (100000 - 10000).clamp(0, inf) = 90000
        // taxAmount = 90000 * 0.11 = 9900
        // grandTotal = 90000 + 9900 = 99900
        expect(cartProvider.total, 100000.0);
        expect(cartProvider.taxableAmount, 90000.0);
        expect(cartProvider.taxAmount, 9900.0);
        expect(cartProvider.grandTotal, 99900.0);
      });

      test('taxableAmount clamps to zero', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 10000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        cartProvider.setTaxRate(0.11);
        cartProvider.setCartDiscount(20000.0);

        // total (10000) - discountTotal (20000) = -10000 -> clamp to 0
        expect(cartProvider.taxableAmount, 0.0);
        expect(cartProvider.taxAmount, 0.0);
        expect(cartProvider.grandTotal, 0.0);
      });

      test('itemCount returns sum of all quantities', () {
        final product1 = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );
        final product2 = Product(
          id: 'prod_002',
          name: 'Nasi Goreng',
          barcode: '8991234567891',
          price: 25000.0,
          category: 'Makanan',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product1, quantity: 2);
        cartProvider.addProduct(product2, quantity: 3);

        expect(cartProvider.itemCount, 5); // 2 + 3
      });
    });

    group('setItemDiscount', () {
      test('sets discount on existing item', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);
        cartProvider.setItemDiscount('prod_001', 2000.0);

        expect(cartProvider.items[0].discount, 2000.0);
      });

      test('does nothing for non-existent item', () {
        cartProvider.setItemDiscount('non_existent', 1000.0);
        // Should not throw
      });
    });

    group('setCartDiscount', () {
      test('sets cart-level discount', () {
        cartProvider.setCartDiscount(5000.0);
        expect(cartProvider.discountTotal, 5000.0);
      });
    });

    group('setTaxRate', () {
      test('sets tax rate', () {
        cartProvider.setTaxRate(0.11);
        expect(cartProvider.taxRate, 0.11);
      });
    });

    group('setPaymentMethod', () {
      test('sets payment method and clears reference for Tunai', () {
        cartProvider.setPaymentMethod('QRIS');
        cartProvider.setPaymentReference('REF-123');

        cartProvider.setPaymentMethod('Tunai');

        expect(cartProvider.selectedPaymentMethod, 'Tunai');
        expect(cartProvider.paymentReference, isNull);
      });

      test('sets payment method and clears reference for EDC', () {
        cartProvider.setPaymentMethod('QRIS');
        cartProvider.setPaymentReference('REF-123');

        cartProvider.setPaymentMethod('EDC');

        expect(cartProvider.selectedPaymentMethod, 'EDC');
        expect(cartProvider.paymentReference, isNull);
      });

      test('sets payment method without clearing reference for other methods', () {
        cartProvider.setPaymentReference('REF-123');
        cartProvider.setPaymentMethod('QRIS');

        expect(cartProvider.selectedPaymentMethod, 'QRIS');
        expect(cartProvider.paymentReference, 'REF-123');
      });
    });

    group('buildTransaction', () {
      test('builds transaction from cart state', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product, quantity: 2);
        cartProvider.setTaxRate(0.11);

        final transaction = cartProvider.buildTransaction(
          id: 'trx_001',
          branchId: 'branch_001',
          cashierId: 'user_001',
          cashierName: 'Owner',
          amountPaid: 50000.0,
          change: 16700.0,
          receiptNumber: 'RCP-001',
        );

        expect(transaction.id, 'trx_001');
        expect(transaction.branchId, 'branch_001');
        expect(transaction.cashierId, 'user_001');
        expect(transaction.cashierName, 'Owner');
        expect(transaction.items.length, 1);
        expect(transaction.items[0].productId, 'prod_001');
        expect(transaction.total, 30000.0);
        expect(transaction.taxRate, 0.11);
        expect(transaction.grandTotal, 33300.0); // 30000 + (30000*0.11)
        expect(transaction.amountPaid, 50000.0);
        expect(transaction.change, 16700.0);
        expect(transaction.receiptNumber, 'RCP-001');
        expect(transaction.paymentMethod, 'Tunai');
      });
    });

    group('items getter returns unmodifiable list', () {
      test('cannot modify returned list directly', () {
        final product = Product(
          id: 'prod_001',
          name: 'Kopi Hitam',
          barcode: '8991234567890',
          price: 15000.0,
          category: 'Minuman',
          branchId: 'branch_001',
        );

        cartProvider.addProduct(product);

        final items = cartProvider.items;
        expect(() => items.clear(), throwsUnsupportedError);
      });
    });

    test('notifies listeners on state changes', () {
      int notifyCount = 0;
      cartProvider.addListener(() {
        notifyCount++;
      });

      final product = Product(
        id: 'prod_001',
        name: 'Kopi Hitam',
        barcode: '8991234567890',
        price: 15000.0,
        category: 'Minuman',
        branchId: 'branch_001',
      );

      cartProvider.addProduct(product);
      expect(notifyCount, greaterThanOrEqualTo(1));

      final previousCount = notifyCount;
      cartProvider.removeItem('prod_001');
      expect(notifyCount, greaterThan(previousCount));
    });
  });
}
