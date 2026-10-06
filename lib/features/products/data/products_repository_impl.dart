import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/storage/local_database_service.dart';
import '../domain/models/category_model.dart';
import '../domain/models/product_model.dart';
import '../domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final LocalDatabaseService _localDb;
  final _uuid = const Uuid();

  ProductsRepositoryImpl(this._localDb);

  @override
  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    String? categoryId,
    bool? onlyActive,
  }) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          var query = Supabase.instance.client
              .from('products')
              .select('*, category:product_categories(name)');

          if (onlyActive == true) {
            query = query.eq('is_active', true);
          }
          if (categoryId != null && categoryId.isNotEmpty) {
            query = query.eq('category_id', categoryId);
          }
          if (searchQuery != null && searchQuery.isNotEmpty) {
            query = query.or('name.ilike.%$searchQuery%,sku.ilike.%$searchQuery%,barcode.ilike.%$searchQuery%');
          }

          final data = await query.order('created_at', ascending: false);
          return (data as List).map((p) => ProductModel.fromJson(p)).toList();
        } catch (_) {}
      }

      // Local Database (Persistent SQLite/JSON tables on PC)
      await _localDb.ensureInitialized();
      final rows = await _localDb.query(LocalDatabaseService.tableProducts, orderBy: 'created_at', ascending: false);
      var products = rows.map((r) => ProductModel.fromJson(r)).toList();

      if (onlyActive == true) {
        products = products.where((p) => p.isActive).toList();
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        products = products.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.sku.toLowerCase().contains(query) ||
              (p.barcode != null && p.barcode!.toLowerCase().contains(query));
        }).toList();
      }

      return products;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final mode = await _localDb.getStorageMode();

      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final data = await Supabase.instance.client
              .from('products')
              .select('*, category:product_categories(name)')
              .eq('id', id)
              .single();
          return ProductModel.fromJson(data);
        } catch (_) {}
      }

      final row = await _localDb.findById(LocalDatabaseService.tableProducts, id);
      if (row != null) {
        return ProductModel.fromJson(row);
      }
      throw const NotFoundFailure('Producto no encontrado');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product, {double initialStock = 0.0}) async {
    try {
      final generatedId = product.id.isNotEmpty ? product.id : _uuid.v4();
      final newProduct = product.copyWith(
        id: generatedId,
        currentStock: initialStock,
        createdAt: DateTime.now(),
      );

      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final payload = newProduct.toJson();
          await Supabase.instance.client.from('products').insert(payload);

          final branchRes = await Supabase.instance.client
              .from('branches')
              .select('id')
              .limit(1)
              .maybeSingle();

          if (branchRes != null) {
            final branchId = branchRes['id'] as String;
            await Supabase.instance.client.from('inventory').insert({
              'product_id': generatedId,
              'branch_id': branchId,
              'current_stock': initialStock,
              'reserved_stock': 0,
            });

            if (initialStock > 0) {
              await Supabase.instance.client.from('inventory_movements').insert({
                'product_id': generatedId,
                'branch_id': branchId,
                'movement_type': 'initial',
                'quantity': initialStock,
                'previous_stock': 0,
                'new_stock': initialStock,
                'unit_cost': product.costPrice,
                'notes': 'Inventario inicial de apertura de producto',
              });
            }
          }
          return newProduct;
        } catch (_) {}
      }

      // Persist locally
      final payload = newProduct.toJson();
      await _localDb.insert(LocalDatabaseService.tableProducts, payload);

      if (initialStock > 0) {
        await _localDb.insert(LocalDatabaseService.tableMovements, {
          'product_id': generatedId,
          'movement_type': 'initial',
          'quantity': initialStock,
          'previous_stock': 0,
          'new_stock': initialStock,
          'unit_cost': product.costPrice,
          'notes': 'Inventario inicial de apertura de producto',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return newProduct;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final payload = product.toJson();
          await Supabase.instance.client
              .from('products')
              .update(payload)
              .eq('id', product.id);
          return product;
        } catch (_) {}
      }

      await _localDb.update(
        LocalDatabaseService.tableProducts,
        product.id,
        product.toJson(),
      );
      return product;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          await Supabase.instance.client.from('products').delete().eq('id', id);
          return;
        } catch (_) {}
      }

      await _localDb.delete(LocalDatabaseService.tableProducts, id);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          final data = await Supabase.instance.client
              .from('product_categories')
              .select()
              .order('name');
          return (data as List).map((c) => CategoryModel.fromJson(c)).toList();
        } catch (_) {}
      }

      await _localDb.ensureInitialized();
      final rows = await _localDb.query(LocalDatabaseService.tableCategories, orderBy: 'name', ascending: true);
      return rows.map((c) => CategoryModel.fromJson(c)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final newCat = category.copyWith(
        id: category.id.isNotEmpty ? category.id : _uuid.v4(),
      );

      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          await Supabase.instance.client.from('product_categories').insert(newCat.toJson());
          return newCat;
        } catch (_) {}
      }

      await _localDb.insert(LocalDatabaseService.tableCategories, newCat.toJson());
      return newCat;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          await Supabase.instance.client
              .from('product_categories')
              .update(category.toJson())
              .eq('id', category.id);
          return category;
        } catch (_) {}
      }

      await _localDb.update(LocalDatabaseService.tableCategories, category.id, category.toJson());
      return category;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final mode = await _localDb.getStorageMode();
      if (mode == 'cloud' && EnvConfig.isSupabaseConfigured) {
        try {
          await Supabase.instance.client.from('product_categories').delete().eq('id', id);
          return;
        } catch (_) {}
      }

      await _localDb.delete(LocalDatabaseService.tableCategories, id);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final localDb = ref.watch(localDatabaseServiceProvider);
  return ProductsRepositoryImpl(localDb);
});
