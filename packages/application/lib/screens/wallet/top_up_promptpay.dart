import 'dart:async';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/top_up_success.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopUpPromptPayScreen extends StatefulWidget {
  final double amount;

  const TopUpPromptPayScreen({
    Key? key,
    required this.amount,
  }) : super(key: key);

  @override
  _TopUpPromptPayScreenState createState() => _TopUpPromptPayScreenState();
}

class _TopUpPromptPayScreenState extends State<TopUpPromptPayScreen> {
  late Timer _timer;
  int _remainingSeconds = 900; // 15 minutes
  final String transactionId = 'TX-20250308-00124';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment timeout. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handlePaid() {
    _timer.cancel();

    // Simulate payment processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TopUpSuccessScreen(
            amount: widget.amount,
            transactionId: transactionId,
          ),
        ),
      );
    });
  }

  void _handleCancel() {
    _timer.cancel();
    Navigator.pop(context);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Scan to Pay ฿${_formatAmount(widget.amount)}'),
        backgroundColor: ChongjaroenColors.primaryColors,
      ),
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Scan this QR code with your banking',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'app to complete payment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildQRCode(),
                    const SizedBox(height: 32),
                    _buildPaymentDetails(),
                    const SizedBox(height: 24),
                    _buildTimer(),
                    const SizedBox(height: 24),
                    _buildInstructions(),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // QR Code placeholder
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_2,
                size: 200,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Amount:', '฿${_formatAmount(widget.amount)}'),
          const SizedBox(height: 8),
          _buildDetailRow('Ref:', transactionId),
        ],
      ),
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          'Time remaining:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(_remainingSeconds),
          style: TextStyle(
            color: _remainingSeconds < 60 ? Colors.red : ChongjaroenColors.secondaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChongjaroenColors.primaryColors.shade600,
        ),
      ),
      child: Text(
        'After payment, balance will update automatically within seconds',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _handlePaid,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChongjaroenColors.secondaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "I've Paid",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}