import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Remote data source that handles all Supabase CRUD operations.
/// This layer abstracts Supabase API calls from the sync engine.
class SupabaseDataSource {
  static final SupabaseDataSource instance = SupabaseDataSource._();
  SupabaseDataSource._();

  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  SupabaseClient get _client => SupabaseConfig.client;

  // ============================================================
  // GENERIC OPERATIONS
  // ============================================================

  /// Fetch all records from a table, optionally filtered by last sync time
  Future<List<Map<String, dynamic>>> fetchAll(
    String table, {
    String? since,
  }) async {
    try {
      var query = _client.from(table).select();
      if (since != null) {
        // Fetch records updated after the last sync
        final data = await query.gte('updated_at', since).order('updated_at');
        return List<Map<String, dynamic>>.from(data);
      }
      final data = await query.order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _logger.e('Failed to fetch from $table: $e');
      rethrow;
    }
  }

  /// Fetch a single record by UUID
  Future<Map<String, dynamic>?> fetchByUuid(String table, String uuid) async {
    try {
      final data = await _client
          .from(table)
          .select()
          .eq('uuid', uuid)
          .maybeSingle();
      return data;
    } catch (e) {
      _logger.e('Failed to fetch $table by uuid $uuid: $e');
      rethrow;
    }
  }

  /// Insert a record into remote table
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _client.from(table).insert(data).select().single();
      _logger.d('Inserted into $table: ${data['uuid']}');
      return result;
    } catch (e) {
      _logger.e('Failed to insert into $table: $e');
      rethrow;
    }
  }

  /// Update a record in remote table by UUID
  Future<Map<String, dynamic>> update(
    String table,
    String uuid,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _client
          .from(table)
          .update(data)
          .eq('uuid', uuid)
          .select()
          .single();
      _logger.d('Updated $table: $uuid');
      return result;
    } catch (e) {
      _logger.e('Failed to update $table uuid=$uuid: $e');
      rethrow;
    }
  }

  /// Soft delete a record in remote table (mark is_deleted = true)
  Future<void> softDelete(String table, String uuid) async {
    try {
      await _client
          .from(table)
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uuid', uuid);
      _logger.d('Soft deleted $table: $uuid');
    } catch (e) {
      _logger.e('Failed to soft delete $table uuid=$uuid: $e');
      rethrow;
    }
  }

  /// Upsert a record (insert or update based on uuid conflict)
  Future<Map<String, dynamic>> upsert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _client
          .from(table)
          .upsert(data, onConflict: 'uuid')
          .select()
          .single();
      _logger.d('Upserted $table: ${data['uuid']}');
      return result;
    } catch (e) {
      _logger.e('Failed to upsert $table: $e');
      rethrow;
    }
  }

  /// Batch upsert multiple records
  Future<List<Map<String, dynamic>>> batchUpsert(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return [];
    try {
      final result = await _client
          .from(table)
          .upsert(records, onConflict: 'uuid')
          .select();
      _logger.d('Batch upserted ${records.length} records into $table');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      _logger.e('Failed to batch upsert $table: $e');
      rethrow;
    }
  }

  // ============================================================
  // CARDS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchCards({String? since}) =>
      fetchAll(SupabaseConfig.cardsTable, since: since);

  Future<Map<String, dynamic>> upsertCard(Map<String, dynamic> data) =>
      upsert(SupabaseConfig.cardsTable, data);

  Future<void> deleteCard(String uuid) =>
      softDelete(SupabaseConfig.cardsTable, uuid);

  // ============================================================
  // CATEGORIES
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchCategories({String? since}) =>
      fetchAll(SupabaseConfig.categoriesTable, since: since);

  Future<Map<String, dynamic>> upsertCategory(Map<String, dynamic> data) =>
      upsert(SupabaseConfig.categoriesTable, data);

  Future<void> deleteCategory(String uuid) =>
      softDelete(SupabaseConfig.categoriesTable, uuid);

  // ============================================================
  // PAYMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchPayments({String? since}) =>
      fetchAll(SupabaseConfig.paymentsTable, since: since);

  Future<Map<String, dynamic>> upsertPayment(Map<String, dynamic> data) =>
      upsert(SupabaseConfig.paymentsTable, data);

  Future<void> deletePayment(String uuid) =>
      softDelete(SupabaseConfig.paymentsTable, uuid);

  // ============================================================
  // WISHLIST
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchWishlist({String? since}) =>
      fetchAll(SupabaseConfig.wishlistTable, since: since);

  Future<Map<String, dynamic>> upsertWishlistItem(Map<String, dynamic> data) =>
      upsert(SupabaseConfig.wishlistTable, data);

  Future<void> deleteWishlistItem(String uuid) =>
      softDelete(SupabaseConfig.wishlistTable, uuid);
}
