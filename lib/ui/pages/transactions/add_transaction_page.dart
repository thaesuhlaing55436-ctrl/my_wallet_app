 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/services/category_service.dart';

class AddTransactionPage extends StatefulWidget {
final WalletService? walletService;

const AddTransactionPage({
super.key,
this.walletService,
});

@override
State<AddTransactionPage> createState() =>
_AddTransactionPageState();
}

class _AddTransactionPageState
extends State<AddTransactionPage> {
final _formKey = GlobalKey<FormState>();

final _amountController = TextEditingController();
final _categoryController = TextEditingController();

final CategoryService _categoryService = CategoryService();

TransactionType _type = TransactionType.expense;
DateTime _selectedDate = DateTime.now();
bool _isSaving = false;

static const Color primaryBlue = Color(0xFF4B9FE1);

@override
void initState() {
super.initState();
_initializeCategories();
}

Future<void> _initializeCategories() async {
try {
await _categoryService.initializeCategories();
} catch (e) {
debugPrint('Initialize categories failed: $e');
}
}

void _changeType(TransactionType type) {
setState(() {
_type = type;
_categoryController.clear();
});
}

Future<void> _selectDate() async {
final picked = await showDatePicker(
context: context,
initialDate: _selectedDate,
firstDate: DateTime(2000),
lastDate: DateTime(2100),
);

if (picked != null && mounted) {
setState(() {
_selectedDate = picked;
});
}
}

Future<void> _saveTransaction() async {
if (!_formKey.currentState!.validate()) return;

final category = _categoryController.text.trim();
final amount = double.tryParse(_amountController.text.trim());

if (amount == null || !amount.isFinite || amount <= 0) {
return;
}

setState(() {
_isSaving = true;
});

try {
final wallet = widget.walletService ??
context.read<WalletService>();

await _categoryService.addCategory(category, _type);

final transaction = TransactionModel(
id: const Uuid().v4(),
title: category,
amount: amount,
category: category,
date: _selectedDate,
type: _type,
);

await wallet.addTransaction(transaction);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Transaction saved successfully'),
),
);

Navigator.pop(context);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Could not save transaction: $e'),
),
);
} finally {
if (mounted) {
setState(() {
_isSaving = false;
});
}
}
}

@override
void dispose() {
_amountController.dispose();
_categoryController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Add Transaction'),
backgroundColor: primaryBlue,
foregroundColor: Colors.white,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_label('Transaction Type'),

Row(
children: [
Expanded(
child: _typeButton(
'Income',
TransactionType.income,
),
),
const SizedBox(width: 12),
Expanded(
child: _typeButton(
'Expense',
TransactionType.expense,
),
),
],
),

const SizedBox(height: 24),

_label('Amount'),

TextFormField(
controller: _amountController,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
decoration: const InputDecoration(
hintText: 'Enter amount',
prefixText: 'MMK ',
border: OutlineInputBorder(),
),
validator: (value) {
final amount = double.tryParse(
value?.trim() ?? '',
);

if (amount == null ||
!amount.isFinite ||
amount <= 0) {
return 'Please enter a valid amount';
}

return null;
},
),

const SizedBox(height: 20),

_label('Category'),

StreamBuilder<List<String>>(
stream: _categoryService.getCategories(_type),
builder: (context, snapshot) {
final categories =
snapshot.data ?? <String>[];

return TextFormField(
controller: _categoryController,
decoration: InputDecoration(
hintText: 'Type or select category',
border: const OutlineInputBorder(),
suffixIcon: PopupMenuButton<String>(
icon: const Icon(
Icons.arrow_drop_down,
size: 30,
),
enabled: categories.isNotEmpty,
onSelected: (value) {
setState(() {
_categoryController.text = value;
});
},
itemBuilder: (context) {
return categories.map((category) {
return PopupMenuItem<String>(
value: category,
child: Text(category),
);
}).toList();
},
),
),
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Please enter or select category';
}
return null;
},
);
},
),

const SizedBox(height: 20),

_label('Date'),

InkWell(
onTap: _selectDate,
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
border: Border.all(
color: Colors.grey.shade400,
),
borderRadius: BorderRadius.circular(5),
),
child: Row(
children: [
const Icon(
Icons.calendar_month,
color: primaryBlue,
),
const SizedBox(width: 12),
Text(
 '${_selectedDate.day.toString().padLeft(2, '0')}/'
'${_selectedDate.month.toString().padLeft(2, '0')}/'
'${_selectedDate.year}',
),
],
),
),
),

const SizedBox(height: 30),

SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton(
onPressed:
_isSaving ? null : _saveTransaction,
style: ElevatedButton.styleFrom(
backgroundColor: primaryBlue,
foregroundColor: Colors.white,
),
child: _isSaving
? const CircularProgressIndicator(
color: Colors.white,
)
    : const Text(
'Save Transaction',
style: TextStyle(fontSize: 16),
),
),
),
],
),
),
),
);
}

Widget _label(String text) {
return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: Text(
text,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
);
}

Widget _typeButton(String label, TransactionType type) {
final selected = _type == type;

return ElevatedButton(
onPressed: () => _changeType(type),
style: ElevatedButton.styleFrom(
backgroundColor:
selected ? primaryBlue : Colors.grey.shade200,
foregroundColor:
selected ? Colors.white : Colors.black87,
padding: const EdgeInsets.symmetric(vertical: 14),
),
child: Text(label),
);
}
}