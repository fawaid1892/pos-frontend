import 'electric_service.dart';

/// Seeds initial data via Electric HTTP API on first run.
///
/// Called once in main.dart after Electric sync initialization.
class SeedDataService {
  static final SeedDataService _instance = SeedDataService._internal();
  factory SeedDataService() => _instance;
  SeedDataService._internal();

  final ElectricService _electric = ElectricService();

  /// Seed all initial data if the database is empty.
  Future<void> seedIfEmpty() async {
    // Check if data already exists
    final branches = await _electric.query('SELECT * FROM branches');
    if (branches.isNotEmpty) return;

    // ── Branches ──
    await _electric.execute(
      "INSERT INTO branches (id, name, address, phone) VALUES (?, ?, ?, ?)",
      ['branch_001', 'Cabang Utama', 'Jl. Merdeka No.1', '021-1234567'],
    );
    await _electric.execute(
      "INSERT INTO branches (id, name, address, phone) VALUES (?, ?, ?, ?)",
      ['branch_002', 'Cabang Kedua', 'Jl. Sudirman No.45', '021-7654321'],
    );
    await _electric.execute(
      "INSERT INTO branches (id, name, address, phone) VALUES (?, ?, ?, ?)",
      ['branch_003', 'Cabang Ketiga', 'Jl. Gatot Subroto No.88', '021-5551234'],
    );

    // ── Users ──
    await _electric.execute(
      "INSERT INTO users (id, email, name, role) VALUES (?, ?, ?, ?)",
      ['user_001', 'owner@example.com', 'Owner', 'owner'],
    );
    await _electric.execute(
      "INSERT INTO users (id, email, name, role, branch_id) VALUES (?, ?, ?, ?, ?)",
      ['user_002', 'kasir@example.com', 'Kasir', 'cashier', 'branch_001'],
    );

    // ── Categories ──
    await _electric.execute(
      "INSERT INTO categories (id, name) VALUES (?, ?)",
      ['cat_001', 'Minuman'],
    );
    await _electric.execute(
      "INSERT INTO categories (id, name) VALUES (?, ?)",
      ['cat_002', 'Makanan'],
    );

    // ── Products ──
    final products = [
      {'id': 'prod_001', 'name': 'Kopi Hitam', 'barcode': '8991001001001', 'price': 15000, 'category': 'Minuman'},
      {'id': 'prod_002', 'name': 'Kopi Susu', 'barcode': '8991001001002', 'price': 20000, 'category': 'Minuman'},
      {'id': 'prod_003', 'name': 'Nasi Goreng', 'barcode': '8991001001003', 'price': 35000, 'category': 'Makanan'},
      {'id': 'prod_004', 'name': 'Mie Goreng', 'barcode': '8991001001004', 'price': 25000, 'category': 'Makanan'},
      {'id': 'prod_005', 'name': 'Air Mineral', 'barcode': '8991001001005', 'price': 5000, 'category': 'Minuman'},
      {'id': 'prod_006', 'name': 'Teh Manis', 'barcode': '8991001001006', 'price': 8000, 'category': 'Minuman'},
      {'id': 'prod_007', 'name': 'Kentang Goreng', 'barcode': '8991001001007', 'price': 20000, 'category': 'Makanan'},
      {'id': 'prod_008', 'name': 'Jus Jeruk', 'barcode': '8991001001008', 'price': 18000, 'category': 'Minuman'},
    ];

    for (final p in products) {
      await _electric.execute(
        'INSERT INTO products (id, name, barcode, price, category) VALUES (?, ?, ?, ?, ?)',
        [p['id'], p['name'], p['barcode'], p['price'], p['category']],
      );
    }

    // ── Branch Products (inventory per branch) ──
    final branchStocks = {
      'branch_001': {'prod_001': 50, 'prod_002': 40, 'prod_003': 25, 'prod_004': 30, 'prod_005': 100, 'prod_006': 60, 'prod_007': 20, 'prod_008': 3},
      'branch_002': {'prod_001': 12, 'prod_002': 8, 'prod_003': 5, 'prod_004': 0, 'prod_005': 45, 'prod_006': 22, 'prod_007': 2, 'prod_008': 15},
      'branch_003': {'prod_001': 30, 'prod_002': 20, 'prod_003': 0, 'prod_004': 10, 'prod_005': 80, 'prod_006': 15, 'prod_007': 7, 'prod_008': 25},
    };

    for (final branchEntry in branchStocks.entries) {
      for (final stockEntry in branchEntry.value.entries) {
        await _electric.execute(
          'INSERT INTO branch_products (id, branch_id, product_id, stock, minimum_stock) VALUES (?, ?, ?, ?, ?)',
          ['${branchEntry.key}_${stockEntry.key}', branchEntry.key, stockEntry.key, stockEntry.value, 5],
        );
      }
    }
  }
}
