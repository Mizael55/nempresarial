import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(
    num amount, {
    String symbol = 'RD\$',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String number(num value) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(value);
  }

  static String percent(double value) {
    final prefix = value >= 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(1)}%';
  }

  static String dateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  static String timeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}
