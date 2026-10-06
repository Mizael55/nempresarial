import 'models/customer_model.dart';
import 'models/customer_payment_model.dart';
import 'models/customer_statement_entry.dart';

abstract class CustomersRepository {
  Future<List<CustomerModel>> getCustomers({String? query, bool? withDebtOnly});
  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);

  // Pagos y Abonos (CXC)
  Future<Map<String, dynamic>> registerPayment({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  });

  Future<List<CustomerPaymentModel>> getCustomerPayments(String customerId);

  // Estado de Cuenta
  Future<List<CustomerStatementEntry>> getCustomerStatement(String customerId);
}
