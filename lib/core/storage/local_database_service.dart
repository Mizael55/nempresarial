import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Embedded Local Database Service for PC / Offline autonomous operation.
/// Stores structured JSON rows persisted across sessions on desktop (macOS/Windows) and mobile.
class LocalDatabaseService {
  static const String tableProducts = 'nubiko_table_products';
  static const String tableCategories = 'nubiko_table_categories';
  static const String tableInventory = 'nubiko_table_inventory';
  static const String tableMovements = 'nubiko_table_movements';
  static const String tableSales = 'nubiko_table_sales';
  static const String tableSaleItems = 'nubiko_table_sale_items';
  static const String tableExpenses = 'nubiko_table_expenses';
  static const String tableExpenseCategories = 'nubiko_table_expense_categories';
  static const String tableCustomers = 'nubiko_table_customers';
  static const String tableBusinessSettings = 'nubiko_table_business_settings';
  static const String tableUsers = 'nubiko_table_users';

  static const String keyStorageMode = 'nubiko_storage_mode'; // 'local' | 'cloud'
  static const String keySetupWizardCompleted = 'nubiko_setup_wizard_completed';
  static const String keyCustomSupabaseUrl = 'nubiko_custom_supabase_url';
  static const String keyCustomSupabaseAnonKey = 'nubiko_custom_supabase_anon_key';

  final Uuid _uuid = const Uuid();

  // Instant in-memory cache for zero-latency lookups and widget test compatibility
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  bool _isDiskLoaded = true;
  String _cachedStorageMode = 'local';
  bool _cachedSetupCompleted = false;

  LocalDatabaseService() {
    _initDefaultMemoryCache();
  }

