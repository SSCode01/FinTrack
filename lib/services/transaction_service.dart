import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/money_transaction.dart';

class TransactionService {
  static final _firestore = FirebaseFirestore.instance;

  // Get current user's transactions collection
  static CollectionReference<Map<String, dynamic>> _txnCollection() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions');
  }

  // STREAM - real time updates
  static Stream<List<MoneyTransaction>> transactionsStream() {
    return _txnCollection()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MoneyTransaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ADD
  static Future<void> addTransaction(MoneyTransaction txn) async {
    await _txnCollection().doc(txn.id).set(txn.toMap());
  }

  // UPDATE
  static Future<void> updateTransaction(MoneyTransaction txn) async {
    await _txnCollection().doc(txn.id).update(txn.toMap());
  }

  // DELETE
  static Future<void> deleteTransaction(String id) async {
    await _txnCollection().doc(id).delete();
  }
}
