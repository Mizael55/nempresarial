import 'models/sale_model.dart';
import 'models/sale_item_model.dart';
import 'models/customer_model.dart';
import 'models/cart_item_model.dart';

abstract class SalesRepository {
  Future<List<SaleModel>> getSales({String? status, String? searchQuery, int limit = 50});
  Future<SaleModel?> getSaleById(String saleId);
  Future<List<SaleItemModel>> getSaleItems(String saleId);
  Future<List<CustomerModel>> getCustomers({String? query});
  Future<CustomerModel> createCustomer({
    required String name,
    String? taxId,
    String? phone,
    String? email,
    String? address,
  });
  Future<Map<String, dynamic>> completeSale({
    String? branchId,
    String? customerId,
    required List<CartItemModel> items,
    required String paymentMethod,
    String paymentStatus = 'paid',
    double globalDiscount = 0.0,
    String? notes,
    String? createdBy,
    List<Map<String, dynamic>> payments = const [],
  });
  Future<Map<String, dynamic>> voidSale({
    required String saleId,
    required String reason,
    String? userId,
  });
}
