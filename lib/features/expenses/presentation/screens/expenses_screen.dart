import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/nubiko_badge.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_empty_state.dart';
import '../../../../shared/widgets/nubiko_responsive_layout.dart';
import '../../../../shared/widgets/nubiko_skeleton.dart';
import '../../../../shared/widgets/nubiko_stat_card.dart';
import '../controllers/expenses_controller.dart';
import '../widgets/expense_form_dialog.dart';
import '../../domain/models/expense_model.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expensesControllerProvider.notifier).loadExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openExpenseForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ExpenseFormDialog(),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppColors.rose500, size: 22),
              SizedBox(width: 10),
              Text('Eliminar Gasto'),
            ],
          ),
          content: Text(
            '¿Deseas eliminar el registro de gasto "${expense.concept}" por ${Formatters.currency(expense.amount)}?',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose500),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(expensesControllerProvider.notifier).deleteExpense(expense.id);
                ref.read(dashboardControllerProvider.notifier).loadMetrics();
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expState = ref.watch(expensesControllerProvider);
    final isMobile = NubikoBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(expensesControllerProvider.notifier).loadExpenses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Control de Gastos & Egresos',
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registra los egresos operativos para calcular tus ganancias netas exactas',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.slate400 : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 16),
                    NubikoButton(
                      text: 'Registrar Gasto',
                      icon: LucideIcons.plus,
                      onPressed: () => _openExpenseForm(context),
                    ),
                  ],
                ],
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 24),

              // KPI Stats Grid
              _buildStatsGrid(context, expState),
              const SizedBox(height: 24),

              // Filters & Search Bar
              _buildFilterBar(context, expState, isDark),
              const SizedBox(height: 18),

              // Expenses List / Table
              if (expState.isLoading) ...[
                const NubikoSkeleton(height: 60),
                const SizedBox(height: 12),
                const NubikoSkeleton(height: 60),
                const SizedBox(height: 12),
                const NubikoSkeleton(height: 60),
              ] else if (expState.expenses.isEmpty) ...[
                NubikoCard(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: NubikoEmptyState(
                    icon: LucideIcons.receipt,
                    title: 'No hay gastos registrados',
                    description: expState.searchQuery.isNotEmpty
                        ? 'No se encontraron gastos que coincidan con "${expState.searchQuery}".'
                        : 'Aún no has registrado egresos u operaciones de caja. Mantén tus cuentas claras.',
                    actionText: 'Registrar Primer Gasto',
                    onAction: () => _openExpenseForm(context),
                  ),
                ),
              ] else ...[
                NubikoResponsiveLayout(
                  mobile: _buildMobileList(context, expState.expenses, isDark),
                  desktop: _buildDesktopTable(context, expState.expenses, isDark),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () => _openExpenseForm(context),
              backgroundColor: AppColors.primary500,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: const Text('Registrar Gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildStatsGrid(BuildContext context, ExpensesState state) {
    final isMobile = NubikoBreakpoints.isMobile(context);

    final cards = [
      NubikoStatCard(
        title: 'Gastos Totales',
        value: Formatters.currency(state.totalExpensesAmount),
        comparisonText: 'Acumulado histórico',
        icon: LucideIcons.wallet,
        iconColor: AppColors.rose500,
      ),
      NubikoStatCard(
        title: 'Gastos del Mes',
        value: Formatters.currency(state.thisMonthExpensesAmount),
        comparisonText: 'Mes en curso',
        icon: LucideIcons.calendar,
        iconColor: AppColors.amber500,
      ),
      NubikoStatCard(
        title: 'Gastos de Hoy',
        value: Formatters.currency(state.todayExpensesAmount),
        comparisonText: 'Jornada actual',
        icon: LucideIcons.clock,
        iconColor: AppColors.primary500,
      ),
      NubikoStatCard(
        title: 'Registros de Gasto',
        value: '${state.count} comprobantes',
        comparisonText: 'Total de egresos registrados',
        icon: LucideIcons.receipt,
        iconColor: AppColors.slate500,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c)))
          .toList(),
    );
  }

  Widget _buildFilterBar(BuildContext context, ExpensesState state, bool isDark) {
    return NubikoCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Búsqueda
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, minWidth: 220),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por concepto o referencia...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(expensesControllerProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.roundedMd,
                  borderSide: BorderSide(color: isDark ? AppColors.slate700 : AppColors.slate200),
                ),
              ),
              onChanged: (val) {
                ref.read(expensesControllerProvider.notifier).setSearchQuery(val);
              },
            ),
          ),

          // Filtro por Categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate50,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedCategoryId ?? 'all',
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Todas las Categorías')),
                  ...state.categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }),
                ],
                onChanged: (val) {
                  ref.read(expensesControllerProvider.notifier).setSelectedCategory(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<ExpenseModel> expenses, bool isDark) {
    return NubikoCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.roundedLg,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 850),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.slate800 : AppColors.slate100,
              ),
              dataRowMaxHeight: 64,
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Concepto / Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Referencia', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Monto Gastado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: expenses.map((e) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        Formatters.dateTime(e.createdAt),
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.concept,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (e.notes != null && e.notes!.isNotEmpty)
                            Text(
                              e.notes!,
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.slate400 : AppColors.slate500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      NubikoBadge(
                        text: e.categoryName ?? 'General',
                        variant: NubikoBadgeVariant.info,
                      ),
                    ),
                    DataCell(
                      NubikoBadge(
                        text: e.paymentMethodLabel,
                        variant: NubikoBadgeVariant.neutral,
                      ),
                    ),
                    DataCell(
                      Text(
                        e.reference ?? '-',
                        style: AppTypography.bodySmall.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                    DataCell(
                      Text(
                        '- ${Formatters.currency(e.amount)}',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.rose500,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.rose500),
                        tooltip: 'Eliminar gasto',
                        onPressed: () => _confirmDelete(context, e),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<ExpenseModel> expenses, bool isDark) {
    return Column(
      children: expenses.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NubikoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Formatters.dateTime(e.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                    Text(
                      '- ${Formatters.currency(e.amount)}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.rose500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  e.concept,
                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                if (e.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.notes!,
                    style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.slate400 : AppColors.slate600),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    NubikoBadge(text: e.categoryName ?? 'General', variant: NubikoBadgeVariant.info),
                    const SizedBox(width: 8),
                    NubikoBadge(text: e.paymentMethodLabel, variant: NubikoBadgeVariant.neutral),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.rose500),
                      onPressed: () => _confirmDelete(context, e),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
