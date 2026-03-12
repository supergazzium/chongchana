import 'package:chongchana/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopUpSuccessScreen extends StatelessWidget {
  final double amount;
  final String transactionId;

  const TopUpSuccessScreen({
    Key? key,
    required this.amount,
    required this.transactionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final double newBalance = 1750.00; // Mock new balance

    return Scaffold(
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              const Text(
                '✓ Top-up Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '฿${_formatAmount(amount)} added to wallet',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildDetailRow('Transaction ID:', transactionId),
              const SizedBox(height: 12),
              _buildDetailRow('Payment Method:', 'PromptPay'),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Date/Time:',
                DateFormat('MMM d, yyyy, HH:mm').format(now),
              ),
              const SizedBox(height: 16),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildNewBalance(newBalance),
              const Spacer(),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 60,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildNewBalance(double newBalance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'New Balance:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '฿${_formatAmount(newBalance)}',
            style: const TextStyle(
              color: ChongjaroenColors.secondaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Download receipt
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt download coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Receipt'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: View transaction
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction detail coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('View Transaction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate back to wallet overview (pop all top-up screens)
              Navigator.popUntil(
                context,
                (route) => route.isFirst || route.settings.name == '/wallet',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChongjaroenColors.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}