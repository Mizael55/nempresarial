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
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signUp(
          _emailController.text,
          _passwordController.text,
          _fullNameController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada con éxito! Configura tu negocio ahora.'),
          backgroundColor: AppColors.emerald600,
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: NubikoResponsiveLayout(
        mobile: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _buildRegisterForm(context, isDark, authState),
              ),
            ),
          ),
        ),
        desktop: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _buildRegisterForm(context, isDark, authState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, bool isDark, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Crear cuenta administrativa',
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configura el usuario principal para administrar la instancia de tu empresa.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: 24),

          if (authState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.rose500.withOpacity(0.15) : AppColors.rose50,
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

          NubikoTextField(
            label: 'Nombre Completo',
            hint: 'Ej. Juan Pérez',
            controller: _fullNameController,
            prefixIcon: const Icon(LucideIcons.user, size: 18),
            validator: (v) => Validators.required(v, 'Ingresa tu nombre'),
          ),
          const SizedBox(height: 16),

          NubikoTextField(
            label: 'Correo Electrónico de Trabajo',
            hint: 'administrador@miempresa.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(LucideIcons.mail, size: 18),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),

          NubikoTextField(
            label: 'Contraseña',
            hint: 'Mínimo 6 caracteres',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            validator: Validators.password,
          ),
          const SizedBox(height: 16),

          NubikoTextField(
            label: 'Confirmar Contraseña',
            hint: 'Repite la contraseña',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
            validator: (v) => Validators.confirmPassword(v, _passwordController.text),
          ),
          const SizedBox(height: 26),

          NubikoButton(
            text: 'Crear Cuenta y Continuar',
            isFullWidth: true,
            icon: LucideIcons.userPlus,
            isLoading: authState.isLoading,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 20),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Ya tienes cuenta activa?',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Iniciar Sesión',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.w700,
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
