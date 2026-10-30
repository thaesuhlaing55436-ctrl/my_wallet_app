 import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class FirestoreService {
final FirebaseFirestore _firestore =
FirebaseFirestore.instance;

final FirebaseAuth _auth = FirebaseAuth.instance;

String get _userId {
final user = _auth.currentUser;

if (user == null) {
throw Exception('Please log in first.');
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
_typeCollection(TransactionType type) {
final typeName = type == TransactionType.income
? 'income'
    : 'expenses';

return _transactionsCollection
    .doc(typeName)
    .collection('items');
}

Map<String, dynamic> _toMap(
TransactionModel transaction,
) {
return {
'id': transaction.id,
'title': transaction.title,
'amount': transaction.amount,
'category': transaction.category,
'date': Timestamp.fromDate(transaction.date),
'type': transaction.type.name,
'note': transaction.note,
'items': transaction.items
    .map((item) => item.toMap())
    .toList(),
};
}

TransactionModel _fromDoc(
QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
final data = doc.data();

final rawItems =
data['items'] as List<dynamic>? ?? [];

return TransactionModel(
id: doc.id,
title: data['title'] as String? ?? '',
amount:
(data['amount'] as num?)?.toDouble() ?? 0.0,
category: data['category'] as String? ?? '',
date: (data['date'] as Timestamp?)?.toDate() ??
DateTime.now(),
type: data['type'] == 'income'
? TransactionType.income
    : TransactionType.expense,
note: data['note'] as String?,
items: rawItems
    .whereType<Map<String, dynamic>>()
    .map((item) => TransactionItem.fromMap(item))
    .toList(),
);
}

Future<void> addTransaction(
TransactionModel transaction,
) async {
await _typeCollection(transaction.type)
    .doc(transaction.id)
    .set({
..._toMap(transaction),
'createdAt': FieldValue.serverTimestamp(),
});
}

Future<void> updateTransaction(
TransactionModel transaction,
) async {
final batch = _firestore.batch();

final newRef = _typeCollection(transaction.type)
    .doc(transaction.id);

final oldType =
transaction.type == TransactionType.income
? TransactionType.expense
    : TransactionType.income;

final oldRef = _typeCollection(oldType)
    .doc(transaction.id);

final oldDoc = await oldRef.get();

if (oldDoc.exists) {
batch.delete(oldRef);
}

batch.set(newRef, _toMap(transaction));

await batch.commit();
}

Stream<List<TransactionModel>> getTransactions() {
late final StreamController<List<TransactionModel>>
controller;

StreamSubscription? incomeSubscription;
StreamSubscription? expenseSubscription;

List<TransactionModel> incomeTransactions = [];
List<TransactionModel> expenseTransactions = [];

void emitTransactions() {
final allTransactions = [
...incomeTransactions,
...expenseTransactions,
];

allTransactions.sort(
(a, b) => b.date.compareTo(a.date),
);

if (!controller.isClosed) {
controller.add(allTransactions);
}
}

controller = StreamController<List<TransactionModel>>(
onListen: () {
incomeSubscription = _typeCollection(
TransactionType.income,
).orderBy('date', descending: true).snapshots().listen(
(snapshot) {
incomeTransactions =
snapshot.docs.map(_fromDoc).toList();
 emitTransactions();
},
onError: (Object error, StackTrace stackTrace) {
if (!controller.isClosed) {
controller.addError(error, stackTrace);
}
},
);

expenseSubscription = _typeCollection(
TransactionType.expense,
).orderBy('date', descending: true).snapshots().listen(
(snapshot) {
expenseTransactions =
snapshot.docs.map(_fromDoc).toList();

emitTransactions();
},
onError: (Object error, StackTrace stackTrace) {
if (!controller.isClosed) {
controller.addError(error, stackTrace);
}
},
);
},
onCancel: () async {
await incomeSubscription?.cancel();
await expenseSubscription?.cancel();
},
);

return controller.stream;
}

Future<void> deleteTransaction(String id) async {
final incomeRef =
_typeCollection(TransactionType.income).doc(id);

final expenseRef =
_typeCollection(TransactionType.expense).doc(id);

final incomeDoc = await incomeRef.get();

if (incomeDoc.exists) {
await incomeRef.delete();
} else {
await expenseRef.delete();
}
}
}