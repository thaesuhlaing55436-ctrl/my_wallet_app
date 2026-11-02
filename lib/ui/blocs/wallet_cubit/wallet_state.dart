
import 'package:flutter/foundation.dart';

import '../../../data/models/transaction_model.dart';

enum WalletStatus {
  initial,
  loading,
  success,
  failure,
}

@immutable
class WalletState {
  final WalletStatus status;
  final List<TransactionModel> transactions;
  final String? error;

  const WalletState({
    this.status = WalletStatus.initial,
    this.transactions = const [],
    this.error,
  });

  bool get isLoading => status == WalletStatus.loading;

  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  WalletState copyWith({
    WalletStatus? status,
    List<TransactionModel>? transactions,
    String? error,
    bool clearError = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      error: clearError ? null : error ?? this.error,
    );
  }
}
