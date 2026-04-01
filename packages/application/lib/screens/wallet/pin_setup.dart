import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

// Design Constants - Starbucks-inspired Clean Aesthetic
class _PinSetupConstants {
  // Colors - Clean & Minimal
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static Color greenPrimary = ChongjaroenColors.primaryColors;
  static Color greenAccent = ChongjaroenColors.secondaryColors;

  // Typography
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Color(0xFF1E1E1E),
    letterSpacing: -0.5,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B6B6B),
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF9E9E9E),
  );

  // Spacing
  static const double spacingXS = 8.0;
  static const double spacingS = 16.0;
  static const double spacingM = 24.0;
  static const double spacingL = 32.0;
  static const double spacingXL = 48.0;
}

class PinSetupScreen extends StatefulWidget {
  final bool isFirstTimeSetup;

  const PinSetupScreen({
    Key? key,
    this.isFirstTimeSetup = true,
  }) : super(key: key);

  @override
  _PinSetupScreenState createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String _firstPin = '';
  String _confirmPin = '';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    await _setupPin();
  }

  Future<void> _setupPin() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<WalletAuthService>(context, listen: false);
    final success = await authService.setupPin(_firstPin);

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessToast('PIN created successfully!');
      if (mounted) {
        if (widget.isFirstTimeSetup) {
          await _showBiometricSetupDialog();
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      _showErrorToast('Couldn\'t create PIN. Please try again.');
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: _PinSetupConstants.greenAccent,
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

  Future<void> _showBiometricSetupDialog() async {
    final authService = Provider.of<WalletAuthService>(context, listen: false);

    if (!authService.isBiometricAvailable) {
      Navigator.of(context).pop(true);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BiometricSetupDialog(
        biometricType: authService.getBiometricTypeName(),
      ),
    );

    if (result == true) {
      try {
        await authService.setBiometricEnabled(true);
        _showSuccessToast('Biometric authentication enabled');
      } catch (e) {
        _showErrorToast('Couldn\'t enable biometric');
      }
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PinSetupConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: _PinSetupConstants.spacingM,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: _PinSetupConstants.spacingL),
                      _buildProgressIndicator(),
                      const SizedBox(height: _PinSetupConstants.spacingXL),
                      _buildHeader(),
                      const SizedBox(height: _PinSetupConstants.spacingXL),
                      _CleanPinInput(
                        key: ValueKey(_currentStep),
                        onCompleted: _currentStep == 0
                            ? _onFirstPinCompleted
                            : _onConfirmPinCompleted,
                      ),
                      const SizedBox(height: _PinSetupConstants.spacingL),
                      if (_isLoading) _buildLoader(),
                      if (widget.isFirstTimeSetup && !_isLoading)
                        _buildInfoCard(),
                      const SizedBox(height: _PinSetupConstants.spacingL),
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
      padding: const EdgeInsets.all(_PinSetupConstants.spacingS),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF1E1E1E),
          ),
          Expanded(
            child: Text(
              widget.isFirstTimeSetup ? 'Create PIN' : 'New PIN',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E1E),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _PinSetupConstants.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStep == 0 ? Icons.lock_outline : Icons.check_circle_outline,
                  size: 36,
                  color: _PinSetupConstants.greenAccent,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: _PinSetupConstants.spacingM),
        Text(
          _currentStep == 0 ? 'Create Your PIN' : 'Confirm Your PIN',
          style: _PinSetupConstants.headlineStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: _PinSetupConstants.spacingS),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _PinSetupConstants.spacingM),
          child: Text(
            _currentStep == 0
                ? 'Choose a 6-digit PIN that\'s easy for you to remember'
                : 'Re-enter the same 6 digits to confirm',
            style: _PinSetupConstants.subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          _PinSetupConstants.greenAccent,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(_PinSetupConstants.spacingS),
      decoration: BoxDecoration(
        color: _PinSetupConstants.greenPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _PinSetupConstants.greenPrimary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _PinSetupConstants.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 20,
              color: _PinSetupConstants.greenAccent,
            ),
          ),
          const SizedBox(width: _PinSetupConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & Private',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _PinSetupConstants.greenPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your PIN is encrypted and never shared',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6B6B),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? _PinSetupConstants.greenAccent
            : const Color(0xFFE0E0E0),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive
            ? _PinSetupConstants.greenAccent
            : const Color(0xFFE0E0E0),
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
        const SizedBox(height: _PinSetupConstants.spacingXL),
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
                  color: isFilled
                      ? _PinSetupConstants.greenAccent
                      : Colors.transparent,
                  border: Border.all(
                    color: isFilled
                        ? _PinSetupConstants.greenAccent
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: isFilled
                      ? _PinSetupConstants.greenAccent
                      : const Color(0xFFE0E0E0),
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

// Biometric Setup Dialog
class _BiometricSetupDialog extends StatelessWidget {
  final String biometricType;

  const _BiometricSetupDialog({required this.biometricType});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(_PinSetupConstants.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _PinSetupConstants.greenAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint,
                size: 32,
                color: _PinSetupConstants.greenAccent,
              ),
            ),
            const SizedBox(height: _PinSetupConstants.spacingM),
            const Text(
              'Enable Biometric?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: _PinSetupConstants.spacingS),
            Text(
              'Use $biometricType for quick and secure authentication',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B6B6B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _PinSetupConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _PinSetupConstants.greenAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enable',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
