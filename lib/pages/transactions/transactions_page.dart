 import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/wallet_service.dart';

class TransactionsPage extends StatefulWidget {
final WalletService walletService;
final String initialFilter;

const TransactionsPage({
super.key,
required this.walletService,
this.initialFilter = 'All',
});

@override
State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
WalletService get wallet => widget.walletService;

String _searchQuery = '';

String money(double amount) => '${amount.toStringAsFixed(0)} MMK';

List<TransactionModel> _filterTransactions(
List<TransactionModel> transactions,
) {
final query = _searchQuery.trim().toLowerCase();

if (query.isEmpty) return transactions;

return transactions.where((item) {
return item.title.toLowerCase().contains(query) ||
item.category.toLowerCase().contains(query);
}).toList();
}

Future<void> showTransactionForm({
TransactionModel? transaction,
}) async {
final formKey = GlobalKey<FormState>();

final amountController = TextEditingController(
text: transaction == null ? '' : transaction.amount.toString(),
);

final categoryController = TextEditingController(
text: transaction?.category ??
(transaction?.type == TransactionType.income
? 'Salary'
    : 'Food'),
);

TransactionType type =
transaction?.type ?? TransactionType.expense;

DateTime date = transaction?.date ?? DateTime.now();

const incomeCategories = [
'Salary',
'Business',
'Gift',
'Other',
];

const expenseCategories = [
'Food',
'Transport',
'Shopping',
'Bills',
'Health',
'Education',
'Gift',
'Other',
];

bool saving = false;

try {
await showDialog<void>(
context: context,
barrierDismissible: false,
builder: (dialogContext) {
return StatefulBuilder(
builder: (stateContext, setDialogState) {
final categories = type == TransactionType.income
? incomeCategories
    : expenseCategories;

Future<void> saveTransaction() async {
if (saving) return;

if (!(formKey.currentState?.validate() ?? false)) {
return;
}

setDialogState(() {
saving = true;
});

final category = categoryController.text.trim();

final newTransaction = TransactionModel(
id: transaction?.id ??
DateTime.now()
    .microsecondsSinceEpoch
    .toString(),
title: category,
amount: double.parse(
amountController.text.trim(),
),
category: category,
date: date,
type: type,
note: transaction?.note,
);

try {
if (transaction == null) {
await wallet.addTransaction(newTransaction);
} else {
await wallet.updateTransaction(newTransaction);
}

if (!mounted || !dialogContext.mounted) return;

Navigator.of(dialogContext).pop();
} catch (error, stackTrace) {
debugPrint('Save transaction error: $error');
debugPrintStack(stackTrace: stackTrace);

if (stateContext.mounted) {
setDialogState(() {
saving = false;
});
}
if (mounted) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
'Could not save transaction: $error',
),
),
);
}
}
}

return AlertDialog(
title: Text(
transaction == null
? 'Add Transaction'
    : 'Edit Transaction',
),
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

categoryController.text =
type == TransactionType.income
? 'Salary'
    : 'Food';
});
},
),
const SizedBox(height: 12),

// Category
TextFormField(
controller: categoryController,
enabled: !saving,
textCapitalization: TextCapitalization.words,
decoration: InputDecoration(
labelText: 'Category',
hintText: categories.join(', '),
border: const OutlineInputBorder(),
),
validator: (value) {
if (value == null ||
value.trim().isEmpty) {
return 'Please enter a category';
}

return null;
},
),
const SizedBox(height: 12),

// Amount
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
const SizedBox(height: 12),

// Date
OutlinedButton.icon(
onPressed: saving
? null
    : () async {
final picked = await showDatePicker(
context: stateContext,
initialDate: date,
firstDate: DateTime(2000),
lastDate: DateTime.now(),
);

if (picked != null &&
stateContext.mounted) {
setDialogState(() {
date = picked;
});
}
},
icon: const Icon(Icons.calendar_month),
label: Text(
'${date.day}/${date.month}/${date.year}',
),
),
],
),
),
),
actions: [
TextButton(
onPressed: saving
? null
    : () => Navigator.of(dialogContext).pop(),
child: const Text('Cancel'),
),
FilledButton(
onPressed: saving ? null : saveTransaction,
child: Text(saving ? 'Saving...' : 'Save'),
),
],
);
},
);
},
);
} finally {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    amountController.dispose();
    categoryController.dispose();
  });
}
}

Future<void> deleteTransaction(TransactionModel item) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('Delete Transaction?'),
content: Text('Delete "${item.title}"?'),
actions: [
TextButton(
onPressed: () {
Navigator.of(dialogContext).pop(false);
},
child: const Text('Cancel'),
),
FilledButton(
onPressed: () {
Navigator.of(dialogContext).pop(true);
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
content: Text('Could not delete transaction: $error'),
),
);
}
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
style: TextStyle(fontWeight: FontWeight.bold),
),
),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
summaryCard(
'Balance',
wallet.balance,
const Color(0xFF4B9FE1),
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: summaryCard(
'Income',
wallet.totalIncome,
const Color(0xFF2EAD75),
),
),
const SizedBox(width: 12),
Expanded(
child: summaryCard(
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
Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
child: TextField(
onChanged: (value) {
setState(() {
_searchQuery = value;
});
},
decoration: InputDecoration(
hintText: 'Search transactions...',
prefixIcon: const Icon(Icons.search),
suffixIcon: _searchQuery.isNotEmpty
? IconButton(
onPressed: () {
setState(() {
_searchQuery = '';
});
},
icon: const Icon(Icons.clear),
)
    : null,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
),
),
),
),
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
final item = filteredTransactions[index];
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
showTransactionForm(
transaction: item,
);
} else if (value == 'delete') {
deleteTransaction(item);
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
floatingActionButton: FloatingActionButton.extended(
onPressed: () => showTransactionForm(),
icon: const Icon(Icons.add),
label: const Text('Add Transaction'),
),
);
},
);
}

Widget summaryCard(
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