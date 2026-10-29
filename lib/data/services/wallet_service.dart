import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import 'firestore_service.dart';

class WalletService extends ChangeNotifier {
 final FirestoreService _firestoreService = FirestoreService();

 final List<TransactionModel> _transactions = [];

 StreamSubscription<List<TransactionModel>>?
 _transactionsSubscription;

 bool _isLoading = true;
 String? _error;
 bool _disposed = false;

 bool get isLoading => _isLoading;
 String? get error => _error;

 List<TransactionModel> get transactions =>
     List.unmodifiable(_transactions);

 double get totalIncome => _transactions
     .where((t) => t.type == TransactionType.income)
     .fold(0.0, (sum, t) => sum + t.amount);

 double get totalExpense => _transactions
     .where((t) => t.type == TransactionType.expense)
     .fold(0.0, (sum, t) => sum + t.amount);

 double get balance => totalIncome - totalExpense;

 WalletService() {
  loadTransactions();
 }

 void _notify() {
  if (!_disposed) {
   notifyListeners();
  }
 }

 Future<void> loadTransactions() async {
  await _transactionsSubscription?.cancel();

  _isLoading = true;
  _error = null;
  _notify();

  try {
   _transactionsSubscription =
       _firestoreService.getTransactions().listen(
            (loaded) {
         _transactions
          ..clear()
          ..addAll(loaded);

         _isLoading = false;
         _error = null;
         _notify();
        },
        onError: (Object error) {
         _isLoading = false;
         _error = error.toString();
         debugPrint('Load transactions failed: $error');
         _notify();
        },
       );
  } catch (e) {
   _isLoading = false;
   _error = e.toString();
   debugPrint('Load transactions failed: $e');
   _notify();
  }
 }

 Future<void> addTransaction(
     TransactionModel transaction,
     ) async {
  await _firestoreService.addTransaction(transaction);
 }

 Future<void> updateTransaction(
     TransactionModel transaction,
     ) async {
  await _firestoreService.updateTransaction(transaction);
 }

 Future<void> deleteTransaction(String id) async {
  await _firestoreService.deleteTransaction(id);
 }

 @override
 void dispose() {
  _disposed = true;
  _transactionsSubscription?.cancel();
  super.dispose();
 }
}