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
  double settledAmount;

  MoneyTransaction({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isCredit,
    required this.note,
    required this.date,
    this.isPaid = false,
    this.category = 'Other',
    this.settledAmount = 0.0,
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
      'settledAmount': settledAmount,
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
      settledAmount: (map['settledAmount'] ?? 0).toDouble(),
    );
  }
}
