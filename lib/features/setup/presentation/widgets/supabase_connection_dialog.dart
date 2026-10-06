import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../controllers/storage_setup_controller.dart';

class SupabaseConnectionDialog extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const SupabaseConnectionDialog({super.key, this.onSuccess});

  @override
  ConsumerState<SupabaseConnectionDialog> createState() => _SupabaseConnectionDialogState();
}

class _SupabaseConnectionDialogState extends ConsumerState<SupabaseConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _keyController;
  bool _showSql = false;

  @override
  void initState() {
    super.initState();
    final setupState = ref.read(storageSetupControllerProvider);
    _urlController = TextEditingController(
      text: setupState.supabaseUrl.isNotEmpty ? setupState.supabaseUrl : EnvConfig.supabaseUrl,
    );
    _keyController = TextEditingController(
      text: setupState.supabaseAnonKey.isNotEmpty ? setupState.supabaseAnonKey : EnvConfig.supabaseAnonKey,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection() async {
    final controller = ref.read(storageSetupControllerProvider.notifier);
    await controller.testConnection(
      url: _urlController.text.trim(),
      anonKey: _keyController.text.trim(),
    );
  }

  Future<void> _handleConnectAndSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(storageSetupControllerProvider.notifier);
    final success = await controller.connectAndSetupCloud(
      url: _urlController.text.trim(),
      anonKey: _keyController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Base de datos Supabase conectada exitosamente!'),
          backgroundColor: AppColors.emerald600,
        ),
      );
      Navigator.of(context).pop(true);
      widget.onSuccess?.call();
    }
  }

  void _fillDefaultCredentials() {
    setState(() {
      _urlController.text = EnvConfig.supabaseUrl;
      _keyController.text = EnvConfig.supabaseAnonKey;
    });
  }

  void _copySqlToClipboard() {
    Clipboard.setData(ClipboardData(text: StorageSetupController.supabaseSqlSchema));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código SQL copiado al portapapeles.'),
        backgroundColor: AppColors.primary600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final setupState = ref.watch(storageSetupControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      backgroundColor: isDark ? AppColors.slate900 : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                          color: AppColors.primary500.withValues(alpha: 0.15),
                          borderRadius: AppRadius.roundedMd,
                        ),
                        child: const Icon(LucideIcons.database, color: AppColors.primary500, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conectar a Base de Datos en la Nube',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configura tu instancia de Supabase para sincronización continua.',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.slate400 : AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick fill suggestion
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate50,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.sparkles, color: AppColors.amber500, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿Tienes credenciales existentes o deseas autocompletar?',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.slate300 : AppColors.slate700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _fillDefaultCredentials,
                          child: const Text('Rellenar Predeterminados'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // URL Field
                  NubikoTextField(
                    label: 'URL de Supabase (Project URL)',
                    hint: 'https://ejemplo.supabase.co',
                    controller: _urlController,
                    prefixIcon: const Icon(LucideIcons.globe, size: 18),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'La URL es requerida';
                      if (!v.trim().startsWith('http')) return 'Debe iniciar con https://';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Anon / Service Key Field
                  NubikoTextField(
                    label: 'Clave de API de Supabase (Anon Key / API Key)',
                    hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                    controller: _keyController,
                    maxLines: 2,
                    prefixIcon: const Icon(LucideIcons.key, size: 18),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'La clave de API es requerida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Test Connection Feedback Banner
                  if (setupState.testMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: setupState.isTestingSuccess == true
                            ? (isDark ? AppColors.emerald700.withValues(alpha: 0.2) : AppColors.emerald50)
                            : (isDark ? AppColors.rose700.withValues(alpha: 0.2) : AppColors.rose50),
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(
                          color: setupState.isTestingSuccess == true
                              ? AppColors.emerald500.withValues(alpha: 0.4)
                              : AppColors.rose500.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            setupState.isTestingSuccess == true
                                ? LucideIcons.checkCircle2
                                : LucideIcons.alertCircle,
                            color: setupState.isTestingSuccess == true
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              setupState.testMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: setupState.isTestingSuccess == true
                                    ? AppColors.emerald600
                                    : AppColors.rose600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons: Probar Conexión & Conectar y Crear Tablas
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: setupState.isTesting ? null : _handleTestConnection,
                          icon: setupState.isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.activity, size: 16),
                          label: Text(setupState.isTesting ? 'Probando...' : 'Probar Conexión'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark ? AppColors.slate700 : AppColors.slate300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.roundedMd,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NubikoButton(
                          text: 'Conectar y Crear Tablas',
                          icon: LucideIcons.cloudLightning,
                          isLoading: setupState.isSettingUpTables,
                          onPressed: _handleConnectAndSetup,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Toggle SQL Schema Script Accordion
                  InkWell(
                    onTap: () => setState(() => _showSql = !_showSql),
                    borderRadius: AppRadius.roundedMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            _showSql ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.primary500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ver Script SQL para Supabase (Opcional)',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showSql) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(
                          color: isDark ? AppColors.slate800 : AppColors.slate200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Esquema PostgreSQL:',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _copySqlToClipboard,
                                icon: const Icon(LucideIcons.copy, size: 14),
                                label: const Text('Copiar SQL'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 140,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                              borderRadius: AppRadius.roundedSm,
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                StorageSetupController.supabaseSqlSchema,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: isDark ? AppColors.slate300 : AppColors.slate700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
