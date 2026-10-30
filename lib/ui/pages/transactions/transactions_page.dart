 import 'package:flutter/material.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/services/category_service.dart';
import 'add_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
final WalletService walletService;
final String initialFilter;

const TransactionsPage({
super.key,
required this.walletService,
this.initialFilter = 'All',
});

@override
State<TransactionsPage> createState() =>
_TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
WalletService get wallet => widget.walletService;

final CategoryService _categoryService = CategoryService();

String _searchQuery = '';
late String _selectedFilter;

final TextEditingController _searchController =
TextEditingController();

@override
void initState() {
super.initState();
_selectedFilter = widget.initialFilter;
}

String money(double amount) {
final value = amount.toStringAsFixed(0);

final formatted = value.replaceAllMapped(
RegExp(r'\B(?=(\d{3})+(?!\d))'),
(match) => ',',
);

return '$formatted MMK';
}

List<TransactionModel> _filterTransactions(
List<TransactionModel> transactions,
) {
final query = _searchQuery.trim().toLowerCase();

return transactions.where((item) {
final matchesSearch =
item.title.toLowerCase().contains(query) ||
item.category.toLowerCase().contains(query);

final matchesFilter =
_selectedFilter == 'All' ||
(_selectedFilter == 'Income' &&
item.type == TransactionType.income) ||
(_selectedFilter == 'Expense' &&
item.type == TransactionType.expense);

return matchesSearch && matchesFilter;
}).toList();
}

Future<void> _openAddTransaction() async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => AddTransactionPage(
walletService: wallet,
),
),
);
}

Future<void> _editTransaction(
TransactionModel item,
) async {
final formKey = GlobalKey<FormState>();

final titleController = TextEditingController(
text: item.title,
);

final amountController = TextEditingController(
text: item.amount.toString(),
);

final categoryController = TextEditingController(
text: item.category,
);

TransactionType type = item.type;
bool saving = false;

try {
await showDialog<void>(
context: context,
builder: (dialogContext) {
return StatefulBuilder(
builder: (context, setDialogState) {
Future<void> save() async {
if (saving) return;

if (!(formKey.currentState?.validate() ??
false)) {
return;
}

final amount = double.tryParse(
amountController.text.trim(),
);

if (amount == null ||
!amount.isFinite ||
amount <= 0) {
return;
}

setDialogState(() {
saving = true;
});

final updatedTransaction = TransactionModel(
id: item.id,
title: titleController.text.trim(),
amount: amount,
category: categoryController.text.trim(),
date: item.date,
type: type,
note: item.note,
);

try {
await _categoryService.addCategory(
updatedTransaction.category,
type,
);

await wallet.updateTransaction(
updatedTransaction,
);
 if (dialogContext.mounted) {
Navigator.pop(dialogContext);
}
} catch (error) {
if (dialogContext.mounted) {
setDialogState(() {
saving = false;
});
}

if (!mounted) return;

ScaffoldMessenger.of(this.context)
    .showSnackBar(
SnackBar(
content: Text(
'Could not update transaction: $error',
),
),
);
}
}

return AlertDialog(
title: const Text('Edit Transaction'),
content: SingleChildScrollView(
child: Form(
key: formKey,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
SegmentedButton<TransactionType>(
segments: const [
ButtonSegment<TransactionType>(
value: TransactionType.expense,
label: Text('Expense'),
icon: Icon(Icons.arrow_upward),
),
ButtonSegment<TransactionType>(
value: TransactionType.income,
label: Text('Income'),
icon: Icon(Icons.arrow_downward),
),
],
selected: {type},
onSelectionChanged: saving
? null
    : (selected) {
setDialogState(() {
type = selected.first;
categoryController.clear();
});
},
),

const SizedBox(height: 12),

TextFormField(
controller: titleController,
enabled: !saving,
decoration: const InputDecoration(
labelText: 'Title',
border: OutlineInputBorder(),
),
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Please enter a title';
}
return null;
},
),

const SizedBox(height: 12),

StreamBuilder<List<String>>(
stream: _categoryService.getCategories(type),
builder: (context, snapshot) {
final categories =
snapshot.data ?? <String>[];

return TextFormField(
controller: categoryController,
enabled: !saving,
decoration: InputDecoration(
labelText: 'Category',
border: const OutlineInputBorder(),
suffixIcon:
PopupMenuButton<String>(
icon: const Icon(
Icons.arrow_drop_down,
),
 enabled: !saving &&
categories.isNotEmpty,
onSelected: (value) {
setDialogState(() {
categoryController.text =
value;
});
},
itemBuilder: (context) {
return categories.map(
(category) {
return PopupMenuItem<String>(
value: category,
child: Text(category),
);
},
).toList();
},
),
),
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Please select a category';
}

return null;
},
);
},
),

const SizedBox(height: 12),

TextFormField(
controller: amountController,
enabled: !saving,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
decoration: const InputDecoration(
labelText: 'Amount (MMK)',
border: OutlineInputBorder(),
),
validator: (value) {
final amount = double.tryParse(
value?.trim() ?? '',
);

if (amount == null ||
!amount.isFinite ||
amount <= 0) {
return 'Enter an amount greater than zero';
}

return null;
},
),
],
),
),
),
actions: [
TextButton(
onPressed: saving
? null
    : () => Navigator.pop(dialogContext),
child: const Text('Cancel'),
),
FilledButton(
onPressed: saving ? null : save,
child: Text(
saving ? 'Saving...' : 'Save',
),
),
],
);
},
);
},
);
} finally {
titleController.dispose();
amountController.dispose();
categoryController.dispose();
}
}

