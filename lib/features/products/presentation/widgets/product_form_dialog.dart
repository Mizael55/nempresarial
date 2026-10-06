import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../domain/models/product_model.dart';
import '../controllers/categories_controller.dart';
import '../controllers/products_controller.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../onboarding/domain/business_settings_model.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormDialog({
    super.key,
    this.productToEdit,
  });

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _descriptionController;

  String? _selectedCategoryId;
  String _selectedUnit = 'unit';
  bool _isTaxable = true;
  bool _isLoading = false;

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(2) : '');
    _salePriceController = TextEditingController(text: p != null ? p.salePrice.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: p != null ? p.currentStock.toStringAsFixed(0) : '0');
    _minStockController = TextEditingController(text: p != null ? p.minStock.toStringAsFixed(0) : '5');
    _descriptionController = TextEditingController(text: p?.description ?? '');

    double taxRate = 18.0;
    try {
      taxRate = ref.read(onboardingControllerProvider).settings.taxRate;
    } catch (_) {}
    _selectedCategoryId = p?.categoryId;
    _selectedUnit = p?.unit ?? 'unit';
    _isTaxable = taxRate > 0 ? (p?.isTaxable ?? true) : false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _generateSku() {
    final prefix = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim().substring(0, 3).toUpperCase()
        : 'PRD';
    final randomNum = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    setState(() {
      _skuController.text = '$prefix-$randomNum';
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cost = double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final sale = double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0.0;
    final initialStock = double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0.0;
    final minStock = double.tryParse(_minStockController.text.replaceAll(',', '.')) ?? 5.0;

    final categories = ref.read(categoriesControllerProvider).categories;
    final categoryName = categories
        .where((c) => c.id == _selectedCategoryId)
        .map((c) => c.name)
        .firstOrNull;

    double settingsTaxRate = 18.0;
    try {
      settingsTaxRate = ref.read(onboardingControllerProvider).settings.taxRate;
    } catch (_) {}
    final effectiveTaxRate = (settingsTaxRate > 0 && _isTaxable) ? settingsTaxRate : 0.0;
    final effectiveIsTaxable = settingsTaxRate > 0 && _isTaxable;

    bool success;
    if (isEditing) {
      final updated = widget.productToEdit!.copyWith(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
        categoryId: _selectedCategoryId,
        categoryName: categoryName,
        unit: _selectedUnit,
        costPrice: cost,
        salePrice: sale,
        minStock: minStock,
        isTaxable: effectiveIsTaxable,
        taxRate: effectiveTaxRate,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      );
      success = await ref.read(productsControllerProvider.notifier).updateProduct(updated);
    } else {
      final newProduct = ProductModel(
        id: '',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : 'SKU-${DateTime.now().millisecondsSinceEpoch % 10000}',
        barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
        categoryId: _selectedCategoryId,
        categoryName: categoryName,
        unit: _selectedUnit,
        costPrice: cost,
        salePrice: sale,
        minStock: minStock,
        isTaxable: effectiveIsTaxable,
        taxRate: effectiveTaxRate,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      );
      success = await ref
          .read(productsControllerProvider.notifier)
          .createProduct(newProduct, initialStock: initialStock);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Producto actualizado exitosamente' : 'Producto creado exitosamente'),
            backgroundColor: AppColors.emerald600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesState = ref.watch(categoriesControllerProvider);
    BusinessSettingsModel settings = const BusinessSettingsModel(businessName: '');
    try {
      settings = ref.watch(onboardingControllerProvider).settings;
    } catch (_) {}

    // Live margin calculations
    final cost = double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final sale = double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0.0;
    final profit = sale - cost;
    final marginPercent = cost > 0 ? (profit / cost) * 100 : 0.0;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary500.withOpacity(0.12),
                            borderRadius: AppRadius.roundedMd,
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.package, color: AppColors.primary500, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Editar Producto' : 'Crear Nuevo Producto',
                                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Completa los datos del artículo para el catálogo e inventario',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Scrollable Form Sections
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: General Info
                        _buildSectionTitle('1. Información General', LucideIcons.fileText),
                        const SizedBox(height: 12),
                        NubikoTextField(
                          label: 'Nombre del Producto *',
                          hint: 'Ej. Aceite de Oliva Extra Virgen 1L',
                          controller: _nameController,
                          prefixIcon: const Icon(LucideIcons.tag, size: 18),
                          validator: (v) => Validators.required(v, 'El nombre es obligatorio'),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            // Category Dropdown
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categoría',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedCategoryId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    hint: const Text('Seleccionar categoría', overflow: TextOverflow.ellipsis),
                                    items: categoriesState.categories.map((cat) {
                                      return DropdownMenuItem(
                                        value: cat.id,
                                        child: Text(cat.name, style: AppTypography.bodyMedium, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Unit selector
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unidad',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedUnit,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'unit', child: Text('Unidad', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'kg', child: Text('Kilogramo (kg)', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'lb', child: Text('Libra (lb)', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'botella', child: Text('Botella', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'paquete', child: Text('Paquete', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'caja', child: Text('Caja', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'galon', child: Text('Galón', overflow: TextOverflow.ellipsis)),
                                    ],
                                    onChanged: (val) => setState(() => _selectedUnit = val ?? 'unit'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Section 2: Codes
                        _buildSectionTitle('2. Identificación & Códigos', LucideIcons.scanLine),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: NubikoTextField(
                                label: 'Código SKU',
                                hint: 'ALIM-001',
                                controller: _skuController,
                                prefixIcon: const Icon(LucideIcons.hash, size: 18),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: NubikoButton(
                                text: 'Generar SKU',
                                variant: NubikoButtonVariant.secondary,
                                icon: LucideIcons.wand2,
                                onPressed: _generateSku,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        NubikoTextField(
                          label: 'Código de Barras (EAN / UPC)',
                          hint: '746123456789',
                          controller: _barcodeController,
                          prefixIcon: const Icon(LucideIcons.barcode, size: 18),
                        ),
                        const SizedBox(height: 24),

                        // Section 3: Pricing & Financials
                        _buildSectionTitle('3. Precios & Rentabilidad', LucideIcons.dollarSign),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: NubikoTextField(
                                label: 'Precio de Costo *',
                                hint: '0.00',
                                controller: _costPriceController,
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(LucideIcons.arrowDownLeft, size: 18),
                                validator: (v) => Validators.number(v, 'Costo requerido'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: NubikoTextField(
                                label: 'Precio de Venta *',
                                hint: '0.00',
                                controller: _salePriceController,
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(LucideIcons.arrowUpRight, size: 18),
                                validator: (v) => Validators.number(v, 'Precio requerido'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Live Margin Metric Card
                        NubikoCard(
                          padding: const EdgeInsets.all(14),
                          backgroundColor: isDark ? AppColors.slate900 : AppColors.slate50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('Ganancia por Unidad', style: AppTypography.bodySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.currency(profit),
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: profit >= 0 ? AppColors.emerald500 : AppColors.rose500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 32, color: isDark ? AppColors.slate700 : AppColors.slate300),
                              Column(
                                children: [
                                  Text('Margen de Rentabilidad', style: AppTypography.bodySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${marginPercent >= 0 ? '+' : ''}${marginPercent.toStringAsFixed(1)}%',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: marginPercent >= 20 ? AppColors.emerald500 : AppColors.amber500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 4: Inventory & Stock Controls
                        _buildSectionTitle('4. Control de Inventario', LucideIcons.boxes),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!isEditing) ...[
                              Expanded(
                                child: NubikoTextField(
                                  label: 'Stock Inicial',
                                  hint: '0',
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(LucideIcons.packagePlus, size: 18),
                                ),
                              ),
                              const SizedBox(width: 14),
                            ],
                            Expanded(
                              child: NubikoTextField(
                                label: 'Stock Mínimo para Alerta',
                                hint: '5',
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(LucideIcons.alertTriangle, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Tax Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Aplica Impuesto (${settings.taxName.isNotEmpty ? settings.taxName : 'ITBIS'})',
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            settings.taxRate > 0
                                ? 'El producto calculará el ${settings.taxRate.toStringAsFixed(settings.taxRate % 1 == 0 ? 0 : 1)}% en las ventas'
                                : 'Impuestos desactivados en Configuración (0%). Este producto se venderá exento.',
                            style: AppTypography.bodySmall,
                          ),
                          value: settings.taxRate > 0 ? _isTaxable : false,
                          activeColor: AppColors.primary600,
                          onChanged: settings.taxRate > 0 ? (val) => setState(() => _isTaxable = val) : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        NubikoTextField(
                          label: 'Descripción o Notas del Producto',
                          hint: 'Detalles del producto o especificaciones...',
                          controller: _descriptionController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NubikoButton(
                    text: 'Cancelar',
                    variant: NubikoButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  NubikoButton(
                    text: isEditing ? 'Guardar Cambios' : 'Registrar Producto',
                    icon: LucideIcons.check,
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary500),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.slate200 : AppColors.slate800,
          ),
        ),
      ],
    );
  }
}
