import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/models/wallet.dart';
import 'package:chongchana/models/wallet_transaction.dart';
import 'package:chongchana/screens/wallet/pay.dart';
import 'package:chongchana/screens/wallet/top_up.dart';
import 'package:chongchana/screens/wallet/transaction_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletOverviewScreen extends StatefulWidget {
  const WalletOverviewScreen({Key? key}) : super(key: key);

  @override
  _WalletOverviewScreenState createState() => _WalletOverviewScreenState();
}

class _WalletOverviewScreenState extends State<WalletOverviewScreen> {
  // Mock data - replace with actual service calls
  final Wallet wallet = Wallet(
    balance: 1250.00,
    pendingBalance: 150.00,
    points: 750,
  );

  final List<WalletTransaction> recentTransactions = [
    WalletTransaction(
      id: 'TX-20250308-00124',
      type: 'top_up',
      amount: 500.00,
      balanceAfter: 1750.00,
      status: 'completed',
      paymentMethod: 'Card ****1234',
      createdAt: DateTime(2025, 3, 8, 14, 32),
    ),
    WalletTransaction(
      id: 'TX-20250307-00123',
      type: 'payment',
      amount: -285.00,
      balanceAfter: 1250.00,
      status: 'completed',
      description: 'Asoke Branch',
      createdAt: DateTime(2025, 3, 7, 18, 15),
    ),
    WalletTransaction(
      id: 'TX-20250307-00122',
      type: 'bonus',
      amount: 50.00,
      balanceAfter: 1535.00,
      status: 'completed',
      description: 'Welcome Bonus',
      createdAt: DateTime(2025, 3, 7, 12, 0),
    ),
    WalletTransaction(
      id: 'TX-20250306-00121',
      type: 'payment',
      amount: -120.00,
      balanceAfter: 1485.00,
      status: 'completed',
      description: 'Silom Branch',
      createdAt: DateTime(2025, 3, 6, 19, 30),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Wallet'),
        backgroundColor: ChongjaroenColors.primaryColors,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu
            },
          ),
        ],
      ),
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChongjaroenColors.primaryColors.shade700,
            ChongjaroenColors.primaryColors.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '💰 Your Wallet Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '฿${_formatAmount(wallet.balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available to spend',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          if (wallet.pendingBalance > 0) ...[
            const SizedBox(height: 4),
            Text(
              '(Pending: ฿${_formatAmount(wallet.pendingBalance)})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Top-up',
              icon: Icons.add_circle_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopUpScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Pay',
              icon: Icons.payment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PayScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: ChongjaroenColors.primaryColors.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChongjaroenColors.primaryColors.shade600,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recentTransactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
              child: const Text(
                'See All Transactions',
                style: TextStyle(
                  color: ChongjaroenColors.secondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final bool isPositive = transaction.amount >= 0;
    final String amountStr = '${isPositive ? '+' : ''}฿${_formatAmount(transaction.amount.abs())}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.getTypeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(transaction.createdAt)}  ${transaction.description ?? transaction.paymentMethod ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountStr,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date);
  }
}