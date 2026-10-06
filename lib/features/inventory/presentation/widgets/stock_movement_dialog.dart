import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../products/presentation/controllers/products_controller.dart';
import '../controllers/inventory_controller.dart';
import '../../domain/models/inventory_item_model.dart';

class StockMovementDialog extends ConsumerStatefulWidget {
  final InventoryItemModel? initialItem;

  const StockMovementDialog({super.key, this.initialItem});

  @override
  ConsumerState<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends ConsumerState<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductId;
  String _selectedMovementType = 'adjustment_in';
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _selectedProductId = widget.initialItem!.productId;
      _costController.text = widget.initialItem!.costPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un producto.'),
          backgroundColor: AppColors.rose500,
        ),
      );
      return;
    }

    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    final cost = double.tryParse(_costController.text);

    final success = await ref.read(inventoryControllerProvider.notifier).recordMovement(
          productId: _selectedProductId!,
          movementType: _selectedMovementType,
          quantity: qty,
          unitCost: cost,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento de inventario guardado con éxito.'),
          backgroundColor: AppColors.emerald600,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsState = ref.watch(productsControllerProvider);
    final inventoryState = ref.watch(inventoryControllerProvider);

    return Dialog(
      backgroundColor: isDark ? AppColors.slate900 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withValues(alpha: 0.12),
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: const Icon(LucideIcons.arrowUpDown, color: AppColors.primary500, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Movimiento de Inventario',
                            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Entradas, salidas o ajustes directos de stock',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.slate400 : AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Product Selector
                Text(
                  'Producto *',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.slate300 : AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.package, size: 18),
                    hintText: 'Seleccionar producto...',
                    filled: true,
                    fillColor: isDark ? AppColors.slate950 : AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.roundedMd,
                      borderSide: BorderSide(color: isDark ? AppColors.slate800 : AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedMd,
                      borderSide: BorderSide(color: isDark ? AppColors.slate800 : AppColors.slate200),
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.slate900 : Colors.white,
                  items: productsState.products.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Text('${p.name} (SKU: ${p.sku})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProductId = val;
                      final p = productsState.products.firstWhere((item) => item.id == val);
                      _costController.text = p.costPrice.toStringAsFixed(2);
                    });
                  },
                  validator: (v) => v == null ? 'Selecciona un producto' : null,
                ),
                const SizedBox(height: 18),

                // Movement Type Radio Selector
                Text(
                  'Tipo de Operación',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.slate300 : AppColors.slate700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('Entrada (+)', 'adjustment_in', LucideIcons.arrowDownLeft, AppColors.emerald500),
                    _buildTypeChip('Salida (-)', 'adjustment_out', LucideIcons.arrowUpRight, AppColors.rose500),
                    _buildTypeChip('Compra (+)', 'purchase', LucideIcons.shoppingCart, AppColors.primary500),
                    _buildTypeChip('Inventario Inicial', 'initial', LucideIcons.archive, AppColors.amber500),
                  ],
                ),
                const SizedBox(height: 18),

                // Quantity and Unit Cost
                Row(
                  children: [
                    Expanded(
                      child: NubikoTextField(
                        label: 'Cantidad *',
                        hint: '0.00',
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(LucideIcons.hash, size: 18),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          final numVal = double.tryParse(v);
                          if (numVal == null || numVal <= 0) return 'Mayor a 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NubikoTextField(
                        label: 'Costo Unitario (RD\$)',
                        hint: '0.00',
                        controller: _costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(LucideIcons.badgePercent, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes / Reason
                NubikoTextField(
                  label: 'Motivo o Referencia',
                  hint: 'Ej. Factura proveedor #4892, conteo físico de fin de mes...',
                  controller: _notesController,
                  maxLines: 2,
                  prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      NubikoButton(
                        text: 'Guardar Movimiento',
                        icon: LucideIcons.check,
                        isLoading: inventoryState.isSubmitting,
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon, Color color) {
    final isSelected = _selectedMovementType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedMovementType = value),
      selectedColor: color,
      backgroundColor: isDark ? AppColors.slate950 : AppColors.slate100,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: isSelected ? Colors.white : (isDark ? AppColors.slate300 : AppColors.slate700),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
