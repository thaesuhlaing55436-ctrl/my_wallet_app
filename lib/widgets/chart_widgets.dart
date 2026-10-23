import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

class ChartWidget extends StatelessWidget {
final List<TransactionModel> transactions;

const ChartWidget({
super.key,
required this.transactions,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);

final now = DateTime.now();

final monthlyTransactions = transactions.where((transaction) {
return transaction.date.year == now.year &&
transaction.date.month == now.month;
}).toList();

double getTotal(TransactionType type, int day) {
return monthlyTransactions
    .where((transaction) =>
transaction.type == type &&
transaction.date.day == day)
    .fold(0.0, (sum, transaction) => sum + transaction.amount);
}

final days = List.generate(7, (index) {
return now.day - 6 + index;
}).where((day) => day > 0).toList();

final incomeSpots = <FlSpot>[];
final expenseSpots = <FlSpot>[];

for (var i = 0; i < days.length; i++) {
incomeSpots.add(
FlSpot(
i.toDouble(),
getTotal(TransactionType.income, days[i]),
),
);

expenseSpots.add(
FlSpot(
i.toDouble(),
getTotal(TransactionType.expense, days[i]),
),
);
}

final maxAmount = [
...incomeSpots.map((spot) => spot.y),
...expenseSpots.map((spot) => spot.y),
].fold<double>(0, (max, amount) => amount > max ? amount : max);

final chartMaxY = maxAmount == 0 ? 100.0 : maxAmount * 1.2;

return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: theme.dividerColor.withValues(alpha: 0.3),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Income & Expense',
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
Text(
'Daily activity this month',
style: theme.textTheme.bodySmall?.copyWith(
color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
),
),
const SizedBox(height: 20),
Row(
children: [
_LegendItem(
color: const Color(0xFF4B9FE1),
label: 'Income',
),
const SizedBox(width: 20),
_LegendItem(
color: const Color(0xFFFF8A80),
label: 'Expense',
),
],
),
const SizedBox(height: 20),
SizedBox(
height: 220,
child: LineChart(
LineChartData(
minY: 0,
maxY: chartMaxY,
gridData: FlGridData(
show: true,
drawVerticalLine: false,
),
borderData: FlBorderData(show: false),
titlesData: FlTitlesData(
topTitles: const AxisTitles(
sideTitles: SideTitles(showTitles: false),
),
rightTitles: const AxisTitles(
sideTitles: SideTitles(showTitles: false),
),
leftTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 42,
getTitlesWidget: (value, meta) {
return Text(
 value >= 1000
? '${(value / 1000).toStringAsFixed(0)}k'
    : value.toStringAsFixed(0),
style: theme.textTheme.bodySmall,
);
},
),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
interval: 1,
getTitlesWidget: (value, meta) {
final index = value.toInt();

if (index < 0 || index >= days.length) {
return const SizedBox.shrink();
}

return Padding(
padding: const EdgeInsets.only(top: 8),
child: Text(
'${days[index]}',
style: theme.textTheme.bodySmall,
),
);
},
),
),
),
lineBarsData: [
LineChartBarData(
spots: incomeSpots,
isCurved: true,
color: const Color(0xFF4B9FE1),
barWidth: 3,
dotData: const FlDotData(show: false),
belowBarData: BarAreaData(
show: true,
color: const Color(0xFF4B9FE1)
    .withValues(alpha: 0.10),
),
),
LineChartBarData(
spots: expenseSpots,
isCurved: true,
color: const Color(0xFFFF8A80),
barWidth: 3,
dotData: const FlDotData(show: false),
),
],
),
),
),
],
),
);
}
}

class _LegendItem extends StatelessWidget {
final Color color;
final String label;

const _LegendItem({
required this.color,
required this.label,
});

@override
Widget build(BuildContext context) {
return Row(
children: [
Container(
width: 10,
height: 10,
decoration: BoxDecoration(
color: color,
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
Text(label),
],
);
}
}