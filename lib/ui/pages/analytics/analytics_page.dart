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

String money(double amount) =>
'${amount.toStringAsFixed(0)} MMK';

String compactMoney(double amount) {
if (amount >= 1000000) {
return '${(amount / 1000000).toStringAsFixed(1)}M';
}
if (amount >= 1000) {
return '${(amount / 1000).toStringAsFixed(1)}k';
}
return amount.toStringAsFixed(0);
}

String _monthName(int month) {
const months = [
'January', 'February', 'March', 'April',
'May', 'June', 'July', 'August',
'September', 'October', 'November', 'December',
];
return months[month - 1];
}

String _dateLabel(DateTime date) =>
'${date.day} ${_monthName(date.month)} ${date.year}';

List<_PeriodOption> _buildOptions() {
final now = DateTime.now();
final options = <_PeriodOption>[];

if (_period == 'Weekly') {
final today = DateTime(now.year, now.month, now.day);
final monday = today.subtract(
Duration(days: today.weekday - 1),
);

for (int i = 0; i < 12; i++) {
final start = monday.subtract(Duration(days: 7 * i));
final end = start.add(const Duration(days: 7));
final lastDay = end.subtract(const Duration(days: 1));

options.add(_PeriodOption(
key: start.toIso8601String(),
label: i == 0
? 'This Week'
    : '${_dateLabel(start)} - ${_dateLabel(lastDay)}',
start: start,
end: end,
));
}
} else if (_period == 'Monthly') {
  for (int month = 1; month <= 12; month++) {
    final start = DateTime(now.year, month, 1);
    final end = DateTime(now.year, month + 1, 1);

    options.add(_PeriodOption(
      key: '${start.year}-$month',
      label: month == now.month
          ? 'This Month (${_monthName(month)})'
          : '${_monthName(month)} ${now.year}',
      start: start,
      end: end,
    ));
  }
} else {
for (int i = 0; i < 6; i++) {
final year = now.year - i;
options.add(_PeriodOption(
key: '$year',
label: i == 0 ? 'This Year ($year)' : '$year',
start: DateTime(year, 1, 1),
end: DateTime(year + 1, 1, 1),
));
}
}

return options;
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
body: Center(child: CircularProgressIndicator()),
);
}

final allTransactions = widget.walletService.transactions;

final filteredTransactions = allTransactions.where((item) {
return !item.date.isBefore(selectedOption.start) &&
item.date.isBefore(selectedOption.end);
}).toList();

final income = filteredTransactions
    .where((item) => item.type == TransactionType.income)
    .fold<double>(0, (sum, item) => sum + item.amount);
final expense = filteredTransactions
    .where((item) => item.type == TransactionType.expense)
    .fold<double>(0, (sum, item) => sum + item.amount);
final categoryTotals = <String, double>{};

for (final item in filteredTransactions) {
  // Expense only
  if (item.type != TransactionType.expense) {
    continue;
  }

  final category = item.category.trim().isEmpty
      ? 'Untitled'
      : item.category.trim();

  categoryTotals[category] =
      (categoryTotals[category] ?? 0) + item.amount;
}

final categories = categoryTotals.entries.toList()
  ..sort((a, b) => b.value.compareTo(a.value));

final totalCategoryExpense = categories.fold<double>(
  0,
      (sum, item) => sum + item.value,
);

final maxAmount = categories.isEmpty
    ? 100.0
    : categories.first.value * 1.2;

final chartMaxY = maxAmount <= 0 ? 100.0 : maxAmount;

const incomeColor = Color(0xFF4B9FE1);
const expenseColor = Color(0xFFFF8A80);

const chartColors = [
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

Color categoryColor(int index) =>
chartColors[index % chartColors.length];

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

// PERIOD DROPDOWN
DropdownButtonFormField<String>(
value: _period,
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
_selectedKey = '';
});
},
),

const SizedBox(height: 12),

// DATE DROPDOWN
DropdownButtonFormField<String>(
key: ValueKey(_period),
value: selectedOption.key,
isExpanded: true,
decoration: InputDecoration(
labelText: 'Select $_period',
prefixIcon: const Icon(Icons.calendar_month),
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
setState(() => _selectedKey = value);
},
),

