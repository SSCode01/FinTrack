import 'package:hive/hive.dart';

part 'money_transaction.g.dart';

@HiveType(typeId: 1)
class MoneyTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  bool isCredit; // true = they owe you / you paid

  @HiveField(4)
  String note;

  @HiveField(5)
  DateTime date;

  MoneyTransaction({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isCredit,
    required this.note,
    required this.date,
  });
}
