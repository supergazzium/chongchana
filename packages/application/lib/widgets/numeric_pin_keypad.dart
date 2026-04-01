import 'package:flutter/material.dart';
import 'package:chongchana/constants/colors.dart';

/// Custom Numeric PIN Keypad Modal
/// Slides up from bottom with minimalist Starbucks-clean aesthetic
/// Shows 6 dots indicator and borderless numeric keypad
class NumericPinKeypad extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String) onCompleted;
  final Function()? onCancel;
  final bool obscureInput;

  const NumericPinKeypad({
    Key? key,
    this.title = 'Enter PIN',
    this.subtitle = 'Enter your 6-digit PIN to continue',
    required this.onCompleted,
    this.onCancel,
    this.obscureInput = true,
  }) : super(key: key);

  @override
  _NumericPinKeypadState createState() => _NumericPinKeypadState();

  /// Show the PIN keypad as a modal bottom sheet
  static Future<String?> show({
    required BuildContext context,
    String title = 'Enter PIN',
    String subtitle = 'Enter your 6-digit PIN to continue',
    bool obscureInput = true,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NumericPinKeypad(
          title: title,
          subtitle: subtitle,
          obscureInput: obscureInput,
          onCompleted: (pin) {
            Navigator.pop(context, pin);
          },
          onCancel: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _NumericPinKeypadState extends State<NumericPinKeypad>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Starbucks Deep Green
  static const Color _deepGreen = Color(0xFF006241);

  @override
  void initState() {
    super.initState();

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
      });

      // Trigger completion if PIN is complete
      if (_pin.length == 6) {
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onCompleted(_pin);
        });
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _deepGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 6 Dots Indicator (green active, light gray inactive)
              _buildDotsIndicator(),
              const SizedBox(height: 40),

              // Custom Numeric Keypad
              _buildNumericKeypad(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isActive = index < _pin.length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _deepGreen : Colors.grey.shade200,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _deepGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: isActive && !widget.obscureInput
              ? Center(
                  child: Text(
                    _pin[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        );
      }),
    );
  }

  Widget _buildNumericKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),

          // Row 2: 4, 5, 6
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),

          // Row 3: 7, 8, 9
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),

          // Row 4: Clear, 0, Backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionKey(
                icon: Icons.clear,
                onPressed: _onClearPressed,
                label: 'Clear',
              ),
              _buildNumberKey('0'),
              _buildActionKey(
                icon: Icons.backspace_outlined,
                onPressed: _onBackspacePressed,
                label: 'Del',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberKey(number)).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}