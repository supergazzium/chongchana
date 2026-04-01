import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Reset PIN screen - Final step in PIN recovery flow
/// Follows Starbucks-Premium minimalist aesthetic
class ResetPinScreen extends StatefulWidget {
  final String resetToken;

  const ResetPinScreen({
    Key? key,
    required this.resetToken,
  }) : super(key: key);

  @override
  _ResetPinScreenState createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String _firstPin = '';
  String _confirmPin = '';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Design constants - Starbucks aesthetic
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardBackground = Colors.white;
  static final Color _greenPrimary = ChongjaroenColors.primaryColors;
  static final Color _greenAccent = ChongjaroenColors.secondaryColors;
  static const Color _textPrimary = Color(0xFF1E1E1E);
  static const Color _textSecondary = Color(0xFF6B6B6B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onFirstPinCompleted(String pin) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _firstPin = pin;
    });

    // Animate to next step
    await _animationController.reverse();
    setState(() {
      _currentStep = 1;
    });
    await _animationController.forward();
  }

  Future<void> _onConfirmPinCompleted(String pin) async {
    setState(() {
      _confirmPin = pin;
    });

    if (_firstPin != _confirmPin) {
      HapticFeedback.heavyImpact();
      _showErrorToast('PINs don\'t match. Let\'s try again.');

      await _animationController.reverse();
      setState(() {
        _currentStep = 0;
        _firstPin = '';
        _confirmPin = '';
      });
      await _animationController.forward();
      return;
    }

    HapticFeedback.mediumImpact();
    await _resetPin();
  }

  Future<void> _resetPin() async {
    setState(() => _isLoading = true);

    try {
      final authState = ChongjaroenAuthScope.of(context);

      final result = await authState.resetPinWithToken(
        resetToken: widget.resetToken,
        newPin: _firstPin,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success'] == true) {
        HapticFeedback.heavyImpact();
        _showSuccessToast('PIN reset successfully!');

        // Navigate back to the start (close all reset screens)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showErrorToast(result['message'] ?? 'Failed to reset PIN. Please try again.');

        // Reset to first step
        await _animationController.reverse();
        setState(() {
          _currentStep = 0;
          _firstPin = '';
          _confirmPin = '';
        });
        await _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorToast('An error occurred. Please try again.');

      // Reset to first step
      if (mounted) {
        await _animationController.reverse();
        setState(() {
          _currentStep = 0;
          _firstPin = '';
          _confirmPin = '';
        });
        await _animationController.forward();
      }
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: _greenAccent,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red.shade400,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _buildProgressIndicator(),
                      const SizedBox(height: 48),
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _CleanPinInput(
                        key: ValueKey(_currentStep),
                        onCompleted: _currentStep == 0
                            ? _onFirstPinCompleted
                            : _onConfirmPinCompleted,
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading) _buildLoader(),
                      if (!_isLoading) _buildInfoCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            color: _isLoading ? Colors.grey : _textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Reset PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepDot(isActive: true, isCompleted: _currentStep > 0),
        _ProgressLine(isActive: _currentStep > 0),
        _StepDot(isActive: _currentStep >= 1, isCompleted: false),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStep == 0 ? Icons.lock_reset : Icons.check_circle_outline,
                  size: 40,
                  color: _greenAccent,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          _currentStep == 0 ? 'Create New PIN' : 'Confirm New PIN',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _currentStep == 0
                ? 'Choose a new 6-digit PIN for your wallet'
                : 'Re-enter the same 6 digits to confirm',
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Column(
      children: [
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
          'Resetting your PIN...',
          style: TextStyle(
            fontSize: 14,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 24,
              color: _greenAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & Encrypted',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _greenPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your new PIN will be encrypted and stored securely',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Step Dot Component
class _StepDot extends StatelessWidget {
  final bool isActive;
  final bool isCompleted;

  const _StepDot({
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final greenAccent = ChongjaroenColors.secondaryColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? greenAccent : const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : null,
    );
  }
}

// Progress Line Component
class _ProgressLine extends StatelessWidget {
  final bool isActive;

  const _ProgressLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final greenAccent = ChongjaroenColors.secondaryColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? greenAccent : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// Clean PIN Input Component with custom numeric keypad
class _CleanPinInput extends StatefulWidget {
  final Function(String) onCompleted;

  const _CleanPinInput({
    Key? key,
    required this.onCompleted,
  }) : super(key: key);

  @override
  _CleanPinInputState createState() => _CleanPinInputState();
}

class _CleanPinInputState extends State<_CleanPinInput> {
  String _pin = '';
  final int _pinLength = 6;

  static final Color _greenAccent = ChongjaroenColors.secondaryColors;

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin += number;
      });

      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onCompleted(_pin);
        });
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPinDots(),
        const SizedBox(height: 48),
        _buildNumericKeypad(),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
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
                    color: isFilled ? _greenAccent : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: isFilled ? _greenAccent : const Color(0xFFE0E0E0),
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildKeyRow(['', '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    if (key.isEmpty) {
      return const SizedBox(width: 72, height: 72);
    }

    final isDelete = key == 'delete';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isDelete) {
            _onBackspacePressed();
          } else {
            _onNumberPressed(key);
          }
        },
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
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
            child: isDelete
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 24,
                    color: Color(0xFF6B6B6B),
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}