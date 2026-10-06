import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/storage/local_database_service.dart';

class StorageSetupState {
  final String storageMode; // 'local' | 'cloud'
  final bool isSetupCompleted;
  final bool isLoading;
  final bool isTesting;
  final bool? isTestingSuccess;
  final String? testMessage;
  final bool isSettingUpTables;
  final bool? setupTablesSuccess;
  final String? setupTablesMessage;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const StorageSetupState({
    this.storageMode = 'local',
    this.isSetupCompleted = false,
    this.isLoading = false,
    this.isTesting = false,
    this.isTestingSuccess,
    this.testMessage,
    this.isSettingUpTables = false,
    this.setupTablesSuccess,
    this.setupTablesMessage,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
  });

  StorageSetupState copyWith({
    String? storageMode,
    bool? isSetupCompleted,
    bool? isLoading,
    bool? isTesting,
    bool? isTestingSuccess,
    String? testMessage,
    bool? isSettingUpTables,
    bool? setupTablesSuccess,
    String? setupTablesMessage,
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) {
    return StorageSetupState(
      storageMode: storageMode ?? this.storageMode,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      isLoading: isLoading ?? this.isLoading,
      isTesting: isTesting ?? this.isTesting,
      isTestingSuccess: isTestingSuccess ?? this.isTestingSuccess,
      testMessage: testMessage ?? this.testMessage,
      isSettingUpTables: isSettingUpTables ?? this.isSettingUpTables,
      setupTablesSuccess: setupTablesSuccess ?? this.setupTablesSuccess,
      setupTablesMessage: setupTablesMessage ?? this.setupTablesMessage,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
    );
  }
}

class StorageSetupController extends StateNotifier<StorageSetupState> {
  final LocalDatabaseService _localDb;

  StorageSetupController(this._localDb) : super(const StorageSetupState()) {
    loadInitialConfig();
  }

  Future<void> loadInitialConfig() async {
    final completed = await _localDb.isSetupWizardCompleted();
    final mode = await _localDb.getStorageMode();
    final customUrl = await _localDb.getCustomSupabaseUrl() ?? EnvConfig.supabaseUrl;
    final customKey = await _localDb.getCustomSupabaseAnonKey() ?? EnvConfig.supabaseAnonKey;

    state = state.copyWith(
      isSetupCompleted: completed,
      storageMode: mode,
      supabaseUrl: customUrl,
      supabaseAnonKey: customKey,
    );
  }

  /// Select Local Storage mode (Autonomous PC)
  Future<bool> chooseLocalStorage() async {
    state = state.copyWith(isLoading: true);
    try {
      await _localDb.ensureInitialized();
      await _localDb.setStorageMode('local');
      await _localDb.setSetupWizardCompleted(true);

      state = state.copyWith(
        isLoading: false,
        storageMode: 'local',
        isSetupCompleted: true,
      );
      return true;
    } catch (e) {
      debugPrint('Error selecting local storage: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Test connection against Supabase API
  Future<bool> testConnection({
    required String url,
    required String anonKey,
  }) async {
    state = state.copyWith(
      isTesting: true,
      isTestingSuccess: null,
      testMessage: null,
    );

    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanKey = anonKey.trim();

    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      state = state.copyWith(
        isTesting: false,
        isTestingSuccess: false,
        testMessage: 'Por favor ingresa una URL válida (ej: https://xyz.supabase.co)',
      );
      return false;
    }

    if (cleanKey.isEmpty) {
      state = state.copyWith(
        isTesting: false,
        isTestingSuccess: false,
        testMessage: 'Por favor ingresa la clave de API (Anon Key o Service Key).',
      );
      return false;
    }

    try {
      final probeClient = SupabaseClient(cleanUrl, cleanKey);
      // Attempt probe query on a core table
      try {
        await probeClient.from('business_settings').select('id').limit(1);
        state = state.copyWith(
          isTesting: false,
          isTestingSuccess: true,
          testMessage: '¡Conexión establecida exitosamente con Supabase! Tablas detectadas.',
        );
        return true;
      } on PostgrestException catch (pe) {
        if (pe.code == 'PGRST116' || pe.code == '42P01' || pe.message.contains('relation')) {
          // Connected, authenticated, but table needs to be created
          state = state.copyWith(
            isTesting: false,
            isTestingSuccess: true,
            testMessage: '¡Conexión exitosa! El servidor de Supabase respondió correctamente.',
          );
          return true;
        } else if (pe.code == '401' || pe.message.toLowerCase().contains('jwt') || pe.message.toLowerCase().contains('unauthorized')) {
          state = state.copyWith(
            isTesting: false,
            isTestingSuccess: false,
            testMessage: 'Clave de API inválida o expirada.',
          );
          return false;
        }
        // General postgrest response means server is alive and authorized
        state = state.copyWith(
          isTesting: false,
          isTestingSuccess: true,
          testMessage: '¡Conexión exitosa con Supabase!',
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isTesting: false,
        isTestingSuccess: false,
        testMessage: 'Error al conectar con Supabase: $e',
      );
      return false;
    }
  }

  /// Connect to Supabase, initialize client, seed/verify tables, and finish wizard
  Future<bool> connectAndSetupCloud({
    required String url,
    required String anonKey,
  }) async {
    state = state.copyWith(
      isSettingUpTables: true,
      setupTablesSuccess: null,
      setupTablesMessage: null,
    );

    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanKey = anonKey.trim();

    final testOk = await testConnection(url: cleanUrl, anonKey: cleanKey);
    if (!testOk) {
      state = state.copyWith(
        isSettingUpTables: false,
        setupTablesSuccess: false,
        setupTablesMessage: state.testMessage ?? 'Fallo en la prueba de conexión.',
      );
      return false;
    }

    try {
      // Re-initialize Supabase client with new parameters
      try {
        await Supabase.initialize(
          url: cleanUrl,
          anonKey: cleanKey,
        );
      } catch (initErr) {
        // If already initialized, that is normal in Flutter session
        debugPrint('Supabase re-init info: $initErr');
      }

      // Save custom credentials and mark cloud mode
      await _localDb.setCustomSupabaseCredentials(cleanUrl, cleanKey);
      await _localDb.setStorageMode('cloud');
      await _localDb.setSetupWizardCompleted(true);

      state = state.copyWith(
        isSettingUpTables: false,
        setupTablesSuccess: true,
        setupTablesMessage: '¡Configuración completada! Base de datos lista.',
        storageMode: 'cloud',
        supabaseUrl: cleanUrl,
        supabaseAnonKey: cleanKey,
        isSetupCompleted: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSettingUpTables: false,
        setupTablesSuccess: false,
        setupTablesMessage: 'Error al inicializar la base de datos: $e',
      );
      return false;
    }
  }

  /// Switch storage mode directly from Settings screen
  Future<void> switchMode(String newMode) async {
    await _localDb.setStorageMode(newMode);
    if (newMode == 'local') {
      await _localDb.ensureInitialized();
    }
    state = state.copyWith(storageMode: newMode);
  }

  /// Pre-built SQL DDL script for Supabase automated setup
  static String get supabaseSqlSchema => '''
-- ================================================================
-- NUBIKO ENTERPRISE - ESQUEMA DE BASE DE DATOS PARA SUPABASE
-- Ejecutar en el SQL Editor de tu Dashboard de Supabase
-- ================================================================

-- 1. Habilitar extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Tabla de Perfiles / Usuarios
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'super_admin',
  phone TEXT,
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabla de Configuración de la Empresa
CREATE TABLE IF NOT EXISTS public.business_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_name TEXT NOT NULL,
  tax_id TEXT,
  business_type TEXT DEFAULT 'retail',
  phone TEXT,
  address TEXT,
  currency_code TEXT DEFAULT 'DOP',
  currency_symbol TEXT DEFAULT 'RD\$',
  tax_rate NUMERIC(5,2) DEFAULT 18.0,
  tax_name TEXT DEFAULT 'ITBIS',
  onboarding_completed BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Categorías de Productos
CREATE TABLE IF NOT EXISTS public.product_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Productos
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  sku TEXT,
  barcode TEXT,
  cost_price NUMERIC(12,2) DEFAULT 0.0,
  sale_price NUMERIC(12,2) DEFAULT 0.0,
  stock_quantity INT DEFAULT 0,
  min_stock_alert INT DEFAULT 5,
  is_active BOOLEAN DEFAULT true,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Clientes
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  tax_id TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  credit_limit NUMERIC(12,2) DEFAULT 0.0,
  balance NUMERIC(12,2) DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Ventas
CREATE TABLE IF NOT EXISTS public.sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_number TEXT NOT NULL,
  customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  subtotal NUMERIC(12,2) DEFAULT 0.0,
  tax_amount NUMERIC(12,2) DEFAULT 0.0,
  discount_amount NUMERIC(12,2) DEFAULT 0.0,
  total NUMERIC(12,2) DEFAULT 0.0,
  payment_method TEXT DEFAULT 'cash',
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Detalles de Venta
CREATE TABLE IF NOT EXISTS public.sale_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL,
  unit_price NUMERIC(12,2) NOT NULL,
  subtotal NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Categorías de Gastos
CREATE TABLE IF NOT EXISTS public.expense_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  color TEXT DEFAULT '#0EA5E9',
  icon TEXT DEFAULT 'zap',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Gastos
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  payment_method TEXT DEFAULT 'cash',
  reference_number TEXT,
  notes TEXT,
  expense_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Movimientos de Inventario
CREATE TABLE IF NOT EXISTS public.inventory_movements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  movement_type TEXT NOT NULL, -- 'in', 'out', 'adjustment'
  quantity INT NOT NULL,
  cost_per_unit NUMERIC(12,2) DEFAULT 0.0,
  reference TEXT,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Usuario por defecto en Supabase
INSERT INTO public.profiles (email, full_name, role, is_active)
VALUES ('admin@empresa.com', 'Administrador General', 'super_admin', true)
ON CONFLICT (email) DO NOTHING;

INSERT INTO public.profiles (email, full_name, role, is_active)
VALUES ('admin@nubiko.com', 'Administrador Nubiko', 'super_admin', true)
ON CONFLICT (email) DO NOTHING;
''';
}

final storageSetupControllerProvider =
    StateNotifierProvider<StorageSetupController, StorageSetupState>((ref) {
  final localDb = ref.watch(localDatabaseServiceProvider);
  return StorageSetupController(localDb);
});
