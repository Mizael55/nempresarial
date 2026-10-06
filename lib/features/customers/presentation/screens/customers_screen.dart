import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_stat_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/customers_controller.dart';
import '../widgets/customer_form_dialog.dart';
import '../widgets/customers_list_view.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const CustomerFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersAsync = ref.watch(customersListProvider);
    final onlyDebt = ref.watch(customersFilterDebtOnlyProvider);

    // Métricas calculadas
    final customers = customersAsync.value ?? [];
    final totalCustomers = customers.length;
    final inDebtCustomers = customers.where((c) => c.hasDebt).length;
    final totalDebtAmount = customers.fold(0.0, (sum, c) => sum + c.currentBalance);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra Superior Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 780;

                  final headerTitle = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: AppRadius.roundedMd,
                            ),
                            child: const Icon(LucideIcons.users, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Clientes & Cuentas por Cobrar (CXC)',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Directorio comercial, crédito autorizado y control de cobros',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );

                  final newButton = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                    ),
                    onPressed: _openNewCustomerDialog,
                    icon: const Icon(LucideIcons.userPlus, size: 18),
                    label: const Text('Nuevo Cliente'),
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: headerTitle),
                        newButton,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        headerTitle,
                        const SizedBox(height: 12),
                        newButton,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 18),

              // KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 800;

                  final stat1 = NubikoStatCard(
                    title: 'Total Clientes',
                    value: '$totalCustomers',
                    icon: LucideIcons.users,
                    comparisonText: 'Cartera activa',
                  );

                  final stat2 = NubikoStatCard(
                    title: 'Clientes con Deuda',
                    value: '$inDebtCustomers',
                    icon: LucideIcons.badgeAlert,
                    comparisonText: 'En cuentas por cobrar',
                  );

                  final stat3 = NubikoStatCard(
                    title: 'Cartera por Cobrar',
                    value: currencyFormat.format(totalDebtAmount),
                    icon: LucideIcons.dollarSign,
                    comparisonText: 'Balance pendiente total',
                  );

                  if (isDesktop) {
                    return Row(
                      children: [
                        Expanded(child: stat1),
                        const SizedBox(width: 14),
                        Expanded(child: stat2),
                        const SizedBox(width: 14),
                        Expanded(child: stat3),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        stat1,
                        const SizedBox(height: 10),
                        stat2,
                        const SizedBox(height: 10),
                        stat3,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 18),

              // Buscador y Filtros
              Row(
                children: [
                  Expanded(
                    child: NubikoTextField(
                      controller: _searchController,
                      hintText: 'Buscar cliente por nombre, RNC o teléfono...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      onChanged: (val) {
                        ref.read(customersSearchQueryProvider.notifier).state = val.trim();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Refrescar',
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () => ref.read(customersListProvider.notifier).refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Chips de filtro
              Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: !onlyDebt,
                    onSelected: (_) => ref.read(customersFilterDebtOnlyProvider.notifier).state = false,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Con Deuda Pendiente'),
                        if (inDebtCustomers > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$inDebtCustomers',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: onlyDebt,
                    onSelected: (_) => ref.read(customersFilterDebtOnlyProvider.notifier).state = true,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Lista Principal
              const Expanded(
                child: CustomersListView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
