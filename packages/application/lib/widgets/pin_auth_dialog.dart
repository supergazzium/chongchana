import 'package:flutter/material.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/widgets/pin_input.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:provider/provider.dart';

class PinAuthDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool canUseBiometric;

  const PinAuthDialog({
    Key? key,
    this.title = 'Enter PIN',
    this.subtitle = 'Enter your 6-digit PIN to continue',
    this.canUseBiometric = true,
  }) : super(key: key);

  @override
  _PinAuthDialogState createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<PinAuthDialog> {
  String _currentPin = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _attemptCount = 0;
  static const int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Try biometric authentication first if enabled
    if (widget.canUseBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryBiometricAuth();
      });
    }
  }

  Future<void> _tryBiometricAuth() async {
    final authService = Provider.of<WalletAuthService>(context, listen: false);

    if (authService.isBiometricEnabled && authService.isBiometricAvailable) {
      final result = await authService.authenticateWithBiometric(
        reason: widget.subtitle,
      );

      if (result && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _verifyPin(String pin) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<WalletAuthService>(context, listen: false);
    final isValid = await authService.verifyPin(pin);

    if (mounted) {
      if (isValid) {
        Navigator.of(context).pop(true);
      } else {
        _attemptCount++;

        if (_attemptCount >= _maxAttempts) {
          setState(() {
            _errorMessage = 'Too many failed attempts. Please try again later.';
            _isLoading = false;
          });

          // Close dialog after showing error
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop(false);
          }
        } else {
          setState(() {
            _errorMessage =
                'Incorrect PIN. ${_maxAttempts - _attemptCount} attempts remaining.';
            _isLoading = false;
            _currentPin = ''; // Reset PIN for next attempt
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<WalletAuthService>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ChongjaroenColors.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 32,
                color: ChongjaroenColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title and subtitle
            PinInput(
              title: widget.title,
              subtitle: widget.subtitle,
              onCompleted: _verifyPin,
              obscureText: true,
            ),

            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Biometric button (if available and enabled)
            if (authService.isBiometricAvailable &&
                authService.isBiometricEnabled &&
                widget.canUseBiometric)
              TextButton.icon(
                onPressed: _isLoading ? null : _tryBiometricAuth,
                icon: Icon(
                  Icons.fingerprint,
                  color: _isLoading
                      ? Colors.grey
                      : ChongjaroenColors.secondaryColor,
                ),
                label: Text(
                  'Use ${authService.getBiometricTypeName()}',
                  style: TextStyle(
                    color: _isLoading
                        ? Colors.grey
                        : ChongjaroenColors.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show PIN authentication dialog
Future<bool> showPinAuthDialog(
  BuildContext context, {
  String title = 'Enter PIN',
  String subtitle = 'Enter your 6-digit PIN to continue',
  bool canUseBiometric = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PinAuthDialog(
      title: title,
      subtitle: subtitle,
      canUseBiometric: canUseBiometric,
    ),
  );

  return result ?? false;
}