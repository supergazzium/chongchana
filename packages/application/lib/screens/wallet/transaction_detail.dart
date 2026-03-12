import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/models/wallet_transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatelessWidget {
  final WalletTransaction transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPositive = transaction.amount >= 0;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Transaction Detail'),
        backgroundColor: ChongjaroenColors.primaryColors,
      ),
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildStatusCard(isPositive),
              const SizedBox(height: 24),
              _buildTransactionInfo(),
              const SizedBox(height: 24),
              _buildPaymentDetails(),
              const SizedBox(height: 24),
              _buildBalanceChanges(),
              const SizedBox(height: 32),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isPositive) {
    return Container(
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transaction.getTypeLabel(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}฿${_formatAmount(transaction.amount.abs())}',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionInfo() {
    return _buildInfoSection(
      title: 'Transaction Information',
      children: [
        _buildDetailRow('Transaction ID:', transaction.id),
        _buildDivider(),
        _buildDetailRow(
          'Date/Time:',
          DateFormat('MMM d, yyyy, HH:mm').format(transaction.createdAt),
        ),
        if (transaction.referenceId != null) ...[
          _buildDivider(),
          _buildDetailRow('Reference:', transaction.referenceId!),
        ],
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return _buildInfoSection(
      title: 'Payment Details',
      children: [
        if (transaction.paymentMethod != null) ...[
          _buildDetailRow('Method:', transaction.paymentMethod!),
          _buildDivider(),
        ],
        if (transaction.description != null) ...[
          _buildDetailRow('Description:', transaction.description!),
          _buildDivider(),
        ],
        _buildDetailRow('Amount Paid:', '฿${_formatAmount(transaction.amount.abs())}'),
        _buildDivider(),
        _buildDetailRow('Processing Fee:', '฿0.00'),
        _buildDivider(),
        _buildDetailRow(
          'You Received:',
          '฿${_formatAmount(transaction.amount.abs())}',
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildBalanceChanges() {
    return _buildInfoSection(
      title: 'Balance Changes',
      children: [
        _buildDetailRow('Balance Before:', '฿${_formatAmount(transaction.balanceBefore)}'),
        _buildDivider(),
        _buildDetailRow(
          'Change:',
          '${transaction.amount >= 0 ? '+' : ''}฿${_formatAmount(transaction.amount.abs())}',
          valueColor: transaction.amount >= 0 ? Colors.green : Colors.red,
        ),
        _buildDivider(),
        _buildDetailRow(
          'Balance After:',
          '฿${_formatAmount(transaction.balanceAfter)}',
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ??
                  (isHighlight
                      ? ChongjaroenColors.secondaryColor
                      : Colors.white),
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('Need Help?'),
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
      ],
    );
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (transaction.status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (transaction.status) {
      case 'completed':
        return '✓ Completed';
      case 'pending':
        return '⏱ Pending';
      case 'failed':
        return '✗ Failed';
      default:
        return transaction.status;
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}