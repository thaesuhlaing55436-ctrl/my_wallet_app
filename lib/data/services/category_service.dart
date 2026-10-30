import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login first.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>>
  get _categories =>
      _firestore
          .collection('users')
          .doc(_userId)
          .collection('categories');

  String _typeName(TransactionType type) {
    return type == TransactionType.income
        ? 'income'
        : 'expenses';
  }

  CollectionReference<Map<String, dynamic>>
  _itemsCollection(TransactionType type) {
    return _categories
        .doc(_typeName(type))
        .collection('items');
  }

  static const List<String> incomeCategories = [
    'Salary',
    'Business',
    'Gift',
    'Other',
  ];

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Education',
    'Gift',
    'Other',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>>
  getCategories(TransactionType type) {
    return _itemsCollection(type)
        .orderBy('name')
        .snapshots();
  }

  Future<void> initializeCategories() async {
    final batch = _firestore.batch();

    // Create Income and Expenses documents
    batch.set(_categories.doc('income'), {
      'name': 'Income',
      'type': 'income',
    });

    batch.set(_categories.doc('expenses'), {
      'name': 'Expenses',
      'type': 'expenses',
    });

    final incomeRef =
    _itemsCollection(TransactionType.income);

    final expenseRef =
    _itemsCollection(TransactionType.expense);

    final incomeExisting = await incomeRef.get();
    final expenseExisting = await expenseRef.get();

    final existingIncome = incomeExisting.docs
        .map((doc) => doc.data()['name'] as String? ?? '')
        .toSet();

    final existingExpense = expenseExisting.docs
        .map((doc) => doc.data()['name'] as String? ?? '')
        .toSet();

    for (final name in incomeCategories) {
      if (!existingIncome.contains(name)) {
        final doc = incomeRef.doc();

        batch.set(doc, {
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    for (final name in expenseCategories) {
      if (!existingExpense.contains(name)) {
        final doc = expenseRef.doc();

        batch.set(doc, {
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> addCategory(
      String name,
      TransactionType type,
      ) async {
    final categoryName = name.trim();

    if (categoryName.isEmpty) {
      throw Exception('Category name cannot be empty.');
    }

    final collection = _itemsCollection(type);

    final existing = await collection
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    await collection.add({
      'name': categoryName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    final type = await _findCategoryType(categoryId);

    if (type == null) {
      throw Exception('Category not found.');
    }

    await _itemsCollection(type)
        .doc(categoryId)
        .delete();
  }

  Future<TransactionType?> _findCategoryType(
      String categoryId,
      ) async {
    final incomeDoc = await _itemsCollection(
      TransactionType.income,
    ).doc(categoryId).get();

    if (incomeDoc.exists) {
      return TransactionType.income;
    }

    final expenseDoc = await _itemsCollection(
      TransactionType.expense,
    ).doc(categoryId).get();

    if (expenseDoc.exists) {
      return TransactionType.expense;
    }

    return null;
  }
}