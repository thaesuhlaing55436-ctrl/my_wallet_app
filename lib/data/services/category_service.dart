import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please login first.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _categoryDoc(
      TransactionType type,
      ) {
    final docName = type == TransactionType.income
        ? 'income_categories'
        : 'expense_categories';

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('categories')
        .doc(docName);
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
  ];

  Stream<List<String>> getCategories(TransactionType type) {
    return _categoryDoc(type).snapshots().map((snapshot) {
      if (!snapshot.exists) return <String>[];

      final data = snapshot.data();

      return List<String>.from(data?['categories'] ?? []);
    });
  }

  Future<void> initializeCategories() async {
    final batch = _firestore.batch();

    final incomeRef = _categoryDoc(TransactionType.income);
    final expenseRef = _categoryDoc(TransactionType.expense);

    final incomeSnapshot = await incomeRef.get();
    final expenseSnapshot = await expenseRef.get();

    final incomeItems = <String>{
      ...incomeCategories,
      ...List<String>.from(
        incomeSnapshot.data()?['categories'] ?? [],
      ),
    }.toList();

    final expenseItems = <String>{
      ...expenseCategories,
      ...List<String>.from(
        expenseSnapshot.data()?['categories'] ?? [],
      ),
    }.toList();

    batch.set(incomeRef, {
      'categories': incomeItems,
    });

    batch.set(expenseRef, {
      'categories': expenseItems,
    });

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

    final ref = _categoryDoc(type);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      final categories = List<String>.from(
        snapshot.data()?['categories'] ?? [],
      );

      if (categories.any(
            (item) => item.toLowerCase() == categoryName.toLowerCase(),
      )) {
        return;
      }

      categories.add(categoryName);

      transaction.set(ref, {
        'categories': categories,
      }, SetOptions(merge: true));
    });
  }

  Future<void> deleteCategory(String categoryName) async {
    for (final type in [
      TransactionType.income,
      TransactionType.expense,
    ]) {
      final ref = _categoryDoc(type);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) return;

        final categories = List<String>.from(
          snapshot.data()?['categories'] ?? [],
        );

        categories.removeWhere(
              (item) => item == categoryName,
        );

        transaction.update(ref, {
          'categories': categories,
        });
      });
    }
  }
}