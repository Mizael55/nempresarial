import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nempresarial/core/storage/local_database_service.dart';
import 'package:nempresarial/features/setup/presentation/controllers/storage_setup_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabaseService db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabaseService();
    await db.ensureInitialized();
  });

  group('LocalDatabaseService Tests', () {
    test('Default users are seeded on initialize', () async {
      final users = await db.query(LocalDatabaseService.tableUsers);
      
      expect(users.isNotEmpty, isTrue);
      final admin = users.firstWhere(
        (u) => u['email'] == 'admin@empresa.com',
        orElse: () => {},
      );
      expect(admin['email'], equals('admin@empresa.com'));
      expect(admin['role'], equals('super_admin'));
    });

    test('CRUD operations work properly in memory', () async {
      // Insert
      final newItem = {
        'id': 'test-prod-1',
        'name': 'Test Item',
        'price': 150.0,
      };
      await db.insert(LocalDatabaseService.tableProducts, newItem);

      // Query
      final retrieved = await db.findById(LocalDatabaseService.tableProducts, 'test-prod-1');
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], equals('Test Item'));
      expect(retrieved['price'], equals(150.0));

      // Update
      await db.update(
        LocalDatabaseService.tableProducts,
        'test-prod-1',
        {'price': 200.0},
      );
      final updated = await db.findById(LocalDatabaseService.tableProducts, 'test-prod-1');
      expect(updated!['price'], equals(200.0));

      // Delete
      await db.delete(LocalDatabaseService.tableProducts, 'test-prod-1');
      final deleted = await db.findById(LocalDatabaseService.tableProducts, 'test-prod-1');
      expect(deleted, isNull);
    });
  });

  group('StorageSetupController Tests', () {
    test('Choose local storage completes setup and records mode', () async {
      final controller = StorageSetupController(db);
      await controller.loadInitialConfig();

      expect(controller.state.storageMode, equals('local'));

      final success = await controller.chooseLocalStorage();
      expect(success, isTrue);

      expect(controller.state.storageMode, equals('local'));
      expect(controller.state.isSetupCompleted, isTrue);
    });

    test('Contains SQL schema ready for Supabase provisioning', () {
      expect(StorageSetupController.supabaseSqlSchema, contains('CREATE TABLE IF NOT EXISTS public.products'));
      expect(StorageSetupController.supabaseSqlSchema, contains('CREATE TABLE IF NOT EXISTS public.sales'));
      expect(StorageSetupController.supabaseSqlSchema, contains('admin@empresa.com'));
    });
  });
}
