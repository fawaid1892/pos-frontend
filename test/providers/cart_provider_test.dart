import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/models/product.dart';
import 'package:pos_flutter/models/transaction.dart';
import 'package:pos_flutter/providers/cart_provider.dart';

void main() {
  late CartProvider cart;

  // Sample products for testing
  final productA = Product(
    id: 'prod-001',
    name: 'Kopi Hitam',
    barcode: '8991001001001',
    price: 15000,
    category: 'Minuman',
    branchId: 'branch-001',
  );

  final productB = Product(
    id: 'prod-002',
    name: 'Nasi Goreng',
    barcode: '8991001001002',
    price: 25000,
    category: 'Makanan',
    branchId: 'branch-001',
  );

  final productC = Product(
    id: 'prod-003',
    name: 'Teh Manis',
    barcode: '8991001001003',
    price: 8000,
    category: 'Minuman',
    branchId: 'branch-001',
  );

  setUp(() {
    cart = CartProvider();
  });

  group('CartProvider - Initial state', () {
    test('starts with an empty cart', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.items, isEmpty);
      expect(cart.itemCount, equals(0));
      expect(cart.total, equals(0.0));
      expect(cart.discountTotal, equals(0.0));
      expect(cart.taxRate, equals(0.0));
      expect(cart.grandTotal, equals(0.0));
      expect(cart.taxAmount, equals(0.0));
      expect(cart.taxableAmount, equals(0.0));
      expect(cart.selectedPaymentMethod, equals('Tunai'));
      expect(cart.paymentReference, isNull);
    });
  });

  group('CartProvider - addProduct', () {
    test('adds a product to an empty cart', () {
      cart.addProduct(productA);

      expect(cart.isEmpty, isFalse);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals('prod-001'));
      expect(cart.items.first.quantity, equals(1));
      expect(cart.items.first.productName, equals('Kopi Hitam'));
      expect(cart.items.first.price, equals(15000));
      expect(cart.total, equals(15000));
      expect(cart.itemCount, equals(1));
    });

    test('increments quantity when adding an existing product', () {
      cart.addProduct(productA);
      cart.addProduct(productA);

      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(2));
      expect(cart.total, equals(30000));
      expect(cart.itemCount, equals(2));
    });

    test('adds multiple distinct products', () {
      cart.addProduct(productA);
      cart.addProduct(productB);

      expect(cart.items.length, equals(2));
      expect(cart.total, equals(40000)); // 15000 + 25000
      expect(cart.itemCount, equals(2));
    });

    test('adds product with custom quantity', () {
      cart.addProduct(productC, quantity: 3);

      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(3));
      expect(cart.total, equals(24000)); // 8000 * 3
      expect(cart.itemCount, equals(3));
    });
  });

  group('CartProvider - updateQuantity', () {
    test('updates quantity of an existing item', () {
      cart.addProduct(productA);
      cart.updateQuantity('prod-001', 5);

      expect(cart.items.first.quantity, equals(5));
      expect(cart.total, equals(75000));
    });

    test('removes item when quantity is set to zero', () {
      cart.addProduct(productA);
      cart.updateQuantity('prod-001', 0);

      expect(cart.items, isEmpty);
      expect(cart.isEmpty, isTrue);
    });

    test('removes item when quantity is set to negative', () {
      cart.addProduct(productA);
      cart.updateQuantity('prod-001', -1);

      expect(cart.items, isEmpty);
    });

    test('does nothing for unknown productId', () {
      cart.addProduct(productA);
      cart.updateQuantity('nonexistent', 10);

      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(1));
    });
  });

  group('CartProvider - removeItem', () {
    test('removes a product from the cart', () {
      cart.addProduct(productA);
      cart.addProduct(productB);

      cart.removeItem('prod-001');

      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals('prod-002'));
      expect(cart.total, equals(25000));
    });

    test('removing last item empties the cart', () {
      cart.addProduct(productB);
      cart.removeItem('prod-002');

      expect(cart.isEmpty, isTrue);
    });
  });

  group('CartProvider - item discounts', () {
    test('applies discount to a specific item', () {
      cart.addProduct(productA);
      cart.setItemDiscount('prod-001', 2000);

      expect(cart.items.first.discount, equals(2000));
      // subtotal = (15000 * 1) - 2000 = 13000
      expect(cart.items.first.subtotal, equals(13000));
      // total = sum of subtotals
      expect(cart.total, equals(13000));
    });

    test('updates existing item discount', () {
      cart.addProduct(productA);
      cart.setItemDiscount('prod-001', 2000);
      cart.setItemDiscount('prod-001', 5000);

      expect(cart.items.first.discount, equals(5000));
      expect(cart.items.first.subtotal, equals(10000));
    });

    test('does nothing for unknown productId', () {
      cart.addProduct(productA);
      cart.setItemDiscount('nonexistent', 3000);

      expect(cart.items.first.discount, equals(0.0));
    });
  });

  group('CartProvider - cart-level discount', () {
    test('default discount total is zero', () {
      expect(cart.discountTotal, equals(0.0));
    });

    test('sets cart-level discount', () {
      cart.addProduct(productA); // total = 15000
      cart.setCartDiscount(3000);

      expect(cart.discountTotal, equals(3000));
      expect(cart.total, equals(15000)); // total is sum of item subtotals (unchanged)
      expect(cart.taxableAmount, equals(12000)); // total - discount = 15000 - 3000
    });

    test('taxable amount clamps to zero', () {
      cart.addProduct(productA); // total = 15000
      cart.setCartDiscount(20000); // discount > total

      expect(cart.taxableAmount, equals(0.0));
    });
  });

  group('CartProvider - tax calculations', () {
    test('default tax rate is zero', () {
      expect(cart.taxRate, equals(0.0));
      expect(cart.taxAmount, equals(0.0));
    });

    test('calculates tax correctly with 11% PPN', () {
      cart.addProduct(productA, quantity: 2); // total = 30000

      cart.setTaxRate(0.11);

      expect(cart.taxRate, equals(0.11));
      expect(cart.taxableAmount, equals(30000));
      expect(cart.taxAmount, equals(3300)); // 30000 * 0.11
      expect(cart.grandTotal, equals(33300)); // 30000 + 3300
    });

    test('calculates tax with discount applied', () {
      cart.addProduct(productA, quantity: 2); // total = 30000
      cart.setCartDiscount(5000);
      cart.setTaxRate(0.11);

      expect(cart.taxableAmount, equals(25000)); // 30000 - 5000
      expect(cart.taxAmount, equals(2750)); // 25000 * 0.11
      expect(cart.grandTotal, equals(27750)); // 25000 + 2750
    });

    test('updates tax when rate changes', () {
      cart.addProduct(productA); // total = 15000
      cart.setTaxRate(0.11);
      expect(cart.taxAmount, equals(1650));

      cart.setTaxRate(0.0);
      expect(cart.taxAmount, equals(0.0));
    });
  });

  group('CartProvider - payment method', () {
    test('default payment method is Tunai', () {
      expect(cart.selectedPaymentMethod, equals('Tunai'));
    });

    test('changes payment method', () {
      cart.setPaymentMethod('QRIS');
      expect(cart.selectedPaymentMethod, equals('QRIS'));
    });

    test('clears reference when changing to Tunai', () {
      cart.setPaymentMethod('Transfer');
      cart.setPaymentReference('REF-123');
      expect(cart.paymentReference, equals('REF-123'));

      cart.setPaymentMethod('Tunai');
      expect(cart.paymentReference, isNull);
    });

    test('clears reference when changing to EDC', () {
      cart.setPaymentMethod('Transfer');
      cart.setPaymentReference('REF-123');

      cart.setPaymentMethod('EDC');
      expect(cart.paymentReference, isNull);
    });

    test('sets payment reference', () {
      cart.setPaymentMethod('Transfer');
      cart.setPaymentReference('TRF-001');
      expect(cart.paymentReference, equals('TRF-001'));
    });
  });

  group('CartProvider - buildTransaction', () {
    test('builds a Transaction from current cart state', () {
      cart.addProduct(productA, quantity: 2); // total = 30000
      cart.setCartDiscount(3000);
      cart.setTaxRate(0.11);
      cart.setPaymentMethod('Tunai');

      final transaction = cart.buildTransaction(
        id: 'txn-001',
        branchId: 'branch-001',
        cashierId: 'user-001',
        cashierName: 'Admin',
        amountPaid: 50000,
        change: 20300,
      );

      expect(transaction.id, equals('txn-001'));
      expect(transaction.branchId, equals('branch-001'));
      expect(transaction.cashierId, equals('user-001'));
      expect(transaction.cashierName, equals('Admin'));
      expect(transaction.items.length, equals(1));
      expect(transaction.items.first.productName, equals('Kopi Hitam'));
      expect(transaction.items.first.quantity, equals(2));
      expect(transaction.total, equals(30000));
      expect(transaction.discountTotal, equals(3000));
      expect(transaction.taxRate, equals(0.11));
      expect(transaction.paymentMethod, equals('Tunai'));
      expect(transaction.paymentReference, isNull);
      expect(transaction.amountPaid, equals(50000));
      expect(transaction.change, equals(20300));
      expect(transaction.receiptNumber, isNull);
    });

    test('buildTransaction preserves item discounts', () {
      cart.addProduct(productA);
      cart.setItemDiscount('prod-001', 2000);

      final transaction = cart.buildTransaction(
        id: 'txn-002',
        branchId: 'branch-001',
        cashierId: 'user-001',
        cashierName: 'Admin',
        amountPaid: 15000,
        change: 2000,
      );

      expect(transaction.items.first.discount, equals(2000));
      expect(transaction.items.first.subtotal, equals(13000));
    });
  });

  group('CartProvider - clearCart', () {
    test('resets all state to defaults', () {
      // Setup non-default state
      cart.addProduct(productA);
      cart.addProduct(productB);
      cart.addProduct(productC);
      cart.setCartDiscount(5000);
      cart.setTaxRate(0.11);
      cart.setPaymentMethod('QRIS');
      cart.setPaymentReference('QR-001');

      expect(cart.isEmpty, isFalse);

      cart.clearCart();

      expect(cart.isEmpty, isTrue);
      expect(cart.items, isEmpty);
      expect(cart.discountTotal, equals(0.0));
      expect(cart.taxRate, equals(0.0));
      expect(cart.selectedPaymentMethod, equals('Tunai'));
      expect(cart.paymentReference, isNull);
      expect(cart.total, equals(0.0));
      expect(cart.taxAmount, equals(0.0));
      expect(cart.grandTotal, equals(0.0));
      expect(cart.itemCount, equals(0));
    });
  });

  group('CartProvider - computed properties', () {
    test('itemCount sums quantities across items', () {
      cart.addProduct(productA, quantity: 3);
      cart.addProduct(productB, quantity: 2);
      cart.addProduct(productC, quantity: 5);

      expect(cart.itemCount, equals(10)); // 3 + 2 + 5
    });

    test('total is sum of item subtotals', () {
      cart.addProduct(productA, quantity: 2); // 15000*2 = 30000
      cart.addProduct(productB); // 25000
      cart.setItemDiscount('prod-001', 5000); // subtotal = 30000-5000 = 25000

      // total = 25000 + 25000 = 50000
      expect(cart.total, equals(50000));
    });

    test('grandTotal includes tax minus discount', () {
      cart.addProduct(productA, quantity: 2); // 30000
      cart.setCartDiscount(5000); // taxable = 25000
      cart.setTaxRate(0.11); // tax = 2750, grand = 27750

      expect(cart.grandTotal, equals(27750));
    });

    test('returned items list is unmodifiable', () {
      cart.addProduct(productA);

      expect(
        () => cart.items.add(
          TransactionItem(
            productId: 'x',
            productName: 'X',
            barcode: '000',
            price: 0,
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
