import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/omise_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
            // Payment completed immediately (rare for credit cards)
            widget.onPaymentSuccess(result['transactionId']);
            Navigator.pop(context);
          } else {
            // Payment is pending (typical for credit cards - awaiting bank approval)
            Navigator.pop(context);
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
    showDialog(
      context: context,
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
              'This usually takes a few minutes. You will receive a notification once the payment is confirmed.',
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