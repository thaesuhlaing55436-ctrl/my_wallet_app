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

String compactMoney(double amount) {
if (amount >= 1000000) {
return '${(amount / 1000000).toStringAsFixed(1)}M';
}
if (amount >= 1000) {
return '${(amount / 1000).toStringAsFixed(1)}k';
}
return amount.toStringAsFixed(0);
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: walletService,
builder: (context, child) {
if (walletService.isLoading) {
return const Scaffold(
body: Center(child: CircularProgressIndicator()),
);
}

final transactions = walletService.transactions;
final now = DateTime.now();

final monthlyTransactions = transactions.where((item) {
return item.date.year == now.year &&
item.date.month == now.month;
}).toList();

final monthlyIncome = monthlyTransactions
    .where((item) => item.type == TransactionType.income)
    .fold<double>(0, (sum, item) => sum + item.amount);

final monthlyExpense = monthlyTransactions
    .where((item) => item.type == TransactionType.expense)
    .fold<double>(0, (sum, item) => sum + item.amount);

final total = monthlyIncome + monthlyExpense;
final maxAmount = monthlyIncome > monthlyExpense
? monthlyIncome
    : monthlyExpense;
final chartMaxY = maxAmount == 0 ? 100.0 : maxAmount * 1.2;

const incomeColor = Color(0xFF4B9FE1);
const expenseColor = Color(0xFFFF8A80);

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
incomeColor,
),
),
const SizedBox(width: 12),
Expanded(
child: _summaryCard(
'Expense',
monthlyExpense,
expenseColor,
),
),
],
),

const SizedBox(height: 24),

_sectionTitle(context, 'Income vs Expense'),
const SizedBox(height: 12),

// BAR CHART
Card(
child: Padding(
padding: const EdgeInsets.fromLTRB(12, 20, 16, 20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Monthly Comparison',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 20),
 SizedBox(
height: 230,
child: BarChart(
BarChartData(
minY: 0,
maxY: chartMaxY,
alignment: BarChartAlignment.spaceEvenly,
gridData: FlGridData(
show: true,
drawVerticalLine: false,
horizontalInterval: chartMaxY / 4,
),
borderData: FlBorderData(show: false),
barTouchData: BarTouchData(
enabled: true,
touchTooltipData: BarTouchTooltipData(
getTooltipItem:
(group, groupIndex, rod, rodIndex) {
final label = group.x == 0
? 'Income'
    : 'Expense';
return BarTooltipItem(
'$label\n${money(rod.toY)}',
const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 12,
),
);
},
),
),
titlesData: FlTitlesData(
topTitles: const AxisTitles(
sideTitles: SideTitles(
showTitles: false,
),
),
rightTitles: const AxisTitles(
sideTitles: SideTitles(
showTitles: false,
),
),
leftTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 48,
interval: chartMaxY / 4,
getTitlesWidget: (value, meta) {
return SideTitleWidget(
meta: meta,
child: Text(
compactMoney(value),
style: const TextStyle(
fontSize: 10,
),
),
);
},
),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 36,
getTitlesWidget: (value, meta) {
final label = value.toInt() == 0
? 'Income'
    : value.toInt() == 1
? 'Expense'
    : '';

if (label.isEmpty) {
return const SizedBox.shrink();
}

return SideTitleWidget(
 meta: meta,
child: Text(
label,
style: const TextStyle(
fontSize: 11,
),
),
);
},
),
),
),
barGroups: [
_barGroup(0, monthlyIncome, incomeColor),
_barGroup(1, monthlyExpense, expenseColor),
],
),
),
),
],
),
),
),

const SizedBox(height: 24),

_sectionTitle(context, 'Income vs Expense'),
const SizedBox(height: 12),

// PIE CHART
Card(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const Align(
alignment: Alignment.centerLeft,
child: Text(
'Monthly Distribution',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
),
const SizedBox(height: 20),

if (total == 0)
const SizedBox(
height: 200,
child: Center(
child: Text(
'No income or expenses recorded this month.',
textAlign: TextAlign.center,
),
),
)
else ...[
SizedBox(
height: 210,
child: PieChart(
PieChartData(
sectionsSpace: 4,
centerSpaceRadius: 48,
sections: [
if (monthlyIncome > 0)
PieChartSectionData(
value: monthlyIncome,
color: incomeColor,
radius: 48,
showTitle: false,
),
if (monthlyExpense > 0)
PieChartSectionData(
value: monthlyExpense,
color: expenseColor,
radius: 48,
showTitle: false,
),
],
),
),
),

const SizedBox(height: 24),

_legendRow(
color: incomeColor,
title: 'Income',
amount: monthlyIncome,
percentage: monthlyIncome / total * 100,
),
const SizedBox(height: 16),
_legendRow(
color: expenseColor,
title: 'Expense',
amount: monthlyExpense,
percentage: monthlyExpense / total * 100,
),
],
],
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
width: 38,
borderRadius: const BorderRadius.vertical(
top: Radius.circular(6),
),
),
],
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
style: const TextStyle(fontWeight: FontWeight.w600),
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Text(
money(amount),
style: const TextStyle(fontWeight: FontWeight.w600),
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

Widget _sectionTitle(BuildContext context, String title) {
return Text(
title,
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(fontWeight: FontWeight.bold),
);
}

Widget _summaryCard(String title, double amount, Color color) {
return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(18),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: TextStyle(color: color)),
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