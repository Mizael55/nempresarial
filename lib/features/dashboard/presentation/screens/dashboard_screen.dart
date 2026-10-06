import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_responsive_layout.dart';
import '../../../../shared/widgets/nubiko_skeleton.dart';
import '../../../../shared/widgets/nubiko_stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../expenses/presentation/widgets/expense_form_dialog.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/low_stock_card.dart';
import '../widgets/recent_sales_card.dart';
import '../widgets/sales_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardState = ref.watch(dashboardControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final metrics = dashboardState.metrics;

    if (dashboardState.isLoading) {
      return Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            const NubikoSkeleton(height: 80),
            const SizedBox(height: 24),
            Row(
              children: const [
                Expanded(child: NubikoSkeleton(height: 140)),
                SizedBox(width: 16),
                Expanded(child: NubikoSkeleton(height: 140)),
                SizedBox(width: 16),
                Expanded(child: NubikoSkeleton(height: 140)),
                SizedBox(width: 16),
                Expanded(child: NubikoSkeleton(height: 140)),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(dashboardControllerProvider.notifier).loadMetrics(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: NubikoBreakpoints.isMobile(context)
            ? AppSpacing.mobilePagePadding
            : AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Greeting & Quick Actions
            _buildDashboardHeader(context, isDark, user?.fullName ?? 'Administrador'),
            const SizedBox(height: 24),

            // Top KPI Cards Grid
            _buildKpiGrid(context, metrics),
            const SizedBox(height: 24),

            // Main Content Area: Charts & Operational Lists
            NubikoResponsiveLayout(
              mobile: Column(
                children: [
                  SalesTrendChart(dataPoints: metrics.weeklySalesTrend),
                  const SizedBox(height: 20),
                  RecentSalesCard(items: metrics.recentSales),
                  const SizedBox(height: 20),
                  LowStockCard(items: metrics.lowStockProducts),
                  const SizedBox(height: 20),
                  _buildFinancialSummaryCard(isDark, metrics),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left main analytics column
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        SalesTrendChart(dataPoints: metrics.weeklySalesTrend)
                            .animate()
                            .fadeIn(duration: 400.ms, curve: Curves.easeOut),
                        const SizedBox(height: 24),
                        RecentSalesCard(items: metrics.recentSales)
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right alerts and quick finance column
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        LowStockCard(items: metrics.lowStockProducts)
                            .animate()
                            .fadeIn(delay: 250.ms, duration: 400.ms),
                        const SizedBox(height: 24),
                        _buildFinancialSummaryCard(isDark, metrics)
                            .animate()
                            .fadeIn(delay: 350.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context, bool isDark, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, $userName!',
              style: AppTypography.displayLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aquí está el resumen financiero y operativo de tu negocio hoy.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
          ],
        ),
        if (!NubikoBreakpoints.isMobile(context))
          Row(
            children: [
              NubikoButton(
                text: 'Registrar Gasto',
                variant: NubikoButtonVariant.secondary,
                icon: LucideIcons.receipt,
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const ExpenseFormDialog(),
                  );
                },
              ),
              const SizedBox(width: 12),
              NubikoButton(
                text: 'Nueva Venta POS',
                icon: LucideIcons.shoppingBag,
                onPressed: () {
                  context.go('/sales');
                },
              ),
            ],
          ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildKpiGrid(BuildContext context, dynamic metrics) {
    final isMobile = NubikoBreakpoints.isMobile(context);

    final cards = [
      NubikoStatCard(
        title: 'Ventas de Hoy',
        value: Formatters.currency(metrics.salesToday),
        comparisonText: 'respecto a ayer',
        percentageChange: metrics.salesTodayDelta,
        icon: LucideIcons.trendingUp,
        iconColor: AppColors.emerald500,
      ).animate().fadeIn(duration: 300.ms),
      NubikoStatCard(
        title: 'Ventas de la Semana',
        value: Formatters.currency(metrics.salesWeek),
        comparisonText: 'vs semana anterior',
        percentageChange: metrics.salesWeekDelta,
        icon: LucideIcons.calendar,
        iconColor: AppColors.primary500,
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
      NubikoStatCard(
        title: 'Ganancia Neta (Mes)',
        value: Formatters.currency(metrics.netProfit),
        comparisonText: 'margen saludable',
        percentageChange: metrics.salesMonthDelta,
        icon: LucideIcons.dollarSign,
        iconColor: AppColors.emerald500,
      ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
      NubikoStatCard(
        title: 'Cuentas por Cobrar',
        value: Formatters.currency(metrics.accountsReceivable),
        comparisonText: '5 clientes pendientes',
        icon: LucideIcons.clock,
        iconColor: AppColors.amber500,
      ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }

    return Row(
      children: cards
          .map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildFinancialSummaryCard(bool isDark, dynamic metrics) {
    return NubikoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(LucideIcons.pieChart, size: 16, color: AppColors.emerald500),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Balance del Mes',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFinancialRow(
            'Ingresos Totales',
            Formatters.currency(metrics.totalIncome),
            AppColors.emerald500,
            LucideIcons.arrowDownLeft,
            isDark,
          ),
          Divider(color: isDark ? AppColors.slate800 : AppColors.slate100, height: 24),
          _buildFinancialRow(
            'Gastos Operativos',
            Formatters.currency(metrics.totalExpenses),
            AppColors.rose500,
            LucideIcons.arrowUpRight,
            isDark,
          ),
          Divider(color: isDark ? AppColors.slate800 : AppColors.slate100, height: 24),
          _buildFinancialRow(
            'Cuentas por Pagar',
            Formatters.currency(metrics.accountsPayable),
            AppColors.amber500,
            LucideIcons.clock,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.slate300 : AppColors.slate700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
        ),
      ],
    );
  }
}
