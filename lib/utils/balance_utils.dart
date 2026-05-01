import '../models/money_transaction.dart';

double calculateBalance(List<MoneyTransaction> txns) {
  double balance = 0;
  for (final t in txns) {
    if (t.isPaid) continue;
    final remaining = t.amount - t.settledAmount;
    balance += t.isCredit ? remaining : -remaining;
  }
  return balance;
}
