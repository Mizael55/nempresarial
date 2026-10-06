import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customers_repository_impl.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/customer_statement_entry.dart';
import '../../domain/models/customer_payment_model.dart';

final customersSearchQueryProvider = StateProvider<String>((ref) => '');
final customersFilterDebtOnlyProvider = StateProvider<bool>((ref) => false);

final customersListProvider = AsyncNotifierProvider<CustomersNotifier, List<CustomerModel>>(() {
  return CustomersNotifier();
});

class CustomersNotifier extends AsyncNotifier<List<CustomerModel>> {
  @override
  Future<List<CustomerModel>> build() async {
    final query = ref.watch(customersSearchQueryProvider);
    final withDebt = ref.watch(customersFilterDebtOnlyProvider);
    final repo = ref.watch(customersRepositoryProvider);
    return repo.getCustomers(query: query, withDebtOnly: withDebt);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final query = ref.read(customersSearchQueryProvider);
      final withDebt = ref.read(customersFilterDebtOnlyProvider);
      return ref.read(customersRepositoryProvider).getCustomers(query: query, withDebtOnly: withDebt);
    });
  }

  Future<CustomerModel> addCustomer(CustomerModel customer) async {
    final created = await ref.read(customersRepositoryProvider).createCustomer(customer);
    await refresh();
    return created;
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final updated = await ref.read(customersRepositoryProvider).updateCustomer(customer);
    await refresh();
    return updated;
  }

  Future<void> deleteCustomer(String id) async {
    await ref.read(customersRepositoryProvider).deleteCustomer(id);
    await refresh();
  }

  Future<Map<String, dynamic>> registerPayment({
    required String customerId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final res = await ref.read(customersRepositoryProvider).registerPayment(
      customerId: customerId,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    await refresh();
    return res;
  }
}

final customerStatementProvider =
    FutureProvider.family<List<CustomerStatementEntry>, String>((ref, customerId) async {
  final repo = ref.watch(customersRepositoryProvider);
  return repo.getCustomerStatement(customerId);
});

final customerPaymentsProvider =
    FutureProvider.family<List<CustomerPaymentModel>, String>((ref, customerId) async {
  final repo = ref.watch(customersRepositoryProvider);
  return repo.getCustomerPayments(customerId);
});
