import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/purchases_controller.dart';
import '../../domain/models/supplier_model.dart';
import 'supplier_form_dialog.dart';
import 'supplier_payment_dialog.dart';

class SuppliersListView extends ConsumerStatefulWidget {
  const SuppliersListView({super.key});

  @override
  ConsumerState<SuppliersListView> createState() => _SuppliersListViewState();
}

class _SuppliersListViewState extends ConsumerState<SuppliersListView> {
  final _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSupplierForm([SupplierModel? supplier]) {
    showDialog(
      context: context,
      builder: (ctx) => SupplierFormDialog(supplier: supplier),
    );
  }

  void _openPaymentDialog(SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (ctx) => SupplierPaymentDialog(supplier: supplier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suppliersAsync = ref.watch(suppliersListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior de búsqueda y botón nuevo
        Row(
          children: [
            Expanded(
              child: NubikoTextField(
                controller: _searchController,
                hintText: 'Buscar por nombre, RNC o contacto...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                onChanged: (val) {
                  ref.read(suppliersSearchQueryProvider.notifier).state = val.trim();
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
              ),
              onPressed: () => _openSupplierForm(),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Nuevo Proveedor'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Listado de Proveedores
        Expanded(
          child: suppliersAsync.when(
            data: (suppliers) {
              if (suppliers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.building, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('No hay proveedores registrados', style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Agregue los datos de sus distribuidores para asociar facturas de compra y cuentas por pagar.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = suppliers[index];
                  final hasDebt = s.currentDebt > 0;

                  return NubikoCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: AppRadius.roundedMd,
                          ),
                          child: const Icon(LucideIcons.building2, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s.name,
                                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                                  if (s.taxId != null && s.taxId!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurface : AppColors.lightBorder,
                                        borderRadius: AppRadius.roundedSm,
                                      ),
                                      child: Text('RNC: ${s.taxId}', style: AppTypography.bodySmall),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 14,
                                children: [
                                  if (s.contactName != null && s.contactName!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.user, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(s.contactName!, style: AppTypography.bodySmall),
                                      ],
                                    ),
                                  if (s.phone != null && s.phone!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.phone, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(s.phone!, style: AppTypography.bodySmall),
                                      ],
                                    ),
                                  if (s.email != null && s.email!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.mail, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(s.email!, style: AppTypography.bodySmall),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Balance Deuda
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Cuentas por Pagar', style: AppTypography.bodySmall),
                            Text(
                              currencyFormat.format(s.currentDebt),
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasDebt ? AppColors.warning : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Botones de Acción
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasDebt)
                              IconButton.filledTonal(
                                tooltip: 'Abonar a Deuda',
                                icon: const Icon(LucideIcons.handCoins, size: 16),
                                onPressed: () => _openPaymentDialog(s),
                              ),
                            IconButton.outlined(
                              tooltip: 'Editar Datos',
                              icon: const Icon(LucideIcons.pencil, size: 16),
                              onPressed: () => _openSupplierForm(s),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
