import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chongchana/constants/colors.dart';

class PinInput extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final String? title;
  final String? subtitle;
  final bool obscureText;
  final int pinLength;

  const PinInput({
    Key? key,
    required this.onCompleted,
    this.onChanged,
    this.title,
    this.subtitle,
    this.obscureText = true,
    this.pinLength = 6,
  }) : super(key: key);

  @override
  _PinInputState createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  String _pin = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.pinLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    if (value.isEmpty) {
      // Handle backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else {
      // Move to next field
      if (index < widget.pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered, unfocus
        _focusNodes[index].unfocus();
      }
    }

    // Build the complete PIN
    _pin = _controllers.map((c) => c.text).join();

    if (widget.onChanged != null) {
      widget.onChanged!(_pin);
    }

    // Check if PIN is complete
    if (_pin.length == widget.pinLength) {
      widget.onCompleted(_pin);
    }
  }

  void clearPin() {
    setState(() {
      for (var controller in _controllers) {
        controller.clear();
      }
      _pin = '';
      _focusNodes[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.pinLength,
            (index) => Container(
              width: 48,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                obscureText: widget.obscureText,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                    borderSide: const BorderSide(
                      color: ChongjaroenColors.secondaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => _onPinChanged(index, value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}