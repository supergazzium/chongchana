import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/models/wallet_transaction.dart';
import 'package:chongchana/screens/wallet/transaction_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<WalletTransaction> transactions = [];
  List<WalletTransaction> filteredTransactions = [];
  bool isLoading = false;

  // Filter options
  Set<String> selectedTypes = {'all'};
  String selectedDateRange = 'last_7';
  double? minAmount;
  double? maxAmount;
  Set<String> selectedStatuses = {'completed', 'pending'};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    // Mock data - replace with actual API call
    transactions = [
      WalletTransaction(
        id: 'TX-20250308-00124',
        type: 'top_up',
        amount: 500.00,
        balanceAfter: 1750.00,
        balanceBefore: 1250.00,
        status: 'completed',
        paymentMethod: 'PromptPay',
        createdAt: DateTime(2025, 3, 8, 14, 32),
      ),
      WalletTransaction(
        id: 'TX-20250307-00123',
        type: 'payment',
        amount: -285.00,
        balanceAfter: 1250.00,
        balanceBefore: 1535.00,
        status: 'completed',
        description: 'Asoke Branch',
        referenceId: 'Order #A-00456',
        createdAt: DateTime(2025, 3, 7, 18, 15),
      ),
      WalletTransaction(
        id: 'TX-20250307-00122',
        type: 'bonus',
        amount: 50.00,
        balanceAfter: 1535.00,
        balanceBefore: 1485.00,
        status: 'completed',
        description: 'Welcome Bonus',
        referenceId: 'BONUS-2025-001',
        createdAt: DateTime(2025, 3, 7, 12, 0),
      ),
      WalletTransaction(
        id: 'TX-20250306-00121',
        type: 'payment',
        amount: -120.00,
        balanceAfter: 1485.00,
        balanceBefore: 1605.00,
        status: 'completed',
        description: 'Silom Branch',
        referenceId: 'Order #S-00789',
        createdAt: DateTime(2025, 3, 6, 19, 30),
      ),
      WalletTransaction(
        id: 'TX-20250305-00098',
        type: 'top_up',
        amount: 1000.00,
        balanceAfter: 1605.00,
        balanceBefore: 605.00,
        status: 'completed',
        paymentMethod: 'Card ****1234',
        createdAt: DateTime(2025, 3, 5, 16, 20),
      ),
      WalletTransaction(
        id: 'TX-20250305-00097',
        type: 'refund',
        amount: 95.00,
        balanceAfter: 605.00,
        balanceBefore: 510.00,
        status: 'completed',
        description: 'Order Cancelled',
        referenceId: 'Ref: Order #A-00432',
        createdAt: DateTime(2025, 3, 5, 10, 15),
      ),
    ];

    filteredTransactions = List.from(transactions);
  }

  void _applyFilters() {
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        // Type filter
        if (!selectedTypes.contains('all') &&
            !selectedTypes.contains(transaction.type)) {
          return false;
        }

        // Status filter
        if (!selectedStatuses.contains(transaction.status)) {
          return false;
        }

        // Amount filter
        if (minAmount != null && transaction.amount.abs() < minAmount!) {
          return false;
        }
        if (maxAmount != null && transaction.amount.abs() > maxAmount!) {
          return false;
        }

        // Date range filter
        final now = DateTime.now();
        switch (selectedDateRange) {
          case 'last_7':
            return transaction.createdAt.isAfter(now.subtract(const Duration(days: 7)));
          case 'last_30':
            return transaction.createdAt.isAfter(now.subtract(const Duration(days: 30)));
          case 'last_90':
            return transaction.createdAt.isAfter(now.subtract(const Duration(days: 90)));
          case 'all':
          default:
            return true;
        }
      }).toList();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Transaction History'),
        backgroundColor: ChongjaroenColors.primaryColors,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChongjaroenColors.primaryColors.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export coming soon'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _getGroupedTransactions().length,
      itemBuilder: (context, index) {
        final group = _getGroupedTransactions()[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(group['date'] as DateTime),
            const SizedBox(height: 8),
            ...(group['transactions'] as List<WalletTransaction>)
                .map((transaction) => _buildTransactionItem(transaction))
                .toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getGroupedTransactions() {
    final Map<String, List<WalletTransaction>> grouped = {};

    for (var transaction in filteredTransactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    return grouped.entries.map((entry) {
      return {
        'date': DateTime.parse(entry.key),
        'transactions': entry.value,
      };
    }).toList()
      ..sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('MMMM d, yyyy').format(date),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final bool isPositive = transaction.amount >= 0;
    final String amountStr =
        '${isPositive ? '+' : ''}฿${_formatAmount(transaction.amount.abs())}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChongjaroenColors.primaryColors.shade800,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.getTypeLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat('HH:mm').format(transaction.createdAt)}  ${transaction.description ?? transaction.paymentMethod ?? ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.id,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Balance: ฿${_formatAmount(transaction.balanceAfter)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaction Type:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('All', 'all', setModalState),
                    _buildFilterChip('Top-up', 'top_up', setModalState),
                    _buildFilterChip('Payment', 'payment', setModalState),
                    _buildFilterChip('Refund', 'refund', setModalState),
                    _buildFilterChip('Bonus', 'bonus', setModalState),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Date Range:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDateRangeOptions(setModalState),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            selectedTypes = {'all'};
                            selectedDateRange = 'last_7';
                            selectedStatuses = {'completed', 'pending'};
                          });
                          setState(() {
                            _applyFilters();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChongjaroenColors.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Apply Filters'),
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

  Widget _buildFilterChip(String label, String value, StateSetter setModalState) {
    final isSelected = selectedTypes.contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          if (value == 'all') {
            selectedTypes = {'all'};
          } else {
            selectedTypes.remove('all');
            if (selected) {
              selectedTypes.add(value);
            } else {
              selectedTypes.remove(value);
            }
            if (selectedTypes.isEmpty) {
              selectedTypes = {'all'};
            }
          }
        });
      },
      backgroundColor: ChongjaroenColors.primaryColors.shade800,
      selectedColor: ChongjaroenColors.secondaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
      ),
    );
  }

  Widget _buildDateRangeOptions(StateSetter setModalState) {
    return Column(
      children: [
        _buildRadioOption('Last 7 days', 'last_7', setModalState),
        _buildRadioOption('Last 30 days', 'last_30', setModalState),
        _buildRadioOption('Last 90 days', 'last_90', setModalState),
        _buildRadioOption('All time', 'all', setModalState),
      ],
    );
  }

  Widget _buildRadioOption(String label, String value, StateSetter setModalState) {
    return RadioListTile<String>(
      title: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      groupValue: selectedDateRange,
      onChanged: (newValue) {
        setModalState(() {
          selectedDateRange = newValue!;
        });
      },
      activeColor: ChongjaroenColors.secondaryColor,
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}
