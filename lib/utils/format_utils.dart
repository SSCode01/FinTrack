import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatAmount(double amount) {
  return _currencyFormatter.format(amount);
}