  void _initDefaultMemoryCache() {
    _cache[tableCategories] = [
      {
        'id': 'cat_general',
        'name': 'General',
        'description': 'Productos y servicios generales',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'cat_alimentos',
        'name': 'Alimentos y Bebidas',
        'description': 'Consumibles, víveres y bebidas',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'cat_tecnologia',
        'name': 'Tecnología',
        'description': 'Dispositivos, accesorios y componentes',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'cat_servicios',
        'name': 'Servicios',
        'description': 'Servicios profesionales o técnicos',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    _cache[tableExpenseCategories] = [
      {
        'id': 'exp_cat_operativo',
        'name': 'Gastos Operativos',
        'description': 'Servicios básicos, internet, luz, agua',
        'icon': 'zap',
        'color': '#0EA5E9',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'exp_cat_nomina',
        'name': 'Nómina y Sueldos',
        'description': 'Pagos a empleados y colaboradores',
        'icon': 'users',
        'color': '#10B981',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'exp_cat_alquiler',
        'name': 'Alquiler y Local',
        'description': 'Arrendamiento de local comercial u oficina',
        'icon': 'building',
        'color': '#F59E0B',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'exp_cat_suministros',
        'name': 'Suministros y Materiales',
        'description': 'Papelería, limpieza y empaque',
        'icon': 'package',
        'color': '#8B5CF6',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    _cache[tableUsers] = [
      {
        'id': 'usr_admin_default',
        'email': 'admin@empresa.com',
        'password': 'admin123456',
        'full_name': 'Administrador del Sistema',
        'role': 'super_admin',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'usr_admin_nubiko',
        'email': 'admin@nubiko.com',
        'password': 'admin123',
        'full_name': 'Administrador Nubiko',
        'role': 'super_admin',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final table in [
      tableProducts,
      tableInventory,
      tableMovements,
      tableSales,
      tableSaleItems,
      tableExpenses,
      tableCustomers,
      tableBusinessSettings,
    ]) {
      _cache[table] = [];
    }
  }

  /// Ensure tables and initial seed data exist on disk and in memory
  Future<void> ensureInitialized() async {
    if (_isDiskLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedStorageMode = prefs.getString(keyStorageMode) ?? 'local';
      _cachedSetupCompleted = prefs.getBool(keySetupWizardCompleted) ?? false;

      // Load all tables from SharedPreferences into cache if present
      for (final table in [
        tableCategories,
        tableExpenseCategories,
        tableUsers,
        tableProducts,
        tableInventory,
        tableMovements,
        tableSales,
        tableSaleItems,
        tableExpenses,
        tableCustomers,
        tableBusinessSettings,
      ]) {
        final raw = prefs.getString(table);
        if (raw != null && raw.isNotEmpty) {
          try {
            final list = jsonDecode(raw) as List<dynamic>;
            _cache[table] = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } catch (_) {}
        } else if (_cache.containsKey(table) && _cache[table]!.isNotEmpty) {
          await prefs.setString(table, jsonEncode(_cache[table]));
        }
      }
      _isDiskLoaded = true;
    } catch (e) {
      debugPrint('ensureInitialized disk loading info: $e');
      _isDiskLoaded = true;
    }
  }

  /// Get rows from a table (ultra-fast in-memory with optional disk check)
  Future<List<Map<String, dynamic>>> query(
    String table, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    if (!_isDiskLoaded) {
      try {
        await ensureInitialized();
      } catch (_) {}
    }

    final list = _cache[table] ?? [];
    var results = List<Map<String, dynamic>>.from(list);

    if (where != null && where.isNotEmpty) {
      results = results.where((row) {
        for (final entry in where.entries) {
          if (row[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    if (orderBy != null) {
      results.sort((a, b) {
        final valA = a[orderBy];
        final valB = b[orderBy];
        if (valA == null && valB == null) return 0;
        if (valA == null) return ascending ? -1 : 1;
        if (valB == null) return ascending ? 1 : -1;

        int comp;
        if (valA is Comparable && valB is Comparable) {
          comp = valA.compareTo(valB);
        } else {
          comp = valA.toString().compareTo(valB.toString());
        }
        return ascending ? comp : -comp;
      });
    }

    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }

    return results;
  }

  /// Find row by ID
  Future<Map<String, dynamic>?> findById(String table, String id) async {
    final rows = await query(table, where: {'id': id}, limit: 1);
    if (rows.isNotEmpty) return rows.first;
    return null;
  }

  /// Insert a row into a table
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> row) async {
    final rowMap = Map<String, dynamic>.from(row);
    if (!rowMap.containsKey('id') || rowMap['id'] == null || (rowMap['id'] as String).isEmpty) {
      rowMap['id'] = _uuid.v4();
    }
    if (!rowMap.containsKey('created_at') || rowMap['created_at'] == null) {
      rowMap['created_at'] = DateTime.now().toIso8601String();
    }
    rowMap['updated_at'] = DateTime.now().toIso8601String();

    final list = _cache.putIfAbsent(table, () => []);
    list.add(rowMap);

    _persistTable(table);
    return rowMap;
  }

  /// Update row by ID
  Future<Map<String, dynamic>?> update(
    String table,
    String id,
    Map<String, dynamic> updates,
  ) async {
    final list = _cache[table] ?? [];
    int index = list.indexWhere((r) => r['id'] == id);
    if (index == -1) return null;

    final updated = Map<String, dynamic>.from(list[index]);
    updates.forEach((key, value) {
      if (key != 'id') {
        updated[key] = value;
      }
    });
    updated['updated_at'] = DateTime.now().toIso8601String();

    list[index] = updated;
    _persistTable(table);
    return updated;
  }

  /// Delete row by ID
  Future<bool> delete(String table, String id) async {
    final list = _cache[table] ?? [];
    int beforeLen = list.length;
    list.removeWhere((r) => r['id'] == id);
    if (list.length < beforeLen) {
      _persistTable(table);
      return true;
    }
    return false;
  }

  /// Clear table content
  Future<void> clearTable(String table) async {
    _cache[table] = [];
    _persistTable(table);
  }

  void _persistTable(String table) {
    SharedPreferences.getInstance().then((prefs) {
      final list = _cache[table] ?? [];
      prefs.setString(table, jsonEncode(list));
    }).catchError((_) {});
  }

  /// Reset all data, keeping only default admin accounts
  Future<void> resetAllData({bool keepAdminUser = true}) async {
    await clearTable(tableProducts);
    await clearTable(tableInventory);
    await clearTable(tableMovements);
    await clearTable(tableSales);
    await clearTable(tableSaleItems);
    await clearTable(tableExpenses);
    await clearTable(tableCustomers);
    await clearTable(tableBusinessSettings);

    if (!keepAdminUser) {
      await clearTable(tableUsers);
    }
    _initDefaultMemoryCache();
    for (final table in _cache.keys) {
      _persistTable(table);
    }
  }

  // Storage Mode helpers
  Future<String> getStorageMode() async {
    if (_isDiskLoaded) return _cachedStorageMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedStorageMode = prefs.getString(keyStorageMode) ?? 'local';
    } catch (_) {}
    return _cachedStorageMode;
  }

  Future<void> setStorageMode(String mode) async {
    _cachedStorageMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyStorageMode, mode);
    } catch (_) {}
  }

  Future<bool> isSetupWizardCompleted() async {
    if (_isDiskLoaded) return _cachedSetupCompleted;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedSetupCompleted = prefs.getBool(keySetupWizardCompleted) ?? false;
    } catch (_) {}
    return _cachedSetupCompleted;
  }

  Future<void> setSetupWizardCompleted(bool value) async {
    _cachedSetupCompleted = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keySetupWizardCompleted, value);
    } catch (_) {}
  }

  Future<String?> getCustomSupabaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyCustomSupabaseUrl);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCustomSupabaseAnonKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyCustomSupabaseAnonKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCustomSupabaseCredentials(String url, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyCustomSupabaseUrl, url.trim());
      await prefs.setString(keyCustomSupabaseAnonKey, key.trim());
    } catch (_) {}
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});
