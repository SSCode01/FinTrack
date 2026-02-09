import '../models/money_transaction.dart';

double calculateBalance(List<MoneyTransaction> txns) {
  double balance = 0;
  for (final t in txns) {
    balance += t.isCredit ? t.amount : -t.amount;
  }
  return balance;
}