const SizedBox(height: 20),

Text(
selectedOption.label,
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(fontWeight: FontWeight.bold),
),

const SizedBox(height: 12),

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

const SizedBox(height: 24),

_sectionTitle(context, 'Expenses by Category'),
const SizedBox(height: 12),

Card(
child: Padding(
padding: const EdgeInsets.fromLTRB(8, 20, 16, 20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Padding(
padding: EdgeInsets.only(left: 8),
child: Text(
'Spending by Item',
style: TextStyle(fontWeight: FontWeight.w600),
),
),
const SizedBox(height: 20),

if (categories.isEmpty)
const SizedBox(
height: 160,
child: Center(
child: Text('No expense items for this period.'),
),
)
else
SizedBox(
height: 250,
child: BarChart(
BarChartData(
minY: 0,
maxY: chartMaxY,
alignment: BarChartAlignment.spaceAround,
gridData: FlGridData(
show: true,
drawVerticalLine: false,
horizontalInterval: chartMaxY / 4,
),
borderData: FlBorderData(show: false),
barTouchData: BarTouchData(
touchTooltipData: BarTouchTooltipData(
getTooltipItem: (
group,
groupIndex,
rod,
rodIndex,
) {
if (group.x < 0 ||
group.x >= categories.length) {
return null;
}
return BarTooltipItem(
  '${categories[group.x].key.split('::').last}\n'
'${money(rod.toY)}',
const TextStyle(
color: Colors.white,
 fontWeight: FontWeight.bold,
),
);
},
),
),
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
reservedSize: 48,
interval: chartMaxY / 4,
getTitlesWidget: (value, meta) =>
SideTitleWidget(
meta: meta,
child: Text(
compactMoney(value),
style: const TextStyle(fontSize: 10),
),
),
),
),
bottomTitles: AxisTitles(
sideTitles: SideTitles(
showTitles: true,
reservedSize: 40,
  getTitlesWidget: (value, meta) {
    final index = value.toInt();

    if (index < 0 || index >= categories.length) {
      return const SizedBox.shrink();
    }

    final name = categories[index].key.split('::').last;

    return SideTitleWidget(
      meta: meta,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          name,
          style: const TextStyle(fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  },
),
),
),
barGroups: List.generate(categories.length, (i) {
return BarChartGroupData(
x: i,
barRods: [
BarChartRodData(
toY: categories[i].value,
color: categoryColor(i),
width: categories.length > 6 ? 14 : 24,
borderRadius: const BorderRadius.vertical(
top: Radius.circular(5),
),
),
],
);
}),
),
),
),
],
),
),
),

const SizedBox(height: 24),

_sectionTitle(context, 'Expense Distribution'),
const SizedBox(height: 12),
Card(
child: Padding(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const Align(
alignment: Alignment.centerLeft,
child: Text(
'Spending Breakdown',
style: TextStyle(fontWeight: FontWeight.w600),
),
),
const SizedBox(height: 20),

if (categories.isEmpty || totalCategoryExpense == 0)
const SizedBox(
height: 180,
child: Center(
child: Text('No expense items for this period.'),
),
)
else ...[
SizedBox(
height: 220,
child: PieChart(
PieChartData(
sectionsSpace: 3,
centerSpaceRadius: 42,
sections: List.generate(categories.length, (i) {
final item = categories[i];
final percentage =
item.value / totalCategoryExpense * 100;

return PieChartSectionData(
  value: item.value,
  color: categoryColor(i),
  radius: 48,
  showTitle: false,

);
}),
),
),
),

const SizedBox(height: 24),

...List.generate(categories.length, (i) {
final item = categories[i];
return Padding(
padding: const EdgeInsets.only(bottom: 14),
child: _legendRow(
color: categoryColor(i),
title: item.key,
amount: item.value,
percentage:
item.value / totalCategoryExpense * 100,
),
);
}),
],
],
),
),
),


],
),
);
},
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
style: const TextStyle(color: Colors.grey, fontSize: 12),
),
],
),
],
);
}
}