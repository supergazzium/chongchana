import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/omise_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';

class PromptPayQRScreen extends StatefulWidget {
  final double amount;

  const PromptPayQRScreen({
    Key? key,
    required this.amount,
  }) : super(key: key);

  @override
  _PromptPayQRScreenState createState() => _PromptPayQRScreenState();
}

class _PromptPayQRScreenState extends State<PromptPayQRScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isLoading = true;
  String? _qrData;
  String? _chargeId;
  DateTime? _expiresAt;
  String? _errorMessage;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Delay API calls to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateQRCode();
      // Polling will be started AFTER QR code is generated (in _generateQRCode)
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    final omiseService = Provider.of<OmisePaymentService>(context, listen: false);

    try {
      print('[PromptPay] Requesting QR code for amount: ${widget.amount}');

      final result = await omiseService.createPromptPaySource(
        amount: widget.amount,
        currency: 'THB',
      );

      print('[PromptPay] Response received: $result');

      if (result != null && result['success'] == true) {
        setState(() {
          // According to Omise documentation:
          // scannable_code structure: { type: "qr", image: { download_uri: "...", ... } }
          final scannableCode = result['scannableCode'];

          print('[PromptPay] scannableCode: $scannableCode');
          print('[PromptPay] scannableCode type: ${scannableCode.runtimeType}');

          if (scannableCode != null && scannableCode is Map) {
            // Get the download URI for the QR code image
            final imageData = scannableCode['image'];
            print('[PromptPay] imageData: $imageData');

            if (imageData != null && imageData is Map) {
              // Use download_uri as the QR data (it's a URL to the QR code image)
              _qrData = imageData['download_uri'] as String?;
              print('[PromptPay] QR data extracted: $_qrData');
            } else {
              print('[PromptPay] ERROR: imageData is null or not a Map');
            }
          } else {
            print('[PromptPay] ERROR: scannableCode is null or not a Map');
          }

          _chargeId = result['chargeId'];
          print('[PromptPay] Charge ID: $_chargeId');

          // Set expiration: Use backend's expiresAt if available, otherwise 15 minutes from now
          if (result['expiresAt'] != null) {
            try {
              _expiresAt = DateTime.parse(result['expiresAt']);
              print('[PromptPay] Expires at (from backend): $_expiresAt');
            } catch (e) {
              print('[PromptPay] Failed to parse expiresAt: $e');
              _expiresAt = DateTime.now().add(const Duration(minutes: 15));
              print('[PromptPay] Expires at (default 15 min): $_expiresAt');
            }
          } else {
            _expiresAt = DateTime.now().add(const Duration(minutes: 15));
            print('[PromptPay] Expires at (default 15 min): $_expiresAt');
          }

          _isLoading = false;

          // Start countdown timer that updates every second
          _startCountdownTimer();
        });

        // Start payment status polling AFTER chargeId is set
        print('[PromptPay] Starting payment verification polling...');
        _startPaymentStatusPolling();
      } else {
        print('[PromptPay] ERROR: Result is null or success is false');
        setState(() {
          _errorMessage = omiseService.lastError ?? 'Failed to generate QR code';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('[PromptPay] EXCEPTION: $e');
      print('[PromptPay] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to generate QR code: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    // Cancel existing timer if any
    _countdownTimer?.cancel();

    // Start timer that updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Check if expired
        if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
          _countdownTimer?.cancel();
          _errorMessage = 'QR code has expired. Please try again.';
        }
      });
    });
  }

  void _startPaymentStatusPolling() {
    print('[PromptPay] Starting payment status polling for charge: $_chargeId');
    // Poll payment status every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      print('[PromptPay] Polling timer triggered - mounted: $mounted, chargeId: $_chargeId');
      if (mounted && _chargeId != null) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_chargeId == null) {
      print('[PromptPay] _checkPaymentStatus: chargeId is null, aborting');
      return;
    }

    print('[PromptPay] Checking payment status for charge: $_chargeId');
    final omiseService = Provider.of<OmisePaymentService>(context, listen: false);

    try {
      final paymentData = await omiseService.verifyPayment(_chargeId!);
      print('[PromptPay] Payment verification result: $paymentData');

      if (paymentData != null && paymentData['paid'] == true) {
        print('[PromptPay] Payment successful! Showing success dialog');
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        print('[PromptPay] Payment not yet completed. Checking expiration...');
        // Continue polling if not expired
        if (_expiresAt != null && DateTime.now().isBefore(_expiresAt!)) {
          print('[PromptPay] Not expired. Continuing polling...');
          _startPaymentStatusPolling();
        } else if (_expiresAt != null) {
          print('[PromptPay] QR code expired');
          setState(() {
            _errorMessage = 'QR code has expired. Please try again.';
          });
        }
      }
    } catch (e) {
      print('[PromptPay] Error checking payment status: $e');
      // Continue polling on error
      _startPaymentStatusPolling();
    }
  }

  Future<void> _downloadQRCode() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Saving QR code...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Capture the QR code as high-resolution image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High-res: 660x660px
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery using Gal (handles permissions automatically)
      // Gal will request permission if needed, with system dialog
      await Gal.putImageBytes(
        pngBytes,
        album: 'PromptPay',  // Creates album if doesn't exist
      );

      // Success!
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('QR code saved to gallery successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } on GalException catch (e) {
      // Handle Gal-specific errors (e.g., permission denied)
      ScaffoldMessenger.of(context).clearSnackBars();

      String errorMessage = 'Failed to save QR code';
      if (e.type == GalExceptionType.accessDenied) {
        errorMessage = 'Storage permission is required to save the QR code';
      } else if (e.type == GalExceptionType.notEnoughSpace) {
        errorMessage = 'Not enough storage space to save the QR code';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(errorMessage),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Handle any other unexpected errors
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Error: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    // Cancel timer when payment is successful
    _countdownTimer?.cancel();

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
              // Success Icon with Animation
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
                          '฿${_formatAmount(widget.amount)}',
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
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'PromptPay QR',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
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
                    Navigator.of(dialogContext).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to top-up screen
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

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _formatTimeRemaining() {
    if (_expiresAt == null) return '';

    final now = DateTime.now();
    final difference = _expiresAt!.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan to Pay',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Generating QR code...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Error Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time,
                            size: 56,
                            color: Colors.red.shade400,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error Title
                        Text(
                          _errorMessage!.contains('expired')
                              ? 'QR Code Expired'
                              : 'Payment Failed',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Error Description
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Action Buttons
                        Column(
                          children: [
                            // Try Again Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // User can generate new QR by selecting PromptPay again
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
                                  'Try Again',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Cancel Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Go back to top-up screen
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Help Text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Need help? Contact support',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        // Payment Info Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '฿${_formatAmount(widget.amount)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            // Timer Badge
                            if (_expiresAt != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Colors.orange.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTimeRemaining(),
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // QR Code Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // PromptPay Label
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.qr_code_2,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'PromptPay',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // QR Code - Smaller and centered, hiding top branding
                              RepaintBoundary(
                                key: _qrKey,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: _qrData != null
                                        ? OverflowBox(
                                            maxWidth: 220,

                                            maxHeight: 300,
                                            child: Transform.translate(
                                              offset: const Offset(0, -50),
                                              child: SvgPicture.network(
                                                '$_qrData?t=${DateTime.now().millisecondsSinceEpoch}',
                                                width: 220,
                                                fit: BoxFit.fitWidth,
                                                placeholderBuilder: (context) => const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Scan Instruction
                              Text(
                                'Scan with any banking app',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Download Button
                              OutlinedButton.icon(
                                onPressed: _downloadQRCode,
                                icon: Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                label: Text(
                                  'Save QR Code',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Simple Instructions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How to pay',
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSimpleStep('Open your mobile banking app'),
                              _buildSimpleStep('Select Scan QR or PromptPay'),
                              _buildSimpleStep('Scan the QR code above'),
                              _buildSimpleStep('Confirm the payment'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}