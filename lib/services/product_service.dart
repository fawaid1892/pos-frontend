import '../database/local_database.dart';
import '../models/product.dart';

/// Service for product CRUD operations backed by ElectricSQL/PGlite.
///
/// Replaces MockApiService for product-related operations.
class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final LocalDatabase _db = LocalDatabase();

  /// Get all products for a specific branch.
  /// Joins products + branch_products to get stock per branch.
  Future<List<Product>> getProducts(String branchId) async {
    final maps = await _db.rawQuery('''
      SELECT p.*, bp.stock
      FROM products p
      INNER JOIN branch_products bp ON bp.product_id = p.id
      WHERE bp.branch_id = ?
      ORDER BY p.name ASC
    ''', [branchId]);

    return maps.map((m) => Product.fromJson({
      ...m,
      'branchId': branchId,
      'stock': m['stock'] ?? 0,
    })).toList();
  }

  /// Get a product by barcode.
  Future<Product?> getProductByBarcode(String barcode, String branchId) async {
    final maps = await _db.rawQuery('''
      SELECT p.*, bp.stock
      FROM products p
      INNER JOIN branch_products bp ON bp.product_id = p.id
      WHERE p.barcode = ? AND bp.branch_id = ?
      LIMIT 1
    ''', [barcode, branchId]);

    if (maps.isEmpty) return null;
    return Product.fromJson({
      ...maps.first,
      'branchId': branchId,
      'stock': maps.first['stock'] ?? 0,
    });
  }

  /// Search products by name or barcode.
  Future<List<Product>> searchProducts(String query, String branchId) async {
    final q = '%$query%';

    final maps = await _db.rawQuery('''
      SELECT p.*, bp.stock
      FROM products p
      INNER JOIN branch_products bp ON bp.product_id = p.id
      WHERE bp.branch_id = ?
        AND (p.name LIKE ? OR p.barcode LIKE ?)
      ORDER BY p.name ASC
    ''', [branchId, q, q]);

    return maps.map((m) => Product.fromJson({
      ...m,
      'branchId': branchId,
      'stock': m['stock'] ?? 0,
    })).toList();
  }

  /// Insert or update a product (upsert).
  Future<void> upsertProduct(Product product) async {
    await _db.upsert('products', product.toJson());
  }

  /// Upsert a branch_product record (inventory per branch).
  Future<void> upsertBranchProduct({
    required String branchId,
    required String productId,
    required int stock,
    int minimumStock = 5,
  }) async {
    final id = '${branchId}_$productId';

    await _db.upsert('branch_products', {
      'id': id,
      'branch_id': branchId,
      'product_id': productId,
      'stock': stock,
      'minimum_stock': minimumStock,
    });
  }
}
