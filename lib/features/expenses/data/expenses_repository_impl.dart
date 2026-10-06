import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/storage/local_database_service.dart';
import '../domain/models/expense_category_model.dart';
import '../domain/models/expense_model.dart';
import '../domain/repositories/expenses_repository.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  final LocalDatabaseService _localDb;

  ExpensesRepositoryImpl(this._localDb);

  @override
  Future<List<ExpenseModel>> getExpenses({
    String? categoryId,
    String? searchQuery,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          var query = Supabase.instance.client
              .from('expenses')
              .select('*, category:expense_categories(name, color)');

          if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
            query = query.eq('category_id', categoryId);
          }

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            query = query.or('concept.ilike.%$searchQuery%,reference.ilike.%$searchQuery%');
          }

          if (from != null) {
            query = query.gte('created_at', from.toIso8601String());
          }

          if (to != null) {
            query = query.lte('created_at', to.toIso8601String());
          }

          final res = await query.order('created_at', ascending: false).limit(limit);
          return (res as List).map((j) => ExpenseModel.fromJson(j as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      await _localDb.ensureInitialized();
      final rows = await _localDb.query(
        LocalDatabaseService.tableExpenses,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      var expenses = rows.map((r) => ExpenseModel.fromJson(r)).toList();

      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        expenses = expenses.where((e) => e.categoryId == categoryId).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        expenses = expenses.where((e) => e.concept.toLowerCase().contains(q)).toList();
      }

      if (from != null) {
        expenses = expenses.where((e) => e.createdAt.isAfter(from)).toList();
      }

      if (to != null) {
        expenses = expenses.where((e) => e.createdAt.isBefore(to)).toList();
      }

      return expenses;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<ExpenseCategoryModel>> getCategories() async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final res = await Supabase.instance.client
              .from('expense_categories')
              .select()
              .eq('is_active', true)
              .order('name', ascending: true);

          return (res as List).map((j) => ExpenseCategoryModel.fromJson(j as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      await _localDb.ensureInitialized();
      final rows = await _localDb.query(
        LocalDatabaseService.tableExpenseCategories,
        orderBy: 'name',
        ascending: true,
      );
      return rows.map((r) => ExpenseCategoryModel.fromJson(r)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          String branchId = expense.branchId;
          final branchRes = await Supabase.instance.client
              .from('branches')
              .select('id')
              .limit(1)
              .maybeSingle();
          if (branchRes != null) {
            branchId = branchRes['id'] as String;
          }

          final payload = expense.toJson();
          payload['branch_id'] = branchId;
          if (payload.containsKey('id') && (payload['id'] as String).isEmpty) {
            payload.remove('id');
          }

          final res = await Supabase.instance.client
              .from('expenses')
              .insert(payload)
              .select('*, category:expense_categories(name, color)')
              .single();

          return ExpenseModel.fromJson(res);
        } catch (_) {}
      }

      await _localDb.ensureInitialized();
      final payload = expense.toJson();
      if (!payload.containsKey('id') || (payload['id'] as String).isEmpty) {
        payload['id'] = 'exp-${DateTime.now().millisecondsSinceEpoch}';
      }
      payload['created_at'] = DateTime.now().toIso8601String();

      final inserted = await _localDb.insert(LocalDatabaseService.tableExpenses, payload);
      return ExpenseModel.fromJson(inserted);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          await Supabase.instance.client.from('expenses').delete().eq('id', id);
          return;
        } catch (_) {}
      }

      await _localDb.delete(LocalDatabaseService.tableExpenses, id);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final localDb = ref.watch(localDatabaseServiceProvider);
  return ExpensesRepositoryImpl(localDb);
});
