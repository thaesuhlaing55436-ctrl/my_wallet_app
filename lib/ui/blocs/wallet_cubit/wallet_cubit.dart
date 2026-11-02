
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/services/firestore_service.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<TransactionModel>>?
  _transactionsSubscription;

  WalletCubit() : super(const WalletState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    await _transactionsSubscription?.cancel();

    emit(state.copyWith(
      status: WalletStatus.loading,
      clearError: true,
    ));

    try {
      _transactionsSubscription =
          _firestoreService.getTransactions().listen(
                (loaded) {
              emit(state.copyWith(
                status: WalletStatus.success,
                transactions: loaded,
                clearError: true,
              ));
            },
            onError: (error) {
              emit(state.copyWith(
                status: WalletStatus.failure,
                error: error.toString(),
              ));
            },
          );
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.failure,
        error: e.toString(),
      ));
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
  Future<void> close() async {
    await _transactionsSubscription?.cancel();
    return super.close();
  }
}
