import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Local database abstraction backed by ElectricSQL HTTP API.
///
/// Instead of sqflite, this uses Electric's sync service at port 5133
/// to execute SQL queries directly via HTTP POST /v1/query.
///
/// Schema is managed by Electric via Postgres logical replication —
/// no manual onCreate/onUpgrade migrations needed.
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  static const String _electricBaseUrl = 'http://localhost:5133';

  http.Client _httpClient = http.Client();

  /// Replace the default HTTP client (e.g. for testing).
  void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  /// Execute a raw SQL query via Electric HTTP API.
  ///
  /// Returns a list of result rows as maps.
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? params,
  ]) async {
    try {
      final uri = Uri.parse('$_electricBaseUrl/v1/query');
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'sql': sql,
              'params': params ?? [],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['rows'] ?? []);
      } else {
        debugPrint('Electric query error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Electric query failed: $e');
      return [];
    }
  }

  /// Execute a write SQL statement (INSERT/UPDATE/DELETE) via Electric HTTP API.
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    try {
      final uri = Uri.parse('$_electricBaseUrl/v1/query');
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'sql': sql,
              'params': params ?? [],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['affected_rows'] as num?)?.toInt() ?? 0;
      } else {
        debugPrint('Electric execute error ${response.statusCode}: ${response.body}');
        return 0;
      }
    } catch (e) {
      debugPrint('Electric execute failed: $e');
      return 0;
    }
  }

  /// Query a table with optional WHERE clause (simplified interface).
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final buffer = StringBuffer('SELECT * FROM $table');

    if (where != null) {
      buffer.write(' WHERE $where');
    }

    if (orderBy != null) {
      buffer.write(' ORDER BY $orderBy');
    }

    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    return rawQuery(buffer.toString(), whereArgs);
  }

  /// Insert a row into a table via Electric HTTP API.
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final columns = values.keys.join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    final params = values.values.toList();
    return execute(sql, params);
  }

  /// Update rows in a table via Electric HTTP API.
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final setClause = values.keys.map((k) => '$k = ?').join(', ');
    final sql = 'UPDATE $table SET $setClause';
    final params = values.values.toList();

    if (where != null) {
      return execute('$sql WHERE $where', [...params, ...?whereArgs]);
    }
    return execute(sql, params);
  }

  /// Delete rows from a table via Electric HTTP API.
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final sql = 'DELETE FROM $table';
    if (where != null) {
      return execute('$sql WHERE $where', whereArgs);
    }
    return execute(sql);
  }

  /// Insert or replace a record (upsert).
  Future<int> upsert(String table, Map<String, dynamic> map) async {
    // For Electric HTTP, we do a manual upsert: try INSERT, fallback to UPDATE
    final id = map['id'];
    if (id == null) {
      return insert(table, map);
    }

    final existing = await query(table, where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      return update(table, map, where: 'id = ?', whereArgs: [id]);
    } else {
      return insert(table, map);
    }
  }

  /// No-op: database is managed by Electric sync service.
  Future<void> close() async {}
}
