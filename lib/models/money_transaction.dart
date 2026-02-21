import 'package:cloud_firestore/cloud_firestore.dart';

class MoneyTransaction {
  final String id;
  String personName;
  double amount;
  bool isCredit;
  String note;
  DateTime date;
  bool isPaid;
  String category;

  MoneyTransaction({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isCredit,
    required this.note,
    required this.date,
    this.isPaid = false,
    this.category = 'Other',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'isCredit': isCredit,
      'note': note,
      'date': Timestamp.fromDate(date),
      'isPaid': isPaid,
      'category': category,
    };
  }

  factory MoneyTransaction.fromMap(String id, Map<String, dynamic> map) {
    return MoneyTransaction(
      id: id,
      personName: map['personName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      isCredit: map['isCredit'] ?? true,
      note: map['note'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      isPaid: map['isPaid'] ?? false,
      category: map['category'] ?? 'Other',
    );
  }
}
