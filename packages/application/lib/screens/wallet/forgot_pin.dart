import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/verify_otp_pin_reset.dart';
import 'package:chongchana/services/auth.dart';
import 'package:provider/provider.dart';

/// Forgot PIN screen - Request OTP for PIN reset
/// Follows Starbucks-Premium minimalist aesthetic
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({Key? key}) : super(key: key);

  @override
  _ForgotPinScreenState createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final String _selectedMethod = 'phone'; // Only phone is allowed
  bool _isLoading = false;

  // Design constants - Starbucks aesthetic
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardBackground = Colors.white;
  static final Color _greenPrimary = ChongjaroenColors.primaryColors;
  static final Color _greenAccent = ChongjaroenColors.secondaryColors;
  static const Color _textPrimary = Color(0xFF1E1E1E);
  static const Color _textSecondary = Color(0xFF6B6B6B);

  Future<void> _requestOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ChongjaroenAuthScope.of(context);

      // Request OTP from backend
      final result = await authState.requestPinResetOTP(
        method: _selectedMethod,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpPinResetScreen(
              method: _selectedMethod,
              maskedContact: result['maskedContact'] ?? '',
            ),
          ),
        );
      } else {
        // Show error
        _showError(result['message'] ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('An error occurred. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ChongjaroenAuthScope.of(context);
    final user = authState.user;

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
          'Forgot PIN',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Info Card
              _buildInfoCard(),
              const SizedBox(height: 32),

              // Verification Method - Phone Only
              const Text(
                'Verification code will be sent to',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Phone option (read-only display)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _greenAccent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _greenAccent.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone_android,
                        color: _greenAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _greenPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _maskPhoneNumber(user.phone),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.sms_outlined,
                      color: _greenAccent,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _greenAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send Verification Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 36,
              color: _greenAccent,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Reset Your PIN',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'We\'ll send you a verification code via SMS to confirm your identity before resetting your wallet PIN.',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}';
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return email;

    return '${username.substring(0, 2)}****@$domain';
  }
}