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

class _AddTransactionPageState extends State<AddTransactionPage> {
final _formKey = GlobalKey<FormState>();
final _amountController = TextEditingController();
final _categoryController = TextEditingController();

final CategoryService _categoryService = CategoryService();

static const List<String> _incomeCategories = [
'Salary',
'Business',
'Gift',
'Other',
];

static const List<String> _expenseCategories = [
'Food',
'Transport',
'Shopping',
'Bills',
'Health',
'Education',
'Gift',
'Other',
];

TransactionType _type = TransactionType.expense;
String _category = 'Food';
DateTime _date = DateTime.now();
bool _saving = false;

@override
void initState() {
super.initState();
_categoryController.text = _category;
_initializeCategories();
}

Future<void> _initializeCategories() async {
try {
await _categoryService.initializeCategories();
} catch (e) {
debugPrint('Initialize categories failed: $e');
}
}

List<String> get _defaultCategories {
return _type == TransactionType.income
? _incomeCategories
    : _expenseCategories;
}

void _changeType(TransactionType type) {
setState(() {
_type = type;
_category = type == TransactionType.income
? 'Salary'
    : 'Food';
_categoryController.text = _category;
});
}

Future<void> _addCategory() async {
final controller = TextEditingController();

final name = await showDialog<String>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Add Category'),
content: TextField(
controller: controller,
autofocus: true,
textCapitalization: TextCapitalization.words,
decoration: const InputDecoration(
labelText: 'Category name',
border: OutlineInputBorder(),
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () {
final value = controller.text.trim();
if (value.isNotEmpty) {
Navigator.pop(dialogContext, value);
}
},
child: const Text('Add'),
),
],
),
);

controller.dispose();

if (name == null || !mounted) return;

try {
await _categoryService.addCategory(name, _type);

if (!mounted) return;

setState(() {
_category = name.trim();
_categoryController.text = _category;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Category saved')),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Add category failed: $e')),
);
}
}

Future<void> _deleteCategory(
String categoryId,
String name,
) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('Delete Category?'),
content: Text('Delete "$name"?'),
actions: [
 TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('Cancel'),
),
FilledButton(
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('Delete'),
),
],
),
);

if (confirmed != true || !mounted) return;

try {
await _categoryService.deleteCategory(categoryId);

if (!mounted) return;

setState(() {
_category = _type == TransactionType.income
? 'Salary'
    : 'Food';
_categoryController.text = _category;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Category deleted')),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Delete failed: $e')),
);
}
}

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

// Read the service before any await.
final service =
widget.walletService ?? context.read<WalletService>();

FocusScope.of(context).unfocus();

setState(() => _saving = true);

try {
final categoryName = _categoryController.text.trim();

// Save category first. Duplicate categories are ignored.
await _categoryService.addCategory(categoryName, _type);

if (!mounted) return;

final transaction = TransactionModel(
id: const Uuid().v4(),
title: categoryName,
amount: double.parse(_amountController.text.trim()),
category: categoryName,
date: _date,
type: _type,
note: null,
);

await service.addTransaction(transaction);

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
_amountController.dispose();
_categoryController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;

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
_changeType(selection.first);
},
),

const SizedBox(height: 24),

StreamBuilder(
stream: _categoryService.getCategories(_type),
builder: (context, snapshot) {
final docs = snapshot.data?.docs ?? [];
 final firestoreNames = docs
    .map((doc) => doc.data()['name'])
    .whereType<String>()
    .where((name) => name.trim().isNotEmpty)
    .toList();

final names = <String>{
..._defaultCategories,
...firestoreNames,
}.toList();

final selectedCategory =
names.contains(_category) ? _category : null;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Category',
style: TextStyle(
fontWeight: FontWeight.w600,
fontSize: 15,
),
),

const SizedBox(height: 8),

Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: TextFormField(
controller: _categoryController,
textCapitalization:
TextCapitalization.words,
decoration: const InputDecoration(
hintText: 'Enter category',
prefixIcon:
Icon(Icons.category_outlined),
border: OutlineInputBorder(),
),
onChanged: (value) {
_category = value.trim();
},
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Please enter a category';
}
return null;
},
),
),

const SizedBox(width: 8),

Expanded(
child: DropdownButtonFormField<String>(
key: ValueKey(
'${_type.name}-$selectedCategory',
),
initialValue: selectedCategory,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'Choose',
border: OutlineInputBorder(),
),
items: names.map((name) {
return DropdownMenuItem<String>(
value: name,
child: Text(
name,
overflow: TextOverflow.ellipsis,
),
);
}).toList(),
onChanged: (value) {
if (value != null) {
setState(() {
_category = value;
_categoryController.text = value;
});
}
},
),
),
],
),

const SizedBox(height: 8),
 Row(
children: [
TextButton.icon(
onPressed: _addCategory,
icon: const Icon(Icons.add),
label: const Text('Add Category'),
),

const Spacer(),

IconButton(
tooltip: 'Delete selected category',
onPressed: () {
final matchingDocs = docs.where(
(doc) =>
doc.data()['name'] ==
_categoryController.text.trim(),
);

if (matchingDocs.isEmpty) {
ScaffoldMessenger.of(context)
    .showSnackBar(
const SnackBar(
content: Text(
'This category cannot be deleted.',
),
),
);
return;
}

final doc = matchingDocs.first;

_deleteCategory(
doc.id,
_categoryController.text.trim(),
);
},
icon: const Icon(Icons.delete_outline),
),
],
),

if (snapshot.hasError)
Text(
'Firestore error: ${snapshot.error}',
style: TextStyle(color: colors.error),
),
],
);
},
),

const SizedBox(height: 16),

TextFormField(
controller: _amountController,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
decoration: const InputDecoration(
labelText: 'Amount (MMK)',
hintText: 'Enter amount',
prefixIcon: Icon(Icons.payments_outlined),
border: OutlineInputBorder(),
),
validator: (value) {
final amount =
double.tryParse(value?.trim() ?? '');

if (amount == null ||
!amount.isFinite ||
amount <= 0) {
return 'Enter a valid amount greater than 0';
}

return null;
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
'Your transaction will sync with your account.',
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