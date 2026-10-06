import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/nubiko_button.dart';
import '../../../../shared/widgets/nubiko_responsive_layout.dart';
import '../../../../shared/widgets/nubiko_text_field.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (success && mounted) {
      await ref.read(onboardingControllerProvider.notifier).checkBusinessProfileStatus();

      if (mounted) {
        final isCompleted = ref.read(onboardingControllerProvider).isCompleted;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido! Sesión iniciada correctamente.'),
            backgroundColor: AppColors.emerald600,
            duration: Duration(seconds: 2),
          ),
        );
        if (isCompleted) {
          context.go('/dashboard');
        } else {
          context.go('/onboarding');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: NubikoResponsiveLayout(
        // Mobile Layout
        mobile: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildFormCard(context, isDark, authState),
              ),
            ),
          ),
        ),
        // Desktop Layout (Split View with Brand Showcase)
        desktop: Row(
          children: [
            // Left Showcase Panel
            Expanded(
              flex: 5,
              child: _buildBrandingShowcase(context, isDark),
            ),
            // Right Login Form Panel
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _buildFormCard(context, isDark, authState),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingShowcase(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B),
                  const Color(0xFF1E1B4B),
                ]
              : [
                  const Color(0xFF1E3A8A),
                  const Color(0xFF2563EB),
                  const Color(0xFF3B82F6),
                ],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          // Logo & Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(LucideIcons.boxes, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'NUBIKO',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withOpacity(0.2),
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.emerald400.withOpacity(0.4)),
                ),
                child: Text(
                  'ENTERPRISE',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.emerald400,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          // Central Value Proposition
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: AppRadius.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, color: AppColors.amber400, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Gestión Empresarial de Nueva Generación',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Control total sobre tus ventas, stock y finanzas.',
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu negocio opera más rápido con terminal de ventas POS, inventario en tiempo real, control de caja y reportes financieros sin interrupciones.',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              // Feature highlights pills
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFeatureChip(LucideIcons.zap, 'POS Ultrarrápido'),
                  _buildFeatureChip(LucideIcons.package, 'Inventario en Tiempo Real'),
                  _buildFeatureChip(LucideIcons.shieldCheck, 'Instancia Dedicada Segura'),
                  _buildFeatureChip(LucideIcons.wifiOff, 'Resistencia Offline'),
                ],
              ),
            ],
          ),

          // Footer info
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 NUBIKO Enterprise Platform',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.lock, color: Colors.white60, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'PostgreSQL & Supabase Secured',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDark, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile header / theme switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary600,
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.boxes, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'NUBIKO',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isDark ? LucideIcons.sun : LucideIcons.moon,
                  size: 20,
                  color: isDark ? AppColors.amber400 : AppColors.slate600,
                ),
                tooltip: 'Cambiar tema',
                onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenido de nuevo',
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus credenciales para acceder al sistema empresarial.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: 28),

          // Error Alert banner if any
          if (authState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.rose500.withOpacity(0.15)
                    : AppColors.rose50,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(
                  color: isDark ? AppColors.rose500.withOpacity(0.3) : AppColors.rose100,
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.rose500, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authState.errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.rose600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Email Input
          NubikoTextField(
            label: 'Correo Electrónico',
            hint: 'ejemplo@negocio.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(LucideIcons.mail, size: 18),
            validator: Validators.email,
          ),
          const SizedBox(height: 18),

          // Password Input
          NubikoTextField(
            label: 'Contraseña',
            hint: '••••••••',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            validator: Validators.password,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 14),

          // Remember & Forgot password
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (_) {},
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    activeColor: AppColors.primary600,
                  ),
                  Text(
                    'Recordarme',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor contacta al administrador de tu sistema.'),
                    ),
                  );
                },
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          NubikoButton(
            text: 'Iniciar Sesión',
            isFullWidth: true,
            icon: LucideIcons.logIn,
            isLoading: authState.isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 24),

          // Default Credentials Hint Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : AppColors.slate50,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.primary500),
                    const SizedBox(width: 8),
                    Text(
                      'Acceso Administrativo Inicial',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate950 : Colors.white,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(
                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Usuario: ',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.slate400 : AppColors.slate600,
                            ),
                          ),
                          Text(
                            'admin@empresa.com',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Contraseña: ',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.slate400 : AppColors.slate600,
                            ),
                          ),
                          Text(
                            'admin123456',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _emailController.text = 'admin@empresa.com';
                        _passwordController.text = 'admin123456';
                      });
                    },
                    icon: const Icon(LucideIcons.keyRound, size: 14),
                    label: const Text('Rellenar credenciales por defecto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      side: BorderSide(
                        color: AppColors.primary500.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedSm,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
