

import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/wallet_service.dart';

class TransactionsPage extends StatefulWidget {
final WalletService walletService;

const TransactionsPage({
super.key,
required this.walletService,
});

@override
State<TransactionsPage> createState() =>
_TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
WalletService get wallet => widget.walletService;

String _searchQuery = '';
String _selectedFilter = 'All';

String money(double amount) =>
'${amount.toStringAsFixed(0)} MMK';

static const List<String> _filterOptions = [
'All',
'Income',
'Expense',
'Food',
'Transport',
'Shopping',
'Bills',
'Health',
'Education',
'Salary',
'Business',
'Gift',
'Other',
];

List<TransactionModel> _filterTransactions(
List<TransactionModel> transactions,
) {
return transactions.where((item) {
final query = _searchQuery.trim().toLowerCase();

final matchesSearch =
item.title.toLowerCase().contains(query) ||
item.category.toLowerCase().contains(query) ||
(item.note ?? '').toLowerCase().contains(query);

bool matchesFilter;

if (_selectedFilter == 'All') {
matchesFilter = true;
} else if (_selectedFilter == 'Income') {
matchesFilter = item.type == TransactionType.income;
} else if (_selectedFilter == 'Expense') {
matchesFilter = item.type == TransactionType.expense;
} else {
matchesFilter = item.category == _selectedFilter;
}

return matchesSearch && matchesFilter;
}).toList();
}

Future<void> showTransactionForm({
TransactionModel? transaction,
}) async {
final formKey = GlobalKey<FormState>();

final titleController = TextEditingController(
text: transaction?.title ?? '',
);

final amountController = TextEditingController(
text: transaction == null
? ''
    : transaction.amount.toStringAsFixed(0),
);

final noteController = TextEditingController(
text: transaction?.note ?? '',
);

TransactionType type =
transaction?.type ?? TransactionType.expense;

String category = transaction?.category ?? 'Food';
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
'Other',
];

try {
await showDialog<void>(
context: context,
builder: (dialogContext) {
return StatefulBuilder(
builder: (dialogContext, setDialogState) {
final categories =
type == TransactionType.income
? incomeCategories
    : expenseCategories;

if (!categories.contains(category)) {
category = categories.first;
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
ButtonSegment(
value: TransactionType.expense,
label: Text('Expense'),
 icon: Icon(Icons.arrow_upward),
),
ButtonSegment(
value: TransactionType.income,
label: Text('Income'),
icon: Icon(Icons.arrow_downward),
),
],
selected: {type},
onSelectionChanged: (selected) {
setDialogState(() {
type = selected.first;
category =
type == TransactionType.income
? incomeCategories.first
    : expenseCategories.first;
});
},
),
const SizedBox(height: 12),

  TextFormField(
    controller: titleController,
    enabled: true,
    keyboardType: TextInputType.text,
    textCapitalization: TextCapitalization.sentences,
    decoration: const InputDecoration(
      labelText: 'Transaction Title',
      hintText: 'Enter title, e.g. Lunch or Salary',
      prefixIcon: Icon(Icons.edit_note),
      border: OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter a transaction title';
      }
      return null;
    },
  ),
const SizedBox(height: 12),

TextFormField(
controller: amountController,
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

  Autocomplete<String>(
    key: ValueKey(type),
    initialValue: TextEditingValue(text: category),
    optionsBuilder: (textEditingValue) {
      final query = textEditingValue.text.trim().toLowerCase();

      if (query.isEmpty) {
        return categories;
      }

      return categories.where(
            (item) => item.toLowerCase().contains(query),
      );
    },
    onSelected: (value) {
      category = value;
    },
    fieldViewBuilder: (
        context,
        textController,
        focusNode,
        onFieldSubmitted,
        ) {
      return TextFormField(
        controller: textController,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Category',
          hintText: 'Choose or type a category',
          prefixIcon: Icon(Icons.category_outlined),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a category';
          }
          return null;
        },
        onChanged: (value) {
          category = value.trim();
        },
      );
    },
  ),
const SizedBox(height: 12),
 TextFormField(
controller: noteController,
maxLines: 2,
decoration: const InputDecoration(
labelText: 'Note (optional)',
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),

OutlinedButton.icon(
onPressed: () async {
final picked = await showDatePicker(
context: dialogContext,
initialDate: date,
firstDate: DateTime(2000),
lastDate: DateTime.now(),
);

if (picked != null &&
dialogContext.mounted) {
setDialogState(() {
date = picked;
});
}
},
icon: const Icon(
Icons.calendar_month,
),
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
onPressed: () {
Navigator.pop(dialogContext);
},
child: const Text('Cancel'),
),
FilledButton(
onPressed: () async {
if (!formKey.currentState!.validate()) {
return;
}

final amount = double.parse(
amountController.text.trim(),
);

final newTransaction = TransactionModel(
id: transaction?.id ??
DateTime.now()
    .microsecondsSinceEpoch
    .toString(),
title: titleController.text.trim(),
amount: amount,
category: category.trim(),
date: date,
type: type,
note: noteController.text.trim().isEmpty
? null
    : noteController.text.trim(),
);

try {
if (transaction == null) {
await wallet.addTransaction(
newTransaction,
);
} else {
await wallet.updateTransaction(
newTransaction,
);
}

if (!dialogContext.mounted) return;

Navigator.pop(dialogContext);
} catch (error) {
if (!dialogContext.mounted) return;

ScaffoldMessenger.of(
dialogContext,
).showSnackBar(
SnackBar(
content: Text(
'Could not save transaction: $error',
),
),
);
}
},
child: const Text('Save'),
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
noteController.dispose();
}
}
 Future<void> deleteTransaction(
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

if (confirmed == true && mounted) {
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
padding: const EdgeInsets.fromLTRB(
16, 12, 16, 8,
),
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
Padding(
padding: const EdgeInsets.fromLTRB(
16, 0, 16, 8,
),
child: DropdownButtonFormField<String>(
initialValue: _selectedFilter,
isExpanded: true,
decoration: InputDecoration(
labelText: 'Filter transactions',
prefixIcon: const Icon(Icons.filter_list),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
),
),
items: _filterOptions.map((option) {
return DropdownMenuItem<String>(
value: option,
child: Text(option),
);
}).toList(),
onChanged: (value) {
if (value != null) {
setState(() {
_selectedFilter = value;
});
}
},
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