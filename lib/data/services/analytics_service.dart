import '../models/transaction_model.dart';

class AnalyticsService {
  const AnalyticsService();

  // Calculate total income.
  double calculateIncome(List<TransactionModel> transactions) {
    return transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // Calculate total expenses.
  double calculateExpense(List<TransactionModel> transactions) {
    return transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  // Calculate balance.
  double calculateBalance(List<TransactionModel> transactions) {
    return calculateIncome(transactions) -
        calculateExpense(transactions);
  }

  // Filter transactions by week, month, or year.
  List<TransactionModel> filterByPeriod(
      List<TransactionModel> transactions, {
        required String period,
        DateTime? now,
      }) {
    final currentDate = now ?? DateTime.now();

    return transactions.where((transaction) {
      final date = transaction.date;

      switch (period) {
        case 'week':
          final startOfWeek = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          ).subtract(Duration(days: currentDate.weekday - 1));

          final endOfWeek = startOfWeek.add(const Duration(days: 7));

          return !date.isBefore(startOfWeek) &&
              date.isBefore(endOfWeek);

        case 'month':
          return date.year == currentDate.year &&
              date.month == currentDate.month;

        case 'year':
          return date.year == currentDate.year;

        default:
          return true;
      }
    }).toList();
  }
}