import 'models/supplier_model.dart';
import 'models/purchase_model.dart';
import 'models/supplier_payment_model.dart';

abstract class PurchasesRepository {
  // Proveedores
  Future<List<SupplierModel>> getSuppliers({String? query, bool? activeOnly});
  Future<SupplierModel> createSupplier(SupplierModel supplier);
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String id);

  // Compras
  Future<List<PurchaseModel>> getPurchases({String? query, String? status});
  Future<PurchaseModel> getPurchaseById(String id);
  Future<Map<String, dynamic>> createPurchase({
    required String? supplierId,
    required String? branchId,
    required String paymentMethod,
    required String paymentStatus,
    required String? notes,
    required String? customInvoiceNumber,
    required double taxAmount,
    required List<Map<String, dynamic>> items,
  });
  Future<void> voidPurchase(String purchaseId, String reason);

  // Pagos a Proveedores
  Future<List<SupplierPaymentModel>> getSupplierPayments(String supplierId);
  Future<void> recordSupplierPayment({
    required String supplierId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  });
}
