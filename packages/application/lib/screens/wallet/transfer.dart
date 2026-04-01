import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/transfer_success.dart';
import 'package:chongchana/screens/wallet/transaction_confirmation.dart';
import 'package:chongchana/services/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransferScreen extends StatefulWidget {
  final double availableBalance;

  const TransferScreen({
    Key? key,
    required this.availableBalance,
  }) : super(key: key);

  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  double _transferAmount = 0.0;
  bool _isValid = false;
  String? _recipientName;
  int? _recipientUserId;
  bool _isCheckingRecipient = false;
  bool _isProcessingTransfer = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() async {
    final phone = _phoneController.text;
    if (phone.length == 10) {
      // Look up recipient via backend API
      setState(() {
        _isCheckingRecipient = true;
        _recipientName = null;
        _recipientUserId = null;
      });

      try {
        final walletService = Provider.of<WalletService>(context, listen: false);
        final result = await walletService.lookupUserByPhone(phone);

        if (mounted) {
          setState(() {
            _isCheckingRecipient = false;
            if (result != null && result['found'] == true) {
              final user = result['user'];
              // Build full name from firstName and lastName
              final firstName = user['firstName'] ?? '';
              final lastName = user['lastName'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              // Fallback to username if no first/last name
              if (fullName.isEmpty) {
                _recipientName = user['username'];
              } else {
                _recipientName = fullName;
              }
              _recipientUserId = user['id'];
            } else {
              _recipientName = null;
              _recipientUserId = null;
              // Show error message
              if (result != null && result['message'] != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          });
          _validateForm();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingRecipient = false;
            _recipientName = null;
            _recipientUserId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error looking up user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _recipientName = null;
        _recipientUserId = null;
        _validateForm();
      });
    }
  }

  void _validateForm() {
    setState(() {
      final walletService = Provider.of<WalletService>(context, listen: false);
      final settings = walletService.settings;

      // Use API transfer limits (defaults)
      final minAmount = settings?.transfer.minAmount ?? 1.0;
      final maxAmount = settings?.transfer.maxAmount ?? 50000.0;

      final inputText = _amountController.text;
      if (inputText.isEmpty) {
        _transferAmount = 0.0;
        _isValid = false;
      } else {
        _transferAmount = double.tryParse(inputText) ?? 0.0;
        _isValid = _transferAmount >= minAmount &&
                   _transferAmount <= maxAmount &&
                   _transferAmount <= widget.availableBalance &&
                   _recipientName != null;
      }
    });
  }

  void _confirmTransfer() async {
    if (!_isValid) return;

    final walletService = Provider.of<WalletService>(context, listen: false);
    final settings = walletService.settings;
    final transferFee = settings?.transfer.calculateFee(_transferAmount) ?? 0.0;
    final totalAmount = settings?.transfer.calculateTotalWithFee(_transferAmount) ?? _transferAmount;

    // Build transaction details
    List<TransactionDetail> details = [
      TransactionDetail(
        label: 'Recipient',
        value: _recipientName!,
      ),
      TransactionDetail(
        label: 'Phone',
        value: _phoneController.text,
      ),
    ];

    if (_noteController.text.isNotEmpty) {
      details.add(TransactionDetail(
        label: 'Note',
        value: _noteController.text,
      ));
    }

    details.add(const TransactionDetail.divider());
    details.add(TransactionDetail(
      label: 'Transfer Amount',
      value: '฿${_formatAmount(_transferAmount)}',
    ));

    if (transferFee > 0) {
      details.add(TransactionDetail(
        label: 'Transfer Fee',
        value: '฿${_formatAmount(transferFee)}',
      ));
      details.add(const TransactionDetail.divider());
      details.add(TransactionDetail(
        label: 'Total Amount',
        value: '฿${_formatAmount(totalAmount)}',
        isHighlighted: true,
      ));
    }

    // Navigate to confirmation screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionConfirmationScreen(
          type: TransactionType.transfer,
          amount: totalAmount,
          details: details,
          onConfirm: (pin) async {
            // PIN is verified, now process the transfer
            return await _processTransfer();
          },
          onSuccess: () {
            // Transfer successful, close confirmation and navigate
            Navigator.pop(context); // Close confirmation screen
          },
        ),
      ),
    );
  }

  Future<bool> _processTransfer() async {
    if (_recipientUserId == null) {
      return false;
    }

    try {
      final walletService = Provider.of<WalletService>(context, listen: false);

      // Call backend transfer API
      final result = await walletService.transferFunds(
        receiverUserId: _recipientUserId!,
        amount: _transferAmount,
        description: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (result != null && result['success'] == true) {
        // Navigate to success screen - don't use pushReplacement
        // The onSuccess callback will handle closing the confirmation screen
        if (mounted) {
          // Wait a tiny bit for confirmation screen to close via onSuccess
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransferSuccessScreen(
                    amount: _transferAmount,
                    recipientName: _recipientName!,
                    recipientPhone: _phoneController.text,
                    note: _noteController.text,
                    transferId: result['transferId']?.toString(),
                  ),
                ),
              );
            }
          });
        }
        return true;
      } else {
        // Show error
        if (mounted) {
          final error = walletService.error ?? 'Transfer failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transfer Money',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Balance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ChongjaroenColors.primaryColors.shade400,
                            ChongjaroenColors.primaryColors.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ChongjaroenColors.primaryColors.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '฿${_formatAmount(widget.availableBalance)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recipient Section
                    const Text(
                      'Recipient',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _recipientName != null
                              ? ChongjaroenColors.primaryColors
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: const Icon(Icons.phone),
                              suffixIcon: _isCheckingRecipient
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _recipientName != null
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                          if (_recipientName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: ChongjaroenColors.primaryColors.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: ChongjaroenColors.primaryColors,
                                    child: Text(
                                      _recipientName![0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _recipientName!,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount Section
                    const Text(
                      'Amount',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isValid
                              ? ChongjaroenColors.secondaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Text(
                              '฿',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final walletService = Provider.of<WalletService>(context, listen: false);
                        final settings = walletService.settings;
                        final minAmount = settings?.transfer.minAmount ?? 1.0;
                        final maxAmount = settings?.transfer.maxAmount ?? 50000.0;

                        return Text(
                          'Min: ฿${_formatAmount(minAmount)} • Max: ฿${_formatAmount(maxAmount)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Note Section (Optional)
                    const Text(
                      'Note (Optional)',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 3,
                        maxLength: 100,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a note for this transfer...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValid ? _confirmTransfer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChongjaroenColors.secondaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isValid
                          ? 'Transfer ฿${_formatAmount(_transferAmount)}'
                          : 'Enter transfer details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}