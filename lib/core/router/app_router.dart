import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/sales/presentation/screens/sales_screen.dart';
import '../../features/purchases/presentation/screens/purchases_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/setup/presentation/controllers/storage_setup_controller.dart';
import '../../features/setup/presentation/screens/storage_setup_screen.dart';
import '../../shared/components/main_layout_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingState = ref.watch(onboardingControllerProvider);
  final storageSetupState = ref.watch(storageSetupControllerProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isStorageSetup = storageSetupState.isSetupCompleted;
      final isSettingUpStorage = state.matchedLocation == '/setup-storage';

      // 0. First run / storage setup wizard
      if (!isStorageSetup) {
        return isSettingUpStorage ? null : '/setup-storage';
      }

      final isAuth = authState.isAuthenticated;
      final isOnboarding = onboardingState.isCompleted;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboardingScreen = state.matchedLocation == '/onboarding';

      // 1. If not authenticated, redirect to login
      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      // 2. If authenticated but onboarding/business profile not completed, enforce onboarding
      if (!isOnboarding) {
        return isOnboardingScreen ? null : '/onboarding';
      }

      // 3. If authenticated and business profile completed, redirect away from login/onboarding/setup
      if (isLoggingIn || isOnboardingScreen || isSettingUpStorage) {
        return '/dashboard';
      }

      return null;
    },
    errorBuilder: (context, state) => const DashboardScreen(),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(
        path: '/setup-storage',
        builder: (context, state) => const StorageSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayoutScaffold(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const PurchasesScreen(initialTabIndex: 0),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const PurchasesScreen(initialTabIndex: 2),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
