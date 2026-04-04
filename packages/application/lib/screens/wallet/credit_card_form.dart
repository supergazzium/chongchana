import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/omise_payment.dart';
import 'package:chongchana/services/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditCardFormScreen extends StatefulWidget {
  final double amount;
  final Function(String tokenId) onPaymentSuccess;

  const CreditCardFormScreen({
    Key? key,
    required this.amount,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  _CreditCardFormScreenState createState() => _CreditCardFormScreenState();
}

class _CreditCardFormScreenState extends State<CreditCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  String? _pendingChargeId;
  bool _isPollingPayment = false;
  int _pollCount = 0;
  static const int _maxPolls = 40; // 40 polls × 3 seconds = 2 minutes

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  String _formatExpiryDate(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final omiseService = Provider.of<OmisePaymentService>(context, listen: false);

    try {
      // Initialize Omise if not already initialized
      if (!omiseService.isInitialized) {
        await omiseService.initialize();
      }

      // Parse expiry date
      final expiryParts = _expiryDateController.text.split('/');
      final month = expiryParts[0].trim();
      final year = '20${expiryParts[1].trim()}';

      // Create token
      final tokenId = await omiseService.createToken(
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        cardHolderName: _cardHolderController.text,
        expirationMonth: month,
        expirationYear: year,
        securityCode: _cvvController.text,
      );

      if (tokenId != null) {
        // Process payment with token
        final result = await omiseService.processTopUpPayment(
          amount: widget.amount,
          currency: 'THB',
          tokenId: tokenId,
          metadata: {
            'type': 'wallet_topup',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (result != null && result['success'] == true) {
          if (!mounted) return;

          // Check if payment is completed (has transactionId) or pending
          if (result['paid'] == true && result['transactionId'] != null) {
            // Payment completed immediately (cards without 3D Secure)
            Navigator.pop(context); // Close credit card form
            // Call callback with delay to ensure navigation completes
            Future.delayed(const Duration(milliseconds: 100), () {
              widget.onPaymentSuccess(result['transactionId']);
            });
          } else if (result['authorizeUri'] != null &&
                     result['authorizeUri'] != 'none' &&
                     result['authorizeUri'].toString().isNotEmpty &&
                     result['authorizeUri'].toString().startsWith('http')) {
            // Payment requires 3D Secure authentication
            // DON'T pop yet - keep credit card form open during 3DS flow
            _handle3DSecureAuth(result['authorizeUri'], result['chargeId']);
          } else {
            // Payment is pending (awaiting bank approval without 3D Secure)
            // DON'T pop yet - keep credit card form open during polling
            _showPendingDialog(result['chargeId']);
          }
        } else {
          if (!mounted) return;
          _showErrorDialog('Payment failed. Please try again.');
        }
      } else {
        if (!mounted) return;
        _showErrorDialog(omiseService.lastError ?? 'Failed to process card information.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: ChongjaroenColors.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog(String chargeId) {
    // Start polling for payment status
    _pendingChargeId = chargeId;
    _startPaymentPolling();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Payment Processing'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your payment is being processed by your bank.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'This usually takes a few seconds to a few minutes. We\'ll check automatically.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Charge ID: ${chargeId.substring(0, 20)}...',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isPollingPayment = false;
              _pendingChargeId = null;
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _checkPendingPaymentStatus(chargeId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChongjaroenColors.secondaryColor,
            ),
            child: const Text(
              'Check Status',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _startPaymentPolling() {
    _isPollingPayment = true;
    _pollPaymentStatus();
  }

  Future<void> _pollPaymentStatus() async {
    if (!_isPollingPayment || _pendingChargeId == null) return;

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted || !_isPollingPayment || _pendingChargeId == null) return;

    await _checkPendingPaymentStatus(_pendingChargeId!);

    // Continue polling if still pending
    if (_isPollingPayment && _pendingChargeId != null) {
      _pollPaymentStatus();
    }
  }

  Future<void> _checkPendingPaymentStatus(String chargeId) async {
    try {
      // Instead of checking payment status endpoint (DNS issues),
      // check wallet transactions for the completed transaction
      final walletService = Provider.of<WalletService>(context, listen: false);
      await walletService.getTransactions(limit: 5);

      if (!mounted) return;

      final transactions = walletService.transactions;

      // Look for a recent transaction matching our payment amount
      // Created within last 2 minutes
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 2));

      final matchingTransaction = transactions.cast<dynamic>().firstWhere(
        (tx) =>
          tx.type == 'top_up' &&
          tx.amount == widget.amount &&
          tx.paymentMethod == 'credit_card' &&
          DateTime.parse(tx.createdAt).isAfter(cutoffTime),
        orElse: () => null,
      );

      if (matchingTransaction != null) {
        // Payment successful - transaction found!
        print('[CreditCard] Found matching transaction: ${matchingTransaction.id}');

        _isPollingPayment = false;
        _pendingChargeId = null;

        // Close pending dialog
        Navigator.pop(context);

        // Close the credit card form
        Navigator.pop(context);

        // Call success callback AFTER all navigation is complete
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onPaymentSuccess(matchingTransaction.id);
        });
      } else {
        // No matching transaction yet - keep polling
        print('[CreditCard] No matching transaction found yet, will retry...');
      }
    } catch (e) {
      // Continue polling on error - don't let network issues stop us
      print('[CreditCard] Error checking transactions: $e');
    }
  }

  Future<void> _handle3DSecureAuth(String authorizeUri, String chargeId) async {
    // Show dialog with instructions
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Bank Verification Required',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your bank requires additional verification (3D Secure).',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be redirected to your bank\'s website to verify this payment. This usually involves entering an OTP (One-Time Password).',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'After verifying, return to the app to complete your top-up.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChongjaroenColors.secondaryColor,
            ),
            child: const Text('Verify Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (proceed == true) {
      // Open authorize_uri in browser
      final uri = Uri.parse(authorizeUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show dialog to check payment status after user returns
        if (mounted) {
          _showCheckPaymentDialog(chargeId);
        }
      } else {
        if (mounted) {
          _showErrorDialog('Unable to open bank verification page');
        }
      }
    }
  }

  void _showCheckPaymentDialog(String chargeId) {
    // Start automatic polling instead of asking user
    _pendingChargeId = chargeId;
    _startPaymentPolling();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.sync, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Verifying Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please wait while we verify your payment...',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.black54),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This usually takes a few seconds. We\'re checking automatically.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isPollingPayment = false;
              _pendingChargeId = null;
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailedDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close failed dialog
              Navigator.of(context).pop(); // Close credit card form
            },
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close failed dialog - stay on credit card form to retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChongjaroenColors.secondaryColor,
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Credit/Debit Card'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountDisplay(),
                const SizedBox(height: 32),
                _buildCardPreview(),
                const SizedBox(height: 32),
                _buildCardNumberField(),
                const SizedBox(height: 20),
                _buildCardHolderField(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildExpiryDateField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCVVField()),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSecurityInfo(),
                const SizedBox(height: 32),
                _buildPayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChongjaroenColors.primaryColors.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Amount to pay:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            '฿${NumberFormat('#,##0.00').format(widget.amount)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ChongjaroenColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    final cardNumber = _cardNumberController.text.isEmpty
        ? '**** **** **** ****'
        : _cardNumberController.text.padRight(19, '*');
    final cardHolder = _cardHolderController.text.isEmpty
        ? 'CARDHOLDER NAME'
        : _cardHolderController.text.toUpperCase();
    final expiry = _expiryDateController.text.isEmpty
        ? 'MM/YY'
        : _expiryDateController.text;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChongjaroenColors.primaryColors.shade400,
            ChongjaroenColors.primaryColors.shade700,
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 36),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VISA/MASTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              cardNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cardHolder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  expiry,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      keyboardType: TextInputType.number,
      maxLength: 19,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
      ],
      onChanged: (value) {
        setState(() {
          _cardNumberController.value = TextEditingValue(
            text: _formatCardNumber(value),
            selection: TextSelection.collapsed(
              offset: _formatCardNumber(value).length,
            ),
          );
        });
      },
      decoration: InputDecoration(
        labelText: 'Card Number',
        hintText: '1234 5678 9012 3456',
        prefixIcon: const Icon(Icons.credit_card),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter card number';
        }
        if (value.replaceAll(' ', '').length < 13) {
          return 'Invalid card number';
        }
        return null;
      },
    );
  }

  Widget _buildCardHolderField() {
    return TextFormField(
      controller: _cardHolderController,
      textCapitalization: TextCapitalization.characters,
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Cardholder Name',
        hintText: 'JOHN DOE',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter cardholder name';
        }
        return null;
      },
    );
  }

  Widget _buildExpiryDateField() {
    return TextFormField(
      controller: _expiryDateController,
      keyboardType: TextInputType.number,
      maxLength: 5,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (value) {
        setState(() {
          _expiryDateController.value = TextEditingValue(
            text: _formatExpiryDate(value),
            selection: TextSelection.collapsed(
              offset: _formatExpiryDate(value).length,
            ),
          );
        });
      },
      decoration: InputDecoration(
        labelText: 'Expiry Date',
        hintText: 'MM/YY',
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (!value.contains('/') || value.length < 5) {
          return 'Invalid';
        }
        return null;
      },
    );
  }

  Widget _buildCVVField() {
    return TextFormField(
      controller: _cvvController,
      keyboardType: TextInputType.number,
      maxLength: 4,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: 'CVV',
        hintText: '123',
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (value.length < 3) {
          return 'Invalid';
        }
        return null;
      },
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is secured by Omise. We do not store your card information.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChongjaroenColors.secondaryColor,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Pay ฿${NumberFormat('#,##0.00').format(widget.amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}