
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/transaction_model.dart';
import '../../services/wallet_service.dart';

class AddTransactionPage extends StatefulWidget {
const AddTransactionPage({super.key});

@override
State<AddTransactionPage> createState() =>
_AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
final _formKey = GlobalKey<FormState>();
final _titleController = TextEditingController();
final _amountController = TextEditingController();
final _noteController = TextEditingController();

final List<String> _categories = [
'Food',
'Transport',
'Shopping',
'Bills',
'Salary',
'Business',
'Entertainment',
'Health',
'Other',
];

TransactionType _type = TransactionType.expense;
String _category = 'Food';
DateTime _date = DateTime.now();
bool _saving = false;

Future<void> _selectDate() async {
final selected = await showDatePicker(
context: context,
initialDate: _date,
firstDate: DateTime(2000),
lastDate: DateTime.now(),
);

if (!mounted) return;

if (selected != null) {
setState(() => _date = selected);
}
}

Future<void> _saveTransaction() async {
if (_saving) return;

if (!_formKey.currentState!.validate()) return;

FocusScope.of(context).unfocus();
setState(() => _saving = true);

try {
final transaction = TransactionModel(
id: const Uuid().v4(),
title: _titleController.text.trim(),
amount: double.parse(_amountController.text.trim()),
category: _category,
date: _date,
type: _type,
note: _noteController.text.trim().isEmpty
? null
    : _noteController.text.trim(),
);

await context
    .read<WalletService>()
    .addTransaction(transaction);

if (!mounted) return;

Navigator.pop(context, true);
} catch (e, stackTrace) {
debugPrint('Save transaction failed: $e');
debugPrintStack(stackTrace: stackTrace);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Save failed: $e'),
duration: const Duration(seconds: 5),
),
);
} finally {
if (mounted) {
setState(() => _saving = false);
}
}
}

@override
void dispose() {
_titleController.dispose();
_amountController.dispose();
_noteController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;

final availableCategories = _categories.where((category) {
if (_type == TransactionType.income) {
return ['Salary', 'Business', 'Other'].contains(category);
}

return category != 'Salary' && category != 'Business';
}).toList();

return Scaffold(
appBar: AppBar(
title: const Text('Add Transaction'),
),
body: SafeArea(
child: Form(
key: _formKey,
child: ListView(
padding: const EdgeInsets.all(20),
children: [
SegmentedButton<TransactionType>(
segments: const [
ButtonSegment<TransactionType>(
value: TransactionType.income,
label: Text('Income'),
icon: Icon(Icons.trending_up),
),
ButtonSegment<TransactionType>(
value: TransactionType.expense,
label: Text('Expense'),
icon: Icon(Icons.trending_down),
),
],
selected: {_type},
onSelectionChanged: (selection) {
setState(() {
_type = selection.first;
_category = _type == TransactionType.income
? 'Salary'
    : 'Food';
});
},
),
const SizedBox(height: 24),

TextFormField(
controller: _titleController,
textCapitalization: TextCapitalization.sentences,
decoration: const InputDecoration(
labelText: 'Title',
hintText: 'e.g. Lunch or Monthly salary',
prefixIcon: Icon(Icons.title),
border: OutlineInputBorder(),
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Please enter a title';
}
return null;
},
),
const SizedBox(height: 16),

TextFormField(
controller: _amountController,
keyboardType:
const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(
labelText: 'Amount (MMK)',
hintText: 'Enter amount',
prefixIcon: Icon(Icons.payments_outlined),
border: OutlineInputBorder(),
),
validator: (value) {
final amount = double.tryParse(value?.trim() ?? '');

if (amount == null ||
!amount.isFinite ||
amount <= 0) {
return 'Enter a valid amount greater than 0';
}

return null;
},
),
const SizedBox(height: 16),

DropdownButtonFormField<String>(
initialValue: _category,
decoration: const InputDecoration(
labelText: 'Category',
prefixIcon: Icon(Icons.category_outlined),
border: OutlineInputBorder(),
),
items: availableCategories.map((category) {
return DropdownMenuItem<String>(
value: category,
child: Text(category),
);
}).toList(),
onChanged: (value) {
if (value != null) {
setState(() => _category = value);
}
},
),
const SizedBox(height: 16),

InkWell(
onTap: _selectDate,
child: InputDecorator(
decoration: const InputDecoration(
labelText: 'Date',
prefixIcon: Icon(Icons.calendar_month),
border: OutlineInputBorder(),
),
child: Text(
'${_date.day.toString().padLeft(2, '0')}/'
'${_date.month.toString().padLeft(2, '0')}/'
'${_date.year}',
),
),
),
const SizedBox(height: 16),

TextFormField(
controller: _noteController,
maxLines: 3,
textCapitalization: TextCapitalization.sentences,
decoration: const InputDecoration(
labelText: 'Note (Optional)',
hintText: 'Add a note...',
prefixIcon: Icon(Icons.notes),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 28),
 SizedBox(
height: 52,
child: FilledButton.icon(
onPressed: _saving ? null : _saveTransaction,
icon: _saving
? const SizedBox(
height: 20,
width: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.save_outlined),
label: Text(
_saving ? 'Saving...' : 'Save Transaction',
),
),
),
const SizedBox(height: 12),

Text(
'Your transaction will be saved on this device.',
textAlign: TextAlign.center,
style: TextStyle(
color: colors.onSurfaceVariant,
fontSize: 12,
),
),
],
),
),
),
);
}
}