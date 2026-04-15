import 'dart:async';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/omise_payment.dart';
import 'package:chongchana/services/inbox.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MobileBankingWaitingScreen extends StatefulWidget {
  final double amount;
  final String bankName;
  final String chargeId;

  const MobileBankingWaitingScreen({
    Key? key,
    required this.amount,
    required this.bankName,
    required this.chargeId,
  }) : super(key: key);

  @override
  _MobileBankingWaitingScreenState createState() => _MobileBankingWaitingScreenState();
}

class _MobileBankingWaitingScreenState extends State<MobileBankingWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _pollingTimer;
  int _pollCount = 0;
  static const int _maxPolls = 40; // 40 polls × 3 seconds = 2 minutes
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Register notification callback for instant success detection
    _setupNotificationListener();

    // Start polling as fallback (in case notification doesn't arrive)
    _startPaymentStatusPolling();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();

    // Unregister notification callback
    final inboxService = Provider.of<InboxService>(context, listen: false);
    inboxService.onWalletNotification = null;

    super.dispose();
  }

  void _setupNotificationListener() {
    print('[MobileBanking] 📲 Setting up notification listener');
    final inboxService = Provider.of<InboxService>(context, listen: false);

    // Register callback for wallet notifications
    inboxService.onWalletNotification = (data) {
      print('[MobileBanking] 🔔 Notification received: $data');

      // Check if this is a top-up notification for mobile banking
      final type = data['type'];
      final chargeId = data['chargeId'];
      final paymentMethod = data['paymentMethod'];

      if (type == 'wallet_topup' &&
          chargeId == widget.chargeId &&
          (paymentMethod == 'mobile_banking_scb' ||
           paymentMethod == 'mobile_banking_kbank' ||
           paymentMethod == 'mobile_banking_bbl' ||
           paymentMethod == 'mobile_banking_bay' ||
           paymentMethod == 'mobile_banking_ktb' ||
           paymentMethod?.toString().startsWith('mobile_banking_') == true)) {

        print('[MobileBanking] ✅ Mobile banking payment notification matched!');
        _stopPaymentPolling();

        if (!_dialogShown && mounted) {
          _dialogShown = true;
          _showSuccessDialog(chargeId);
        }
      }
    };
  }

  void _startPaymentStatusPolling() {
    print('[MobileBanking] 🔵 Starting payment status polling for chargeId: ${widget.chargeId}');

    // Cancel any existing timer
    _pollingTimer?.cancel();
    _pollCount = 0;

    // Start Timer.periodic for robust polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      print('[MobileBanking] ⏰ Timer tick - checking payment status');
      if (!mounted) {
        print('[MobileBanking] ⚠️ Stopping timer: widget not mounted');
        timer.cancel();
        _pollingTimer = null;
        return;
      }
      _checkPaymentStatus();
    });
  }

  void _stopPaymentPolling() {
    print('[MobileBanking] 🛑 Stopping payment polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _pollCount = 0;
  }

  Future<void> _checkPaymentStatus() async {
    _pollCount++;
    print('[MobileBanking] Poll #${_pollCount}/${_maxPolls}');

    // Safety check: stop after max attempts
    if (_pollCount >= _maxPolls) {
      print('[MobileBanking] Max polls reached, stopping');
      _stopPaymentPolling();
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Verification timed out. Please check your transaction history.');
      }
      return;
    }

    final omiseService = Provider.of<OmisePaymentService>(context, listen: false);

    try {
      final paymentData = await omiseService.verifyPayment(widget.chargeId);

      if (!mounted) return;

      if (paymentData != null && paymentData['paid'] == true) {
        print('[MobileBanking] ✓ Payment verified as paid!');

        final transactionId = paymentData['transactionId'] ?? widget.chargeId;

        _stopPaymentPolling();
        _showSuccessDialog(transactionId);
      } else {
        print('[MobileBanking] Payment not yet paid, will retry...');
      }
    } catch (e) {
      print('[MobileBanking] Error checking payment: $e');
      // Continue polling on error
    }
  }

  void _showSuccessDialog(String transactionId) {
    // Stop polling when success dialog is shown
    _stopPaymentPolling();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Your wallet has been topped up',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Payment Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '฿${NumberFormat('#,##0.00').format(widget.amount)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),

                    // Payment Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Method',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.bankName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close success dialog
                    Navigator.of(context).pop(); // Close mobile banking waiting screen
                    Navigator.of(context).pop(); // Go back to wallet overview
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChongjaroenColors.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            onPressed: () {
              Navigator.pop(context); // Close error dialog
              Navigator.pop(context); // Close waiting screen
            },
            child: const Text(
              'OK',
              style: TextStyle(color: ChongjaroenColors.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelPayment() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancel Payment?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this payment?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'No, Continue',
              style: TextStyle(
                color: ChongjaroenColors.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close confirmation
              Navigator.of(context).pop(); // Go back to top-up
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelPayment();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: _cancelPayment,
          ),
          title: const Text(
            'Complete Payment',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animated Icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: ChongjaroenColors.primaryColors.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 64,
                          color: ChongjaroenColors.primaryColors,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Status Text
                const Text(
                  'Waiting for Payment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'Please complete the payment in your ${widget.bankName} app',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Amount Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Column(
                    children: [
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '฿${_formatAmount(widget.amount)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'via ${widget.bankName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Next Steps',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInstructionStep(
                        Icons.apps,
                        'Check your ${widget.bankName} app',
                        'The app should open automatically',
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep(
                        Icons.verified_user,
                        'Review payment details',
                        'Verify the amount and recipient',
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep(
                        Icons.touch_app,
                        'Confirm the payment',
                        'Complete the authorization in your app',
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep(
                        Icons.check_circle,
                        'Return to this app',
                        'Payment will be verified automatically',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Security Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payment is secured by Omise payment gateway and your bank',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelPayment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}