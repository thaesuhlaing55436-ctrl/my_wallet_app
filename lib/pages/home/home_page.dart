import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../../models/transaction_model.dart';
import '../transactions/transactions_page.dart';

class HomePage extends StatelessWidget {
final WalletService walletService;

const HomePage({
super.key,
required this.walletService,
});

static const Color primaryBlue = Color(0xFF4B9FE1);
static const Color incomeGreen = Color(0xFF2EAD75);
static const Color expenseRed = Color(0xFFE85D75);

String _money(double amount) {
final value = amount.toStringAsFixed(0);
final formatted = value.replaceAllMapped(
RegExp(r'\B(?=(\d{3})+(?!\d))'),
(match) => ',',
);
return 'MMK $formatted';
}

@override
Widget build(BuildContext context) {
return AnimatedBuilder(
animation: walletService,
builder: (context, child) {
final transactions = walletService.transactions;

return Scaffold(
appBar: AppBar(
title: const Text(
'MyWallet',
style: TextStyle(fontWeight: FontWeight.bold),
),
actions: [
IconButton(
onPressed: () {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Notifications coming soon'),
),
);
},
icon: const Icon(Icons.notifications_none_rounded),
),
const SizedBox(width: 8),
],
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Welcome back!',
style: TextStyle(
fontSize: 25,
fontWeight: FontWeight.bold,
color: Color(0xFF202A44),
),
),
const SizedBox(height: 6),
Text(
'Here is your financial overview.',
style: TextStyle(
fontSize: 14,
color: Colors.grey.shade600,
),
),
const SizedBox(height: 24),

// Total Balance
Container(
width: double.infinity,
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
Color(0xFF4B9FE1),
Color(0xFF3478D4),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(24),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Total Balance',
style: TextStyle(
color: Colors.white70,
fontSize: 15,
),
),
const SizedBox(height: 12),
Text(
_money(walletService.balance),
style: const TextStyle(
color: Colors.white,
fontSize: 27,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 22),
const Row(
children: [
Icon(
Icons.account_balance_wallet_outlined,
color: Colors.white70,
),
SizedBox(width: 8),
Text(
'My available balance',
style: TextStyle(color: Colors.white70),
),
],
),
],
),
),
const SizedBox(height: 20),



// Income and Expense
Row(
children: [
Expanded(
child: _summaryCard(
  context: context,
title: 'Income',
amount: walletService.totalIncome,
icon: Icons.arrow_downward_rounded,
color: incomeGreen,
),
),
const SizedBox(width: 14),
Expanded(
child: _summaryCard(
  context: context,
title: 'Expense',
amount: walletService.totalExpense,
icon: Icons.arrow_upward_rounded,
color: expenseRed,
),
),
],
),
const SizedBox(height: 28),

// Recent Transactions
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Recent Transactions',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
TextButton(
onPressed: () {
// Transactions ကို အောက်ခြေ menu မှ ဖွင့်နိုင်ပါတယ်။
},
child: const Text('See All'),
),
],
),
const SizedBox(height: 8),

if (transactions.isEmpty)
Container(
width: double.infinity,
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: const Color(0xFFE8EDF4),
),
),
child: Column(
children: [
Icon(
Icons.receipt_long_outlined,
size: 42,
color: Colors.grey.shade400,
),
const SizedBox(height: 10),
const Text(
'No transactions yet',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
'Add a transaction to see it here.',
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 13,
),
),
],
),
)
else
...transactions.take(5).map((transaction) {
final isIncome =
transaction.type == TransactionType.income;
final color = isIncome ? incomeGreen : expenseRed;
final sign = isIncome ? '+' : '-';
final icon = isIncome
? Icons.arrow_downward_rounded
: Icons.arrow_upward_rounded;
return _transactionTile(
  title: transaction.title,
  subtitle: transaction.category,
  amount: '$sign ${_money(transaction.amount)}',
  icon: icon,
  color: color,
);
}),
  const SizedBox(height: 20),
],
),
),
);
},
);
}

Widget _summaryCard({
  required BuildContext context,
  required String title,
  required double amount,
  required IconData icon,
  required Color color,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionsPage(
            walletService: walletService,
            initialFilter: title,
          ),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _transactionTile({
  required String title,
  required String subtitle,
  required String amount,
  required IconData icon,
  required Color color,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8EDF4)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            amount,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
}