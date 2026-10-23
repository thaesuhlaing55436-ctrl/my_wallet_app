import 'package:flutter/material.dart';

import '../services/wallet_service.dart';

class BalanceCard extends StatelessWidget {
final WalletService walletService;

const BalanceCard({
super.key,
required this.walletService,
});

String _money(double amount) {
return '${amount.toStringAsFixed(0)} MMK';
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;

return AnimatedBuilder(
animation: walletService,
builder: (context, child) {
if (walletService.isLoading) {
return const Card(
child: SizedBox(
height: 180,
child: Center(
child: CircularProgressIndicator(),
),
),
);
}

return Card(
elevation: 2,
clipBehavior: Clip.antiAlias,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
colors.primary,
colors.primary.withValues(alpha: 0.75),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Total Balance',
style: TextStyle(
color: Colors.white70,
fontSize: 14,
),
),
const SizedBox(height: 8),
FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.centerLeft,
child: Text(
_money(walletService.balance),
style: const TextStyle(
color: Colors.white,
fontSize: 30,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(height: 24),
Row(
children: [
Expanded(
child: _amountItem(
icon: Icons.arrow_downward_rounded,
title: 'Income',
amount: walletService.totalIncome,
),
),
const SizedBox(width: 12),
Expanded(
child: _amountItem(
icon: Icons.arrow_upward_rounded,
title: 'Expense',
amount: walletService.totalExpense,
),
),
],
),
],
),
),
);
},
);
}

Widget _amountItem({
required IconData icon,
required String title,
required double amount,
}) {
return Row(
children: [
Icon(
icon,
color: Colors.white70,
size: 22,
),
const SizedBox(width: 8),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
const SizedBox(height: 4),
FittedBox(
fit: BoxFit.scaleDown,
alignment: Alignment.centerLeft,
 child: Text(
_money(amount),
style: const TextStyle(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
],
),
),
],
);
}
}