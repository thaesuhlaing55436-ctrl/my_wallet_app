import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please log in first.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>>
  get _transactionsCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');
  }

  Map<String, dynamic> _toMap(
      TransactionModel transaction,
      ) {
    return {
      'id': transaction.id,
      'title': transaction.title,
      'amount': transaction.amount,
      'category': transaction.category,
      'date': Timestamp.fromDate(transaction.date),
      'type': transaction.type.name,
      'note': transaction.note,
    };
  }

  Future<void> addTransaction(
      TransactionModel transaction,
      ) async {
    await _transactionsCollection
        .doc(transaction.id)
        .set({
      ..._toMap(transaction),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTransaction(
      TransactionModel transaction,
      ) async {
    await _transactionsCollection
        .doc(transaction.id)
        .update(_toMap(transaction));
  }

  Stream<List<TransactionModel>> getTransactions() {
    return _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return TransactionModel(
          id: doc.id,
          title: data['title'] as String? ?? '',
          amount:
          (data['amount'] as num?)?.toDouble() ?? 0.0,
          category: data['category'] as String? ?? '',
          date: (data['date'] as Timestamp?)?.toDate()
              ?? DateTime.now(),
          type: data['type'] == 'income'
              ? TransactionType.income
              : TransactionType.expense,
          note: data['note'] as String?,
        );
      }).toList();
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsCollection.doc(id).delete();
  }
}