import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:chongchana/screens/wallet/forgot_pin.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Transaction types supported by this confirmation screen
enum TransactionType {
  topUp,
  transfer,
  redeem,
}

/// Transaction detail item for display
class TransactionDetail {
  final String label;
  final String value;
  final bool isHighlighted;
  final bool isDivider;

  const TransactionDetail({
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.isDivider = false,
  });

  const TransactionDetail.divider()
      : label = '',
        value = '',
        isHighlighted = false,
        isDivider = true;
}

/// Starbucks-Premium minimalist transaction confirmation screen
/// Shows transaction details with inline PIN verification
class TransactionConfirmationScreen extends StatefulWidget {
  final TransactionType type;
  final double amount;
  final List<TransactionDetail> details;
  final Future<bool> Function(String pin) onConfirm;
  final VoidCallback? onSuccess;
  final String? successMessage;

  const TransactionConfirmationScreen({
    Key? key,
    required this.type,
    required this.amount,
    required this.details,
    required this.onConfirm,
    this.onSuccess,
    this.successMessage,
  }) : super(key: key);

  @override
  _TransactionConfirmationScreenState createState() =>
      _TransactionConfirmationScreenState();
}

class _TransactionConfirmationScreenState
    extends State<TransactionConfirmationScreen> with TickerProviderStateMixin {
  String _pin = '';
  bool _isProcessing = false;
  bool _showError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Design constants - Starbucks aesthetic
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardBackground = Colors.white;
  static final Color _greenPrimary = ChongjaroenColors.primaryColors;
  static final Color _greenAccent = ChongjaroenColors.secondaryColors;
  static const Color _textPrimary = Color(0xFF1E1E1E);
  static const Color _textSecondary = Color(0xFF6B6B6B);
  static const Color _dotInactive = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
        }
      });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 6 && !_isProcessing) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin += number;
        _showError = false;
      });

      if (_pin.length == 6) {
        _verifyAndProcess();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty && !_isProcessing) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _showError = false;
      });
    }
  }

  Future<void> _verifyAndProcess() async {
    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    // First verify with WalletAuthService
    final authService = Provider.of<WalletAuthService>(context, listen: false);
    final isValid = await authService.verifyPin(_pin);

    if (!isValid) {
      // PIN is incorrect
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showError = true;
          _pin = '';
        });
        _shakeController.forward();
      }
      return;
    }

    // PIN is correct, now process the transaction
    try {
      final success = await widget.onConfirm(_pin);

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        // Success - call the success callback
        widget.onSuccess?.call();
      } else {
        // Transaction failed
        setState(() {
          _isProcessing = false;
          _showError = true;
          _pin = '';
        });
        _shakeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showError = true;
          _pin = '';
        });
        _shakeController.forward();
      }
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case TransactionType.topUp:
        return 'Confirm Top-Up';
      case TransactionType.transfer:
        return 'Confirm Transfer';
      case TransactionType.redeem:
        return 'Confirm Redemption';
    }
  }

  String _getAmountLabel() {
    switch (widget.type) {
      case TransactionType.topUp:
        return 'Top-Up Amount';
      case TransactionType.transfer:
        return 'Transfer Amount';
      case TransactionType.redeem:
        return 'Redeem Amount';
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletAuthService>(
      builder: (context, authService, child) {
        // Check if PIN is required based on authorization settings
        final bool isPinRequired = widget.type != TransactionType.topUp &&
                                   authService.shouldRequirePin(widget.amount);

        return Scaffold(
          backgroundColor: _backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // Amount Card
                        _buildAmountCard(),
                        const SizedBox(height: 24),

                        // Transaction Details
                        _buildDetailsCard(),
                        const SizedBox(height: 32),

                        // Check if PIN is required based on settings
                        if (!isPinRequired) ...[
                          // No PIN required - show confirm button
                          if (!_isProcessing)
                            _buildConfirmButton()
                          else
                            _buildProcessingIndicator(),
                        ] else ...[
                          // PIN required - show PIN keypad
                          if (!_isProcessing) ...[
                            _buildPinSection(),
                            const SizedBox(height: 32),

                            // Numeric Keypad
                            _buildNumericKeypad(),
                          ] else ...[
                            // Processing Indicator
                            _buildProcessingIndicator(),
                          ],
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: _isProcessing
                ? null
                : () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: _isProcessing ? Colors.grey : _textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _getTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            _getAmountLabel(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '฿${_formatCurrency(widget.amount)}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: _greenPrimary,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.details.map((detail) {
            if (detail.isDivider) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.grey.shade200, height: 1),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.label,
                    style: TextStyle(
                      fontSize: detail.isHighlighted ? 15 : 14,
                      fontWeight:
                          detail.isHighlighted ? FontWeight.w700 : FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      detail.value,
                      style: TextStyle(
                        fontSize: detail.isHighlighted ? 18 : 14,
                        fontWeight:
                            detail.isHighlighted ? FontWeight.w800 : FontWeight.w600,
                        color: detail.isHighlighted ? _greenPrimary : _textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    return Column(
      children: [
        const Text(
          'Enter PIN to Confirm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // PIN Dots with animation
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: _showError
                  ? Offset(_shakeAnimation.value - 12, 0)
                  : Offset.zero,
              child: child,
            );
          },
          child: _buildPinDots(),
        ),

        if (_showError) ...[
          const SizedBox(height: 16),
          Text(
            'Incorrect PIN. Please try again.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForgotPinScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot PIN?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _greenAccent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final bool isFilled = index < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? _greenAccent : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? _greenAccent : _dotInactive,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: isFilled ? _greenAccent : _dotInactive,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildKeypadRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: key == 'backspace' ? _buildBackspaceKey() : _buildKey(key),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberPressed(key),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: _textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(_greenAccent),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Processing transaction...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  /// Confirm button for transactions not requiring PIN
  Widget _buildConfirmButton() {
    String buttonText;
    String subtitle;

    switch (widget.type) {
      case TransactionType.topUp:
        buttonText = 'Confirm Top-Up';
        subtitle = 'No PIN required for adding funds';
        break;
      case TransactionType.transfer:
        buttonText = 'Confirm Transfer';
        subtitle = 'No PIN required for this amount';
        break;
      case TransactionType.redeem:
        buttonText = 'Confirm Redemption';
        subtitle = 'No PIN required for this amount';
        break;
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmWithoutPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: _greenAccent.withOpacity(0.3),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  /// Process top-up without PIN verification
  Future<void> _confirmWithoutPin() async {
    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // Call onConfirm with empty PIN (top-ups don't need PIN)
      final success = await widget.onConfirm('');

      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        // Success - call the success callback
        widget.onSuccess?.call();
      } else {
        // Transaction failed
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}
