 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../models/transaction_model.dart';

class CategoryService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

String get _userId {
final user = _auth.currentUser;
if (user == null) {
throw Exception('Please login first.');
}
  debugPrint('CURRENT USER ID: ${user.uid}');
return user.uid;
}

CollectionReference<Map<String, dynamic>> get _categoriesCollection {
return _firestore
    .collection('users')
    .doc(_userId)
    .collection('categories');
}

DocumentReference<Map<String, dynamic>> _categoryDoc(
TransactionType type,
) {
final docName = type == TransactionType.income
? 'income_categories'
    : 'expense_categories';

return _categoriesCollection.doc(docName);
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

return List<String>.from(
snapshot.data()?['categories'] ?? [],
);
});
}

// Migrate old category documents into two documents.
Future<void> initializeCategories() async {
final snapshot = await _categoriesCollection.get();

final incomeItems = <String>{
...incomeCategories,
};

final expenseItems = <String>{
...expenseCategories,
};

for (final doc in snapshot.docs) {
final data = doc.data();

// Keep existing category arrays.
if (doc.id == 'income_categories') {
incomeItems.addAll(
List<String>.from(data['categories'] ?? []),
);
} else if (doc.id == 'expense_categories') {
expenseItems.addAll(
List<String>.from(data['categories'] ?? []),
);
}

// Move old individual category documents.
final name = data['name'];

if (name is String && name.trim().isNotEmpty) {
final type = data['type']?.toString().toLowerCase();

if (type == 'income') {
incomeItems.add(name.trim());
} else if (type == 'expense') {
expenseItems.add(name.trim());
}
}

// Migrate old income/expense array documents if present.
final oldCategories = data['categories'];

if (oldCategories is List) {
final values = List<String>.from(oldCategories);

if (doc.id == 'income') {
incomeItems.addAll(values);
} else if (doc.id == 'expenses' || doc.id == 'expense') {
expenseItems.addAll(values);
}
}
}

final batch = _firestore.batch();

batch.set(_categoryDoc(TransactionType.income), {
'categories': incomeItems.toList(),
});

batch.set(_categoryDoc(TransactionType.expense), {
'categories': expenseItems.toList(),
});

// Delete old documents, keeping only the two required documents.
for (final doc in snapshot.docs) {
if (doc.id != 'income_categories' &&
doc.id != 'expense_categories') {
batch.delete(doc.reference);
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
});
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

categories.removeWhere((item) => item == categoryName);

transaction.set(ref, {
'categories': categories,
});
});
}
}
}