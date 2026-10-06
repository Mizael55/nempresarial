import 'package:flutter_test/flutter_test.dart';
import 'package:nempresarial/features/dashboard/domain/dashboard_metrics.dart';

void main() {
  group('Dashboard Metrics Unit Tests', () {
    test('DashboardMetrics fromJson parses real backend aggregation format', () {
      final mockJson = {
        'sales_today': 12500.50,
        'sales_today_delta': 15.2,
        'sales_week': 85000.00,
        'sales_week_delta': 8.5,
        'sales_month': 340000.00,
        'sales_month_delta': -2.1,
        'total_income': 520000.00,
        'total_expenses': 140000.00,
        'net_profit': 380000.00,
        'accounts_receivable': 45000.00,
        'accounts_payable': 28000.00,
        'low_stock_products': [
          {
            'id': 'p-1',
            'name': 'Arroz Selecto 10lb',
            'sku': 'ARR-010',
            'current_stock': 3.0,
            'min_stock': 10.0,
          },
        ],
        'recent_sales': [
          {
            'id': 's-1',
            'invoice_number': 'FAC-000010',
            'customer_name': 'Juan Pérez',
            'total_amount': 2450.0,
            'payment_method': 'cash',
            'created_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          },
        ],
        'weekly_sales_trend': [1000.0, 1500.0, 2000.0, 1800.0, 2200.0, 3100.0, 2500.0],
      };

      final metrics = DashboardMetrics.fromJson(mockJson);

      expect(metrics.salesToday, 12500.50);
      expect(metrics.salesTodayDelta, 15.2);
      expect(metrics.salesWeek, 85000.00);
      expect(metrics.totalIncome, 520000.00);
      expect(metrics.totalExpenses, 140000.00);
      expect(metrics.netProfit, 380000.00);
      expect(metrics.accountsReceivable, 45000.00);
      expect(metrics.accountsPayable, 28000.00);

      expect(metrics.lowStockProducts.length, 1);
      expect(metrics.lowStockProducts.first.name, 'Arroz Selecto 10lb');
      expect(metrics.lowStockProducts.first.currentStock, 3.0);

      expect(metrics.recentSales.length, 1);
      expect(metrics.recentSales.first.invoiceNumber, 'FAC-000010');
      expect(metrics.recentSales.first.total, 2450.0);
      expect(metrics.recentSales.first.timeAgo, contains('15m'));

      expect(metrics.weeklySalesTrend.length, 7);
      expect(metrics.weeklySalesTrend.last, 2500.0);
    });

    test('DashboardMetrics default fallback when empty or null', () {
      final metrics = DashboardMetrics.fromJson({});

      expect(metrics.salesToday, 0.0);
      expect(metrics.salesWeek, 0.0);
      expect(metrics.totalIncome, 0.0);
      expect(metrics.netProfit, 0.0);
      expect(metrics.accountsReceivable, 0.0);
      expect(metrics.lowStockProducts, isEmpty);
      expect(metrics.recentSales, isEmpty);
      expect(metrics.weeklySalesTrend, isEmpty);
    });
  });
}
