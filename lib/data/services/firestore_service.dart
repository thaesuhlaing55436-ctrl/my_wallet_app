import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
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

  CollectionReference<Map<String, dynamic>>
  get _categoriesCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('categories');
  }

  Map<String, dynamic> _toMap(TransactionModel transaction) {
    return {
      'id': transaction.id,
      'title': transaction.title,
      'amount': transaction.amount,
      'category': transaction.category,
      'date': Timestamp.fromDate(transaction.date),
      'note': transaction.note,
    };
  }

  TransactionModel _fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      List<String> incomeCategories,
      ) {
    final data = doc.data();
    final category = data['category'] ?? '';

    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      category: category,
      date: (data['date'] as Timestamp).toDate(),
      type: incomeCategories.contains(category)
          ? TransactionType.income
          : TransactionType.expense,
      note: data['note'],
    );
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

  Stream<List<TransactionModel>> getTransactions() async* {
    await for (final snapshot in _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()) {
      final incomeDoc = await _categoriesCollection
          .doc('income_categories')
          .get();

      final incomeCategories =
      List<String>.from(incomeDoc.data()?['categories'] ?? []);

      yield snapshot.docs
          .map((doc) => _fromDoc(doc, incomeCategories))
          .toList();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsCollection.doc(id).delete();
  }
}