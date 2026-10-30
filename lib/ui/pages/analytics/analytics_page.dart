 import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:my_wallet_app/data/models/transaction_model.dart';
import 'package:my_wallet_app/data/services/wallet_service.dart';

class AnalyticsPage extends StatefulWidget {
final WalletService walletService;

const AnalyticsPage({
super.key,
required this.walletService,
});

@override
State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _PeriodOption {
final String key;
final String label;
final DateTime start;
final DateTime end;

const _PeriodOption({
required this.key,
required this.label,
required this.start,
required this.end,
});
}

class _AnalyticsPageState extends State<AnalyticsPage> {
String _period = 'Monthly';
String _selectedKey = '';
@override
void initState() {
 super.initState();

 final now = DateTime.now();
 _selectedKey = '${now.year}-${now.month}';
}

static const Color incomeColor = Color(0xFF4B9FE1);
static const Color expenseColor = Color(0xFFFF8A80);

static const List<Color> chartColors = [
Color(0xFF4B9FE1),
Color(0xFFFF8A80),
Color(0xFF9575CD),
Color(0xFFFFB74D),
Color(0xFF4DB6AC),
Color(0xFF7986CB),
Color(0xFFF06292),
Color(0xFF90A4AE),
Color(0xFF81C784),
];

String money(double amount) {
return '${amount.toStringAsFixed(0)} MMK';
}

String _monthName(int month) {
const months = [
'January',
'February',
'March',
'April',
'May',
'June',
'July',
'August',
'September',
'October',
'November',
'December',
];

return months[month - 1];
}

String _dateLabel(DateTime date) {
return '${date.day} ${_monthName(date.month)} ${date.year}';
}

List<_PeriodOption> _buildOptions() {
final now = DateTime.now();
final options = <_PeriodOption>[];

if (_period == 'Weekly') {
final today = DateTime(now.year, now.month, now.day);

final monday = today.subtract(
Duration(days: today.weekday - 1),
);

for (int i = 0; i < 12; i++) {
final start = monday.subtract(
Duration(days: 7 * i),
);

final end = start.add(
const Duration(days: 7),
);

final lastDay = end.subtract(
const Duration(days: 1),
);

options.add(
_PeriodOption(
key: start.toIso8601String(),
label: i == 0
? 'This Week'
    : '${_dateLabel(start)} - ${_dateLabel(lastDay)}',
start: start,
end: end,
),
);
}
} else if (_period == 'Monthly') {
 for (int month = 1; month <= 12; month++) {
  final start = DateTime(now.year, month, 1);

  final end = DateTime(now.year, month + 1, 1);

  options.add(
   _PeriodOption(
    key: '${now.year}-$month',
    label: month == now.month
        ? 'This Month (${_monthName(month)})'
        : '${_monthName(month)} ${now.year}',
    start: start,
    end: end,
   ),
  );
 }
} else {
for (int i = 0; i < 6; i++) {
final year = now.year - i;

options.add(
_PeriodOption(
key: '$year',
label: i == 0 ? 'This Year ($year)' : '$year',
start: DateTime(year, 1, 1),
end: DateTime(year + 1, 1, 1),
),
);
}
}

return options;
}

Map<String, double> _categoryTotals(
List<TransactionModel> transactions,
TransactionType type,
) {
final totals = <String, double>{};

for (final item in transactions) {
if (item.type != type) continue;

final category = item.category.trim().isEmpty
? 'Other'
    : item.category.trim();

totals[category] =
(totals[category] ?? 0) + item.amount;
}

return totals;
}

List<MapEntry<String, double>> _sortedCategories(
Map<String, double> totals,
) {
final result = totals.entries.toList();
 result.sort(
(a, b) => b.value.compareTo(a.value),
);

return result;
}

Color _categoryColor(int index) {
return chartColors[index % chartColors.length];
}

@override
Widget build(BuildContext context) {
final options = _buildOptions();

final selectedOption = options.firstWhere(
(option) => option.key == _selectedKey,
orElse: () => options.first,
);

return AnimatedBuilder(
animation: widget.walletService,
builder: (context, child) {
if (widget.walletService.isLoading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

final allTransactions =
widget.walletService.transactions;

final filteredTransactions =
allTransactions.where((item) {
return !item.date.isBefore(selectedOption.start) &&
item.date.isBefore(selectedOption.end);
}).toList();

final income = filteredTransactions
    .where(
(item) =>
item.type == TransactionType.income,
)
    .fold<double>(
0,
(sum, item) => sum + item.amount,
);

final expense = filteredTransactions
    .where(
(item) =>
item.type == TransactionType.expense,
)
    .fold<double>(
0,
(sum, item) => sum + item.amount,
);

final incomeCategories = _sortedCategories(
_categoryTotals(
filteredTransactions,
TransactionType.income,
),
);

final expenseCategories = _sortedCategories(
_categoryTotals(
filteredTransactions,
TransactionType.expense,
),
);

return Scaffold(
appBar: AppBar(
title: const Text(
'Analytics',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
// PERIOD DROPDOWN
DropdownButtonFormField<String>(
key: ValueKey(_period),
initialValue: _period,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'Period',
prefixIcon: Icon(Icons.date_range),
border: OutlineInputBorder(),
),
items: const [
DropdownMenuItem(
value: 'Weekly',
child: Text('Weekly'),
),
DropdownMenuItem(
value: 'Monthly',
child: Text('Monthly'),
),
DropdownMenuItem(
value: 'Yearly',
child: Text('Yearly'),
),
],
onChanged: (value) {
 if (value == null) return;

 setState(() {
  _period = value;

  if (value == 'Monthly') {
   final now = DateTime.now();
   _selectedKey = '${now.year}-${now.month}';
  } else {
   _selectedKey = '';
  }
 });
},
),

const SizedBox(height: 12),

// DATE DROPDOWN
DropdownButtonFormField<String>(
key: ValueKey(
'$_period-${selectedOption.key}',
),
initialValue: selectedOption.key,
isExpanded: true,
decoration: InputDecoration(
labelText: 'Select $_period',
prefixIcon: const Icon(
Icons.calendar_month,
 ),
border: const OutlineInputBorder(),
),
items: options.map((option) {
return DropdownMenuItem<String>(
value: option.key,
child: Text(
option.label,
overflow: TextOverflow.ellipsis,
),
);
}).toList(),
onChanged: (value) {
if (value == null) return;

setState(() {
_selectedKey = value;
});
},
),

const SizedBox(height: 20),

Text(
selectedOption.label,
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

// INCOME AND EXPENSE SUMMARY
Row(
children: [
Expanded(
child: _summaryCard(
'Income',
income,
incomeColor,
),
),
const SizedBox(width: 12),
Expanded(
child: _summaryCard(
'Expense',
expense,
expenseColor,
),
),
],
),

const SizedBox(height: 28),

// INCOME PIE CHART
_sectionTitle('Income'),

const SizedBox(height: 12),

_buildPieChart(
incomeCategories,
'No income items for this period.',
),

const SizedBox(height: 28),

// EXPENSE PIE CHART
_sectionTitle('Expenses'),

const SizedBox(height: 12),

_buildPieChart(
expenseCategories,
'No expense items for this period.',
),

const SizedBox(height: 24),
],
),
);
},
);
}

Widget _sectionTitle(String title) {
return Text(
title,
style: Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(
fontWeight: FontWeight.bold,
),
);
}

Widget _summaryCard(
String title,
double amount,
Color color,
) {
return Container(
padding: const EdgeInsets.all(18),
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

const SizedBox(height: 10),

FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.centerLeft,
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

Widget _buildPieChart(
List<MapEntry<String, double>> categories,
String emptyMessage,
) {
final total = categories.fold<double>(
0,
(sum, item) => sum + item.value,
);

return Card(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
if (categories.isEmpty || total <= 0)
SizedBox(
 height: 180,
child: Center(
child: Text(emptyMessage),
),
)
else ...[
SizedBox(
height: 220,
child: PieChart(
PieChartData(
sectionsSpace: 3,
centerSpaceRadius: 42,
sections: List.generate(
categories.length,
(i) {
final item = categories[i];

final percentage =
item.value / total * 100;

return PieChartSectionData(
value: item.value,
color: _categoryColor(i),
radius: 55,
title:
'${percentage.toStringAsFixed(0)}%',
titleStyle: const TextStyle(
color: Colors.white,
fontSize: 11,
fontWeight: FontWeight.bold,
),
);
},
),
),
),
),

const SizedBox(height: 24),

...List.generate(
categories.length,
(i) {
final item = categories[i];

final percentage =
item.value / total * 100;

return Padding(
padding: const EdgeInsets.only(
bottom: 14,
),
child: _legendRow(
color: _categoryColor(i),
title: item.key,
amount: item.value,
percentage: percentage,
),
);
},
),
],
],
),
),
);
}

Widget _legendRow({
required Color color,
required String title,
required double amount,
required double percentage,
}) {
return Row(
children: [
Container(
width: 12,
height: 12,
decoration: BoxDecoration(
color: color,
shape: BoxShape.circle,
),
),

const SizedBox(width: 10),

Expanded(
child: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),
),

Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Text(
money(amount),
style: const TextStyle(
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 3),

Text(
'${percentage.toStringAsFixed(1)}%',
style: const TextStyle(
color: Colors.grey,
fontSize: 12,
),
),
],
),
],
);
}
}