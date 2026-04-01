import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/reset_pin.dart';
import 'package:chongchana/services/auth.dart';
import 'dart:async';

/// OTP Verification screen for PIN reset
/// Starbucks-Premium minimalist aesthetic
class VerifyOtpPinResetScreen extends StatefulWidget {
  final String method; // 'phone' or 'email'
  final String maskedContact;

  const VerifyOtpPinResetScreen({
    Key? key,
    required this.method,
    required this.maskedContact,
  }) : super(key: key);

  @override
  _VerifyOtpPinResetScreenState createState() => _VerifyOtpPinResetScreenState();
}

class _VerifyOtpPinResetScreenState extends State<VerifyOtpPinResetScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String _otp = '';
  bool _isVerifying = false;
  bool _showError = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  // Design constants
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardBackground = Colors.white;
  static final Color _greenPrimary = ChongjaroenColors.primaryColors;
  static final Color _greenAccent = ChongjaroenColors.secondaryColors;
  static const Color _textPrimary = Color(0xFF1E1E1E);
  static const Color _textSecondary = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty) {
      // Handle backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    // Build complete OTP
    _otp = _controllers.map((c) => c.text).join();
    setState(() {
      _showError = false;
    });

    // Auto-verify when all 6 digits entered
    if (_otp.length == 6) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) return;

    setState(() {
      _isVerifying = true;
      _showError = false;
    });

    HapticFeedback.mediumImpact();

    try {
      final authState = ChongjaroenAuthScope.of(context);

      final result = await authState.verifyPinResetOTP(
        otp: _otp,
        method: widget.method,
      );

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      if (result['success'] == true) {
        HapticFeedback.heavyImpact();

        // Navigate to PIN reset screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPinScreen(
              resetToken: result['resetToken'] ?? '',
            ),
          ),
        );
      } else {
        // Invalid OTP
        HapticFeedback.heavyImpact();
        setState(() {
          _showError = true;
          _otp = '';
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _showError = true;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;

    try {
      final authState = ChongjaroenAuthScope.of(context);

      final result = await authState.requestPinResetOTP(
        method: widget.method,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification code sent successfully'),
            backgroundColor: _greenAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to resend code'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.method == 'phone' ? Icons.phone_android : Icons.email_outlined,
                  size: 40,
                  color: _greenAccent,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We sent a 6-digit code to\n${widget.maskedContact}',
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.all(0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _greenAccent,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _cardBackground,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onOtpChanged(index, value),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_showError)
                Text(
                  'Invalid verification code. Please try again.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade600,
                  ),
                ),
              const SizedBox(height: 32),

              // Processing Indicator
              if (_isVerifying) ...[
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_greenAccent),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verifying code...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Didn\'t receive the code?',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _resendCountdown > 0
                      ? Text(
                          'Resend in ${_resendCountdown}s',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        )
                      : TextButton(
                          onPressed: _resendOTP,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Resend',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _greenAccent,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}