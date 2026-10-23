
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../../services/wallet_service.dart';

class AnalyticsPage extends StatelessWidget {
final WalletService walletService;

const AnalyticsPage({
super.key,
required this.walletService,
});

String money(double amount) {
return '${amount.toStringAsFixed(0)} MMK';
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: walletService,
builder: (context, child) {
if (walletService.isLoading) {
return const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
);
}

final transactions = walletService.transactions;
final now = DateTime.now();

final monthlyTransactions = transactions.where((item) {
return item.date.year == now.year &&
item.date.month == now.month;
}).toList();

final monthlyIncome = monthlyTransactions
.where((item) =>
item.type == TransactionType.income)
.fold<double>(
0, (sum, item) => sum + item.amount);

final monthlyExpense = monthlyTransactions
.where((item) =>
item.type == TransactionType.expense)
.fold<double>(
0, (sum, item) => sum + item.amount);

final Map<String, double> categoryExpenses = {};

for (final item in monthlyTransactions) {
if (item.type == TransactionType.expense) {
categoryExpenses[item.category] =
(categoryExpenses[item.category] ?? 0) +
item.amount;
}
}

final sortedCategories = categoryExpenses.entries
.toList()
..sort((a, b) => b.value.compareTo(a.value));

return Scaffold(
appBar: AppBar(
title: const Text(
'Analytics',
style: TextStyle(fontWeight: FontWeight.bold),
),
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
Text(
'Overview • ${_monthName(now.month)} ${now.year}',
style: Theme.of(context)
.textTheme
.titleLarge
?.copyWith(fontWeight: FontWeight.bold),
),
const SizedBox(height: 16),

Row(
children: [
Expanded(
child: _summaryCard(
'Income',
monthlyIncome,
const Color(0xFF2EAD75),
),
),
const SizedBox(width: 12),
Expanded(
child: _summaryCard(
'Expense',
monthlyExpense,
const Color(0xFFE85D75),
),
),
],
),

const SizedBox(height: 24),

_sectionTitle(context, 'Income vs Expense'),
const SizedBox(height: 12),

Card(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
SizedBox(
height: 220,
child: BarChart(
BarChartData(
alignment:
BarChartAlignment.spaceEvenly,
gridData: const FlGridData(
show: true,
drawVerticalLine: false,
),
borderData: FlBorderData(
show: false,
),
titlesData: FlTitlesData(
topTitles:
const AxisTitles(
sideTitles: SideTitles(
showTitles: false,
),
),
rightTitles:
const AxisTitles(
sideTitles: SideTitles(
showTitles: false,
),
),
leftTitles: const AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 42,
),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
getTitlesWidget:
(value, meta) {
String label;

switch (value.toInt()) {
case 0:
label = 'Income';
break;
case 1:
label = 'Expense';
break;
default:
return const SizedBox();
}

return SideTitleWidget(
meta: meta,
child: Text(
label,
style:
const TextStyle(
fontSize: 11,
),
),
);
},
),
),
),
barGroups: [
_barGroup(
0,
monthlyIncome,
const Color(0xFF2EAD75),
),
_barGroup(
1,
monthlyExpense,
const Color(0xFFE85D75),
),
],
),
),
),
const SizedBox(height: 12),
const Text(
'Current month totals',
style: TextStyle(color: Colors.grey),
),
],
),
),
),

const SizedBox(height: 24),

_sectionTitle(
context,
'Expense by Category',
),
const SizedBox(height: 12),

if (sortedCategories.isEmpty)
const Card(
child: Padding(
padding: EdgeInsets.all(24),
child: Center(
child: Text(
'No expenses recorded this month.',
textAlign: TextAlign.center,
),
),
),
)
else
Card(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: sortedCategories.map((entry) {
final percentage = monthlyExpense > 0
? entry.value / monthlyExpense
: 0.0;

return Padding(
padding:
const EdgeInsets.only(bottom: 18),
child: Column(
children: [
Row(
children: [
Expanded(
child: Text(
entry.key,
style: const TextStyle(
fontWeight:
FontWeight.w600,
),
),
),
Text(money(entry.value)),
const SizedBox(width: 8),
Text(
'${(percentage * 100).toStringAsFixed(1)}%',
style: const TextStyle(
color: Colors.grey,
fontSize: 12,
),
),
],
),
const SizedBox(height: 8),
ClipRRect(
borderRadius:
BorderRadius.circular(8),
child: LinearProgressIndicator(
value: percentage,
minHeight: 9,
backgroundColor:
Colors.grey.withValues(
alpha: 0.15,
),
color: const Color(0xFF4B9FE1),
),
),
],
),
);
}).toList(),
),
),
),

const SizedBox(height: 24),

_sectionTitle(context, 'Overall Balance'),
const SizedBox(height: 12),

_summaryCard(
'All-time balance',
walletService.balance,
const Color(0xFF4B9FE1),
),
],
),
);
},
);
}

BarChartGroupData _barGroup(
int x,
double amount,
Color color,
) {
return BarChartGroupData(
x: x,
barRods: [
BarChartRodData(
toY: amount,
color: color,
width: 34,
borderRadius: const BorderRadius.vertical(
top: Radius.circular(6),
),
),
],
);
}

Widget _sectionTitle(
BuildContext context,
String title,
) {
return Text(
title,
style: Theme.of(context)
.textTheme
.titleMedium
?.copyWith(fontWeight: FontWeight.bold),
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
}