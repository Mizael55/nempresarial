import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../products/presentation/controllers/products_controller.dart';
import '../controllers/purchases_controller.dart';
import 'supplier_form_dialog.dart';

class NewPurchaseView extends ConsumerStatefulWidget {
  final VoidCallback onPurchaseCompleted;

  const NewPurchaseView({super.key, required this.onPurchaseCompleted});

  @override
  ConsumerState<NewPurchaseView> createState() => _NewPurchaseViewState();
}

class _NewPurchaseViewState extends ConsumerState<NewPurchaseView> {
  final _searchProductController = TextEditingController();
  final _invoiceNumController = TextEditingController();
  final _notesController = TextEditingController();
  String _productSearchQuery = '';

  final currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void dispose() {
    _searchProductController.dispose();
    _invoiceNumController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const SupplierFormDialog(),
    );
  }

  Future<void> _processPurchase() async {
    final state = ref.read(newPurchaseControllerProvider);
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos un producto a la compra'), backgroundColor: AppColors.warning),
      );
      return;
    }

    try {
      final res = await ref.read(newPurchaseControllerProvider.notifier).submitPurchase();
      if (mounted) {
        _invoiceNumController.clear();
        _notesController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Compra ${res['purchase_number']} procesada con éxito! Stock actualizado en inventario.'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onPurchaseCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar compra: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchaseState = ref.watch(newPurchaseControllerProvider);
    final productsState = ref.watch(productsControllerProvider);
    final suppliersAsync = ref.watch(suppliersListProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 920;

        final productCatalogWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buscador de productos
            NubikoTextField(
              controller: _searchProductController,
              hintText: 'Buscar productos por nombre, SKU o código de barra...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              onChanged: (val) => setState(() => _productSearchQuery = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),

            // Lista de productos para agregar a la compra
            Expanded(
              child: productsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        final products = productsState.products.where((p) {
                          if (_productSearchQuery.isEmpty) return true;
                          return p.name.toLowerCase().contains(_productSearchQuery) ||
                              p.sku.toLowerCase().contains(_productSearchQuery) ||
                              (p.barcode?.toLowerCase().contains(_productSearchQuery) ?? false);
                        }).toList();

                        if (products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.packageOpen, size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text('No se encontraron productos', style: AppTypography.bodySmall),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = products[index];
                            final isInCart = purchaseState.items.any((it) => it.product.id == p.id);

                            return NubikoCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: AppRadius.roundedSm,
                                    ),
                                    child: const Icon(LucideIcons.package, color: AppColors.primary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                        Row(
                                          children: [
                                            Text('SKU: ${p.sku}', style: AppTypography.bodySmall),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Costo Actual: ${currencyFormat.format(p.costPrice)}',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: isInCart ? AppColors.success : AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                                    ),
                                    icon: Icon(isInCart ? LucideIcons.plus : LucideIcons.shoppingBag, size: 16),
                                    tooltip: 'Agregar a la compra',
                                    onPressed: () {
                                      ref.read(newPurchaseControllerProvider.notifier).addProduct(p);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );

        final orderSummaryWidget = Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.roundedXl,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado del Resumen
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.fileCheck, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Detalle de Factura de Compra',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (purchaseState.items.isNotEmpty)
                          TextButton(
                            onPressed: () => ref.read(newPurchaseControllerProvider.notifier).clear(),
                            child: const Text('Limpiar', style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Selector de Proveedor
                    suppliersAsync.when(
                      data: (suppliers) {
                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.roundedMd,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: purchaseState.selectedSupplier?.id,
                                    isExpanded: true,
                                    hint: const Text('Seleccionar Proveedor...'),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Proveedor Genérico / Sin Registro'),
                                      ),
                                      ...suppliers.map((s) => DropdownMenuItem<String?>(
                                            value: s.id,
                                            child: Text('${s.name} ${s.taxId != null ? "(${s.taxId})" : ""}'),
                                          )),
                                    ],
                                    onChanged: (id) {
                                      if (id == null) {
                                        ref.read(newPurchaseControllerProvider.notifier).setSupplier(null);
                                      } else {
                                        final supp = suppliers.firstWhere((s) => s.id == id);
                                        ref.read(newPurchaseControllerProvider.notifier).setSupplier(supp);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: _showAddSupplierDialog,
                              icon: const Icon(LucideIcons.userPlus, size: 16),
                              tooltip: 'Nuevo Proveedor',
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Error al cargar proveedores'),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: NubikoTextField(
                            controller: _invoiceNumController,
                            hintText: '# Factura / NCF Proveedor',
                            prefixIcon: const Icon(LucideIcons.hash, size: 18),
                            onChanged: (val) =>
                                ref.read(newPurchaseControllerProvider.notifier).setCustomInvoiceNumber(val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.roundedMd,
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: purchaseState.paymentStatus,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'paid', child: Text('Contado (Pagado)')),
                                  DropdownMenuItem(value: 'pending', child: Text('A Crédito (Pendiente)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(newPurchaseControllerProvider.notifier).setPaymentStatus(val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Lista de productos seleccionados
              Expanded(
                child: purchaseState.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.shoppingCart, size: 36, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('Agregue productos del catálogo izquierdo', style: AppTypography.bodySmall),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: purchaseState.items.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 14,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final item = purchaseState.items[index];

                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                    Text('Costo unitario:', style: AppTypography.bodySmall),
                                  ],
                                ),
                              ),
                              // Cantidad recibida (+/-)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.minus, size: 14),
                                    onPressed: () => ref
                                        .read(newPurchaseControllerProvider.notifier)
                                        .updateQuantity(item.product.id, item.quantity - 1),
                                  ),
                                  Text(
                                    item.quantity.toStringAsFixed(0),
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.plus, size: 14),
                                    onPressed: () => ref
                                        .read(newPurchaseControllerProvider.notifier)
                                        .updateQuantity(item.product.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                              // Costo unitario editable
                              SizedBox(
                                width: 85,
                                child: TextFormField(
                                  initialValue: item.unitCost.toStringAsFixed(2),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    prefixText: 'RD\$',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: AppRadius.roundedSm),
                                  ),
                                  style: AppTypography.bodySmall,
                                  onChanged: (val) {
                                    final cost = double.tryParse(val) ?? item.unitCost;
                                    ref.read(newPurchaseControllerProvider.notifier).updateCost(item.product.id, cost);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Total renglón
                              SizedBox(
                                width: 75,
                                child: Text(
                                  currencyFormat.format(item.total),
                                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                                onPressed: () =>
                                    ref.read(newPurchaseControllerProvider.notifier).removeItem(item.product.id),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Barra de totales y confirmación
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  borderRadius: BorderRadius.only(
                    bottomLeft: AppRadius.roundedXl.bottomLeft,
                    bottomRight: AppRadius.roundedXl.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal:', style: AppTypography.bodySmall),
                        Text(currencyFormat.format(purchaseState.subtotal), style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: purchaseState.applyTax,
                              onChanged: (v) =>
                                  ref.read(newPurchaseControllerProvider.notifier).toggleApplyTax(v ?? true),
                            ),
                            Text('Aplicar ITBIS (18%):', style: AppTypography.bodySmall),
                          ],
                        ),
                        Text(currencyFormat.format(purchaseState.taxAmount), style: AppTypography.bodySmall),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL COMPRA:',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormat.format(purchaseState.totalAmount),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    NubikoButton(
                      text: 'Registrar Compra & Entrada a Stock',
                      icon: LucideIcons.truck,
                      isLoading: purchaseState.isSubmitting,
                      onPressed: purchaseState.items.isEmpty ? null : _processPurchase,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: productCatalogWidget),
              const SizedBox(width: 18),
              Expanded(flex: 6, child: orderSummaryWidget),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: productCatalogWidget),
              const SizedBox(height: 16),
              Expanded(flex: 5, child: orderSummaryWidget),
            ],
          );
        }
      },
    );
  }
}
