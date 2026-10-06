import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/storage/local_database_service.dart';
import '../../../expenses/data/expenses_repository_impl.dart';
import '../../../products/data/products_repository_impl.dart';
import '../../../sales/data/sales_repository_impl.dart';
import '../../domain/dashboard_metrics.dart';

class DashboardState {
  final bool isLoading;
  final DashboardMetrics metrics;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.metrics = const DashboardMetrics(),
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardMetrics? metrics,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardController(this._ref) : super(const DashboardState()) {
    loadMetrics();
  }

  Future<void> loadMetrics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final localDb = _ref.read(localDatabaseServiceProvider);
      final mode = await localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final res = await Supabase.instance.client.rpc('get_dashboard_metrics');
          if (res is Map<String, dynamic>) {
            state = state.copyWith(
              isLoading: false,
              metrics: DashboardMetrics.fromJson(res),
            );
            return;
          }
        } catch (_) {}
      }

      // Compute live metrics from repositories
      final salesRepo = _ref.read(salesRepositoryProvider);
      final productsRepo = _ref.read(productsRepositoryProvider);
      final expensesRepo = _ref.read(expensesRepositoryProvider);

      final sales = await salesRepo.getSales(status: 'completed', limit: 200);
      final products = await productsRepo.getProducts();
      final expenses = await expensesRepo.getExpenses();

      final now = DateTime.now();
      double salesToday = 0;
      double salesWeek = 0;
      double salesMonth = 0;
      double totalIncome = 0;
      double totalExpenses = 0;

      for (final s in sales) {
        final d = s.createdAt;
        totalIncome += s.totalAmount;
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          salesToday += s.totalAmount;
        }
        if (now.difference(d).inDays <= 7) {
          salesWeek += s.totalAmount;
        }
        if (d.year == now.year && d.month == now.month) {
          salesMonth += s.totalAmount;
        }
      }

      for (final e in expenses) {
        totalExpenses += e.amount;
      }

      final lowStock = products
          .where((p) => p.currentStock <= p.minStock)
          .map((p) => LowStockItem(
                id: p.id,
                name: p.name,
                sku: p.sku,
                currentStock: p.currentStock,
                minStock: p.minStock,
              ))
          .toList();

      final recent = sales.take(5).map<RecentSaleItem>((s) => RecentSaleItem(
            id: s.id,
            invoiceNumber: s.invoiceNumber,
            customerName: s.customerName,
            total: s.totalAmount,
            paymentMethod: s.paymentMethod,
            timeAgo: 'Hoy',
          )).toList();

      final metrics = DashboardMetrics(
        salesToday: salesToday,
        salesWeek: salesWeek,
        salesMonth: salesMonth,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netProfit: totalIncome - totalExpenses,
        lowStockProducts: lowStock,
        recentSales: recent,
      );

      state = state.copyWith(isLoading: false, metrics: metrics);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        metrics: const DashboardMetrics(),
        errorMessage: 'Error al cargar métricas del negocio.',
      );
    }
  }

  void refresh() {
    loadMetrics();
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref);
});
