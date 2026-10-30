enum TransactionType {
  income,
  expense,
}

class TransactionItem {
  final String name;
  final double amount;
  final String? note;

  const TransactionItem({
    required this.name,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'note': note,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
    );
  }
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final TransactionType type;
  final String? note;
  final List<TransactionItem> items;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.note,
    this.items = const [],
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    TransactionType? type,
    String? note,
    List<TransactionItem>? items,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      items: items ?? this.items,
    );
  }
}