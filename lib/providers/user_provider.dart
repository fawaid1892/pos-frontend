import 'package:flutter/foundation.dart';
import '../database/local_database.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  final LocalDatabase _db = LocalDatabase();
  List<PosUser> _users = [];
  bool _isLoading = false;
  String? _error;

  List<PosUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await _db.database;
      final maps = await db.query('users', orderBy: 'name ASC');
      _users = maps.map((m) => PosUser.fromJson(m)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<PosUser?> getUserById(String id) async {
    try {
      final db = await _db.database;
      final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return PosUser.fromJson(maps.first);
    } catch (e) {
      debugPrint('UserProvider.getUserById error: $e');
      return null;
    }
  }

  Future<bool> createUser(PosUser user) async {
    try {
      final db = await _db.database;
      await db.insert('users', {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'branch_id': user.branchId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'pending_sync': 1,
        'sync_status': 'pending',
      });
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(PosUser user) async {
    try {
      final db = await _db.database;
      await db.update(
        'users',
        {
          'email': user.email,
          'name': user.name,
          'role': user.role,
          'branch_id': user.branchId,
          'updated_at': DateTime.now().toIso8601String(),
          'pending_sync': 1,
          'sync_status': 'pending',
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final db = await _db.database;
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get list of branches for assignment dropdown.
  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final db = await _db.database;
      return await db.query('branches', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('UserProvider.getBranches error: $e');
      return [];
    }
  }
}
