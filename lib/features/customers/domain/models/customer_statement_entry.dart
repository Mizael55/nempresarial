class CustomerStatementEntry {
  final DateTime date;
  final String type; // 'sale' or 'payment'
  final String documentNumber;
  final String description;
  final double debit; // Aumenta deuda (Venta)
  final double credit; // Disminuye deuda (Pago)
  final double runningBalance;

  const CustomerStatementEntry({
    required this.date,
    required this.type,
    required this.documentNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });

  bool get isSale => type == 'sale';
  bool get isPayment => type == 'payment';
}