Future<void> _deleteTransaction(
TransactionModel item,
) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Delete Transaction?'),
content: Text('Delete "${item.title}"?'),
actions: [
TextButton(
onPressed: () {
Navigator.pop(dialogContext, false);
},
child: const Text('Cancel'),
),
FilledButton(
onPressed: () {
Navigator.pop(dialogContext, true);
},
child: const Text('Delete'),
),
],
);
},
);
if (confirmed != true || !mounted) return;

try {
await wallet.deleteTransaction(item.id);
} catch (error) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'Could not delete transaction: $error',
),
),
);
}
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: wallet,
builder: (context, child) {
if (wallet.isLoading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

final transactions = wallet.transactions;

final filteredTransactions =
_filterTransactions(transactions);

return Scaffold(
appBar: AppBar(
title: const Text(
'Transactions',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
_summaryCard(
'Balance',
wallet.balance,
const Color(0xFF4B9FE1),
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: _summaryCard(
'Income',
wallet.totalIncome,
const Color(0xFF2EAD75),
),
),
const SizedBox(width: 12),
Expanded(
child: _summaryCard(
'Expense',
wallet.totalExpense,
const Color(0xFFE85D75),
),
),
],
),
],
),
),

const Divider(height: 1),

// Search
Padding(
padding: const EdgeInsets.fromLTRB(
16, 12, 16, 8,
),
child: TextField(
controller: _searchController,
onChanged: (value) {
setState(() {
_searchQuery = value;
});
},
decoration: InputDecoration(
hintText: 'Search transactions...',
prefixIcon: const Icon(Icons.search),
suffixIcon: IconButton(
onPressed: () {
_searchController.clear();

setState(() {
_searchQuery = '';
});
},
icon: const Icon(Icons.clear),
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
),
),
),
),

// Filter
Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 8,
),
child: Row(
children: [
_filterButton('All'),
const SizedBox(width: 8),
_filterButton('Income'),
const SizedBox(width: 8),
_filterButton('Expense'),
],
),
),
// Transaction List
Expanded(
child: filteredTransactions.isEmpty
? Center(
child: Text(
transactions.isEmpty
? 'No transactions yet.\nTap + to add one.'
    : 'No matching transactions found.',
textAlign: TextAlign.center,
),
)
    : ListView.builder(
padding: const EdgeInsets.all(12),
itemCount: filteredTransactions.length,
itemBuilder: (context, index) {
final item =
filteredTransactions[index];

final isIncome =
item.type == TransactionType.income;

final color = isIncome
? const Color(0xFF2EAD75)
    : const Color(0xFFE85D75);

return Card(
child: ListTile(
leading: CircleAvatar(
backgroundColor:
color.withValues(alpha: 0.12),
child: Icon(
isIncome
? Icons.arrow_downward
    : Icons.arrow_upward,
color: color,
),
),
title: Text(item.title),
subtitle: Text(
'${item.category} • '
'${item.date.day}/'
'${item.date.month}/'
'${item.date.year}',
),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'${isIncome ? '+' : '-'}'
'${money(item.amount)}',
style: TextStyle(
color: color,
fontWeight: FontWeight.bold,
),
),
PopupMenuButton<String>(
onSelected: (value) {
if (value == 'edit') {
_editTransaction(item);
} else if (value == 'delete') {
_deleteTransaction(item);
}
},
itemBuilder: (context) => const [
PopupMenuItem<String>(
value: 'edit',
child: Text('Edit'),
),
PopupMenuItem<String>(
value: 'delete',
child: Text('Delete'),
),
],
),
],
),
),
);
},
),
),
],
),
floatingActionButton:
FloatingActionButton.extended(
onPressed: _openAddTransaction,
icon: const Icon(Icons.add),
label: const Text('Add Transaction'),
),
);
},
);
}
Widget _filterButton(String filter) {
final selected = _selectedFilter == filter;

return Expanded(
child: OutlinedButton(
onPressed: () {
setState(() {
_selectedFilter = filter;
});
},
style: OutlinedButton.styleFrom(
backgroundColor: selected
? const Color(0xFF4B9FE1)
    : Colors.transparent,
foregroundColor: selected
? Colors.white
    : const Color(0xFF4B9FE1),
),
child: Text(filter),
),
);
}

Widget _summaryCard(
String title,
double amount,
Color color,
) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(18),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(color: color),
),
const SizedBox(height: 8),
FittedBox(
fit: BoxFit.scaleDown,
child: Text(
money(amount),
style: TextStyle(
color: color,
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),
],
),
);
}
}