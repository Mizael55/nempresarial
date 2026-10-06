import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_card.dart';
import '../controllers/storage_setup_controller.dart';
import '../widgets/supabase_connection_dialog.dart';

class StorageSetupScreen extends ConsumerWidget {
  const StorageSetupScreen({super.key});

  Future<void> _handleSelectLocal(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(storageSetupControllerProvider.notifier).chooseLocalStorage();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Modo Local activado! Todos los datos se guardarán en esta computadora.'),
          backgroundColor: AppColors.emerald600,
        ),
      );
      context.go('/login');
    }
  }

  void _handleOpenSupabaseModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupabaseConnectionDialog(
        onSuccess: () {
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final setupState = ref.watch(storageSetupControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App branding header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary600, AppColors.primary400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppRadius.roundedLg,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary500.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.boxes, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'NUBIKO',
                        style: AppTypography.displayMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary500.withValues(alpha: 0.15),
                          borderRadius: AppRadius.roundedFull,
                          border: Border.all(
                            color: AppColors.primary500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'CONFIGURACIÓN INICIAL',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary500,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title and subtitle
                  Text(
                    '¿Cómo deseas almacenar los datos de tu empresa?',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Elige el modo de almacenamiento para tu computadora. Puedes cambiarlo en cualquier momento desde Configuración.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Selection Cards (Local PC vs Cloud Supabase)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildLocalCard(context, ref, isDark, setupState)),
                                const SizedBox(width: 24),
                                Expanded(child: _buildCloudCard(context, ref, isDark, setupState)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildLocalCard(context, ref, isDark, setupState),
                                const SizedBox(height: 20),
                                _buildCloudCard(context, ref, isDark, setupState),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Security and default user notice
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : Colors.white,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: AppColors.emerald500, size: 18),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Ambos modos incluyen el usuario administrador predeterminado listo para iniciar sesión.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.slate300 : AppColors.slate700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    StorageSetupState setupState,
  ) {
    return NubikoCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedMd,
                ),
                child: const Center(
                  child: Icon(LucideIcons.hardDrive, color: AppColors.emerald500, size: 28),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '100% AUTÓNOMO',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.emerald500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Guardar todo en esta computadora',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Modo Local Offline. Todo se almacena directamente en tu equipo sin depender de internet.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.slate400 : AppColors.slate600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Features bullet points
          _buildBullet(isDark, LucideIcons.wifiOff, 'Funciona 100% sin internet ni caídas de red.'),
          _buildBullet(isDark, LucideIcons.zap, 'Máxima velocidad de carga y lectura instantánea.'),
          _buildBullet(isDark, LucideIcons.lock, 'Tus datos se mantienen en tu disco de forma privada.'),
          _buildBullet(isDark, LucideIcons.userCheck, 'Usuario admin precargado (admin@empresa.com / admin123456).'),
          const SizedBox(height: 24),

          // Action Button
          NubikoButton(
            text: 'Elegir Modo Local',
            icon: LucideIcons.hardDriveDownload,
            isFullWidth: true,
            isLoading: setupState.isLoading,
            onPressed: () => _handleSelectLocal(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    StorageSetupState setupState,
  ) {
    return NubikoCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedMd,
                ),
                child: const Center(
                  child: Icon(LucideIcons.cloud, color: AppColors.primary500, size: 28),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(
                    color: AppColors.primary500.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'EN LA NUBE',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Conectar a Supabase en la nube',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sincroniza tus datos en PostgreSQL en tiempo real y accede desde varios dispositivos.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.slate400 : AppColors.slate600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Features bullet points
          _buildBullet(isDark, LucideIcons.refreshCw, 'Sincronización en tiempo real entre múltiples cajas y PCs.'),
          _buildBullet(isDark, LucideIcons.database, 'Respaldos y copias de seguridad continuas en la nube.'),
          _buildBullet(isDark, LucideIcons.wrench, 'Creación y verificación automática de tablas y esquema.'),
          _buildBullet(isDark, LucideIcons.sliders, 'Prueba de conexión con 1 clic y asistente asistido.'),
          const SizedBox(height: 24),

          // Action Button
          NubikoButton(
            text: 'Conectar a Supabase...',
            icon: LucideIcons.cloudLightning,
            isFullWidth: true,
            variant: NubikoButtonVariant.secondary,
            onPressed: () => _handleOpenSupabaseModal(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(bool isDark, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.slate400 : AppColors.slate600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.slate300 : AppColors.slate700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
