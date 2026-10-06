import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class ProductsRepository {
  Future<List<ProductModel>> getProducts({
    String? searchQuery,
    String? categoryId,
    bool? onlyActive,
  });

  Future<ProductModel> getProductById(String id);

  Future<ProductModel> createProduct(ProductModel product, {double initialStock = 0.0});

  Future<ProductModel> updateProduct(ProductModel product);

  Future<void> deleteProduct(String id);

  Future<List<CategoryModel>> getCategories();

  Future<CategoryModel> createCategory(CategoryModel category);

  Future<CategoryModel> updateCategory(CategoryModel category);

  Future<void> deleteCategory(String id);
}
