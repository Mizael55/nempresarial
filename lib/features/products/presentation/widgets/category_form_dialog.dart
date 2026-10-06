import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/categories_controller.dart';
import '../../domain/models/category_model.dart';

class CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? categoryToEdit;

  const CategoryFormDialog({
    super.key,
    this.categoryToEdit,
  });

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;
  late String _selectedIcon;
  bool _isLoading = false;

  final List<String> _presetColors = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#64748B', // Slate
  ];

  final List<String> _presetIcons = [
    'tag',
    'package',
    'coffee',
    'laptop',
    'shirt',
    'sparkles',
    'shopping-bag',
    'wrench',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.categoryToEdit?.description ?? '');
    _selectedColor = widget.categoryToEdit?.color ?? '#3B82F6';
    _selectedIcon = widget.categoryToEdit?.icon ?? 'tag';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary500;
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'tag':
        return LucideIcons.tag;
      case 'package':
        return LucideIcons.package;
      case 'coffee':
        return LucideIcons.coffee;
      case 'laptop':
        return LucideIcons.laptop;
      case 'shirt':
        return LucideIcons.shirt;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'shopping-bag':
        return LucideIcons.shoppingBag;
      case 'wrench':
        return LucideIcons.wrench;
      default:
        return LucideIcons.folder;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isEditing = widget.categoryToEdit != null;
    final catData = CategoryModel(
      id: widget.categoryToEdit?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      color: _selectedColor,
      icon: _selectedIcon,
      isActive: widget.categoryToEdit?.isActive ?? true,
    );

    final success = isEditing
        ? await ref.read(categoriesControllerProvider.notifier).updateCategory(catData)
        : await ref.read(categoriesControllerProvider.notifier).createCategory(catData);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Categoría actualizada con éxito' : 'Categoría creada con éxito',
            ),
            backgroundColor: AppColors.emerald600,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la categoría'),
            backgroundColor: AppColors.rose600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.categoryToEdit != null;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _parseHex(_selectedColor).withOpacity(0.15),
                            borderRadius: AppRadius.roundedMd,
                          ),
                          child: Icon(
                            _getIconData(_selectedIcon),
                            color: _parseHex(_selectedColor),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                          style: AppTypography.titleLarge,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name field
                NubikoTextField(
                  label: 'Nombre de la categoría',
                  hint: 'Ej: Bebidas, Ropa, Electrónica',
                  controller: _nameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre' : null,
                ),
                const SizedBox(height: 16),

                // Description field
                NubikoTextField(
                  label: 'Descripción (Opcional)',
                  hint: 'Breve descripción de los productos en este grupo',
                  controller: _descriptionController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Color picker palette
                Text(
                  'Color de Identificación',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetColors.map((colorHex) {
                    final color = _parseHex(colorHex);
                    final isSelected = _selectedColor == colorHex;
                    return InkWell(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      borderRadius: AppRadius.roundedFull,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Icon picker palette
                Text(
                  'Ícono',
                  style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetIcons.map((iconName) {
                    final iconData = _getIconData(iconName);
                    final isSelected = _selectedIcon == iconName;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = iconName),
                      borderRadius: AppRadius.roundedMd,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary500.withOpacity(0.15)
                              : (isDark ? AppColors.slate800 : AppColors.slate100),
                          borderRadius: AppRadius.roundedMd,
                          border: isSelected
                              ? Border.all(color: AppColors.primary500, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          iconData,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary500
                              : (isDark ? AppColors.slate300 : AppColors.slate600),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NubikoButton(
                      text: 'Cancelar',
                      variant: NubikoButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    NubikoButton(
                      text: isEditing ? 'Guardar Cambios' : 'Crear Categoría',
                      variant: NubikoButtonVariant.primary,
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
