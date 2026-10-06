class DashboardMetrics {
  final double salesToday;
  final double salesTodayDelta;
  final double salesWeek;
  final double salesWeekDelta;
  final double salesMonth;
  final double salesMonthDelta;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double accountsReceivable;
  final double accountsPayable;
  final List<LowStockItem> lowStockProducts;
  final List<RecentSaleItem> recentSales;
  final List<double> weeklySalesTrend; // 7 days trend

  const DashboardMetrics({
    this.salesToday = 0.0,
    this.salesTodayDelta = 0.0,
    this.salesWeek = 0.0,
    this.salesWeekDelta = 0.0,
    this.salesMonth = 0.0,
    this.salesMonthDelta = 0.0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.accountsReceivable = 0.0,
    this.accountsPayable = 0.0,
    this.lowStockProducts = const [],
    this.recentSales = const [],
    this.weeklySalesTrend = const [0, 0, 0, 0, 0, 0, 0],
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final lowStockRaw = json['low_stock_products'] as List<dynamic>? ?? [];
    final recentSalesRaw = json['recent_sales'] as List<dynamic>? ?? [];
    final trendRaw = json['weekly_sales_trend'] as List<dynamic>? ?? [];

    return DashboardMetrics(
      salesToday: (json['sales_today'] as num?)?.toDouble() ?? 0.0,
      salesTodayDelta: (json['sales_today_delta'] as num?)?.toDouble() ?? 0.0,
      salesWeek: (json['sales_week'] as num?)?.toDouble() ?? 0.0,
      salesWeekDelta: (json['sales_week_delta'] as num?)?.toDouble() ?? 0.0,
      salesMonth: (json['sales_month'] as num?)?.toDouble() ?? 0.0,
      salesMonthDelta: (json['sales_month_delta'] as num?)?.toDouble() ?? 0.0,
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
      accountsReceivable: (json['accounts_receivable'] as num?)?.toDouble() ?? 0.0,
      accountsPayable: (json['accounts_payable'] as num?)?.toDouble() ?? 0.0,
      lowStockProducts: lowStockRaw.map((e) {
        final map = e as Map<String, dynamic>;
        return LowStockItem(
          id: map['id'] as String? ?? '',
          name: map['name'] as String? ?? '',
          sku: map['sku'] as String? ?? '',
          currentStock: (map['current_stock'] as num?)?.toDouble() ?? 0.0,
          minStock: (map['min_stock'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList(),
      recentSales: recentSalesRaw.map((e) {
        final map = e as Map<String, dynamic>;
        final createdAtStr = map['created_at'] as String?;
        String timeAgo = 'Reciente';
        if (createdAtStr != null) {
          final dt = DateTime.tryParse(createdAtStr);
          if (dt != null) {
            final diff = DateTime.now().difference(dt);
            if (diff.inMinutes < 60) {
              timeAgo = 'Hace ${diff.inMinutes < 1 ? 1 : diff.inMinutes}m';
            } else if (diff.inHours < 24) {
              timeAgo = 'Hace ${diff.inHours}h';
            } else {
              timeAgo = 'Hace ${diff.inDays}d';
            }
          }
        }
        return RecentSaleItem(
          id: map['id'] as String? ?? '',
          invoiceNumber: map['invoice_number'] as String? ?? '',
          customerName: map['customer_name'] as String? ?? 'Consumidor Final',
          total: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: map['payment_method'] as String? ?? 'cash',
          timeAgo: timeAgo,
        );
      }).toList(),
      weeklySalesTrend: trendRaw.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class LowStockItem {
  final String id;
  final String name;
  final String sku;
  final double currentStock;
  final double minStock;

  const LowStockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.minStock,
  });
}

class RecentSaleItem {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final double total;
  final String paymentMethod;
  final String timeAgo;

  const RecentSaleItem({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.total,
    required this.paymentMethod,
    required this.timeAgo,
  });
}
