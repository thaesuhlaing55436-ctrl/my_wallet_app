import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/transaction_model.dart';

class WalletService extends ChangeNotifier {
final List<TransactionModel> _transactions = [];

bool _isLoading = true;
String? _userId;

List<TransactionModel> get transactions =>
List.unmodifiable(_transactions);

bool get isLoading => _isLoading;

WalletService() {
_userId = FirebaseAuth.instance.currentUser?.uid;
loadTransactions();
}

double get totalIncome => _transactions
    .where((t) => t.type == TransactionType.income)
    .fold(0.0, (sum, t) => sum + t.amount);

double get totalExpense => _transactions
    .where((t) => t.type == TransactionType.expense)
    .fold(0.0, (sum, t) => sum + t.amount);

double get balance => totalIncome - totalExpense;

Future<void> loadTransactions() async {
_isLoading = true;
notifyListeners();

try {
final userId = FirebaseAuth.instance.currentUser?.uid;

_transactions.clear();
_userId = userId;

if (userId == null) return;

final Database db = await AppDatabase.instance.database;

final rows = await db.query(
'transactions',
where: 'userId = ?',
whereArgs: [userId],
orderBy: 'date DESC',
);

_transactions.addAll(
rows.map((row) {
return TransactionModel(
id: row['id'] as String,
title: row['title'] as String,
amount: (row['amount'] as num).toDouble(),
category: row['category'] as String,
date: DateTime.parse(row['date'] as String),
type: row['type'] == 'income'
? TransactionType.income
    : TransactionType.expense,
note: row['note'] as String?,
);
}),
);
} catch (error, stackTrace) {
debugPrint('Load transactions failed: $error');
debugPrintStack(stackTrace: stackTrace);
} finally {
_isLoading = false;
notifyListeners();
}
}

String _requireUserId() {
final userId = FirebaseAuth.instance.currentUser?.uid;

if (userId == null) {
throw StateError('Please login before managing transactions.');
}

if (_userId != userId) {
throw StateError(
'The logged-in account changed. Reload transactions first.',
);
}

return userId;
}

Map<String, Object?> _toMap(
TransactionModel transaction,
String userId,
) {
return {
'id': transaction.id,
'userId': userId,
'title': transaction.title,
'amount': transaction.amount,
'category': transaction.category,
'date': transaction.date.toIso8601String(),
'type': transaction.type.name,
'note': transaction.note,
};
}

Future<void> addTransaction(TransactionModel transaction) async {
final userId = _requireUserId();
final Database db = await AppDatabase.instance.database;

await db.insert(
'transactions',
_toMap(transaction, userId),
conflictAlgorithm: ConflictAlgorithm.replace,
);

_transactions.insert(0, transaction);
notifyListeners();
}

Future<void> updateTransaction(TransactionModel updated) async {
final userId = _requireUserId();
final Database db = await AppDatabase.instance.database;

final count = await db.update(
'transactions',
_toMap(updated, userId),
where: 'id = ? AND userId = ?',
whereArgs: [updated.id, userId],
);

if (count == 0) return;

final index = _transactions.indexWhere((t) => t.id == updated.id);

if (index == -1) {
await loadTransactions();
return;
}

_transactions[index] = updated;
notifyListeners();
}

Future<void> deleteTransaction(String id) async {
final userId = _requireUserId();
final Database db = await AppDatabase.instance.database;
 await db.delete(
'transactions',
where: 'id = ? AND userId = ?',
whereArgs: [id, userId],
);

_transactions.removeWhere((t) => t.id == id);
notifyListeners();
}
}