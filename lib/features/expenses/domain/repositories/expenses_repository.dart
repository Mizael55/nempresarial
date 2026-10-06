import '../models/expense_category_model.dart';
import '../models/expense_model.dart';

abstract class ExpensesRepository {
  Future<List<ExpenseModel>> getExpenses({
    String? categoryId,
    String? searchQuery,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  });

  Future<List<ExpenseCategoryModel>> getCategories();

  Future<ExpenseModel> createExpense(ExpenseModel expense);

  Future<void> deleteExpense(String id);
}
