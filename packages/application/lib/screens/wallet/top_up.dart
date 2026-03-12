import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/top_up_payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  _TopUpScreenState createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  double? selectedAmount;
  final double currentBalance = 1250.00;
  final double minAmount = 100.00;
  final double maxAmount = 50000.00;

  final List<double> quickAmounts = [100, 500, 1000, 2000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectAmount(double amount) {
    setState(() {
      selectedAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  void _onCustomAmountChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        selectedAmount = null;
      });
      return;
    }

    try {
      final amount = double.parse(value);
      setState(() {
        selectedAmount = amount;
      });
    } catch (e) {
      setState(() {
        selectedAmount = null;
      });
    }
  }

  void _continue() {
    if (selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedAmount! < minAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum top-up amount is ฿${_formatAmount(minAmount)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedAmount! > maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum top-up amount is ฿${_formatAmount(maxAmount)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopUpPaymentMethodScreen(amount: selectedAmount!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Top-up Wallet'),
        backgroundColor: ChongjaroenColors.primaryColors,
      ),
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentBalance(),
              const SizedBox(height: 32),
              _buildQuickAmounts(),
              const SizedBox(height: 32),
              _buildCustomAmount(),
              const SizedBox(height: 16),
              _buildAmountLimits(),
              const SizedBox(height: 32),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBalance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Current Balance:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            '฿${_formatAmount(currentBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select amount to top-up:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            ...quickAmounts.map((amount) => _buildQuickAmountButton(amount)).toList(),
            _buildOtherAmountButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    final isSelected = selectedAmount == amount && _amountController.text == amount.toStringAsFixed(0);

    return GestureDetector(
      onTap: () => _selectAmount(amount),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? ChongjaroenColors.secondaryColor
              : ChongjaroenColors.primaryColors.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ChongjaroenColors.secondaryColor
                : ChongjaroenColors.primaryColors.shade600,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '฿${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherAmountButton() {
    final isOtherSelected = selectedAmount != null &&
        !quickAmounts.contains(selectedAmount);

    return Container(
      decoration: BoxDecoration(
        color: isOtherSelected
            ? ChongjaroenColors.secondaryColor.withOpacity(0.2)
            : ChongjaroenColors.primaryColors.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOtherSelected
              ? ChongjaroenColors.secondaryColor
              : ChongjaroenColors.primaryColors.shade600,
          width: 2,
        ),
      ),
      child: const Center(
        child: Text(
          'Other Amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Or enter custom amount:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: _onCustomAmountChanged,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            prefixText: '฿ ',
            prefixStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            filled: true,
            fillColor: ChongjaroenColors.primaryColors.shade800,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChongjaroenColors.primaryColors.shade600,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ChongjaroenColors.primaryColors.shade600,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ChongjaroenColors.secondaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountLimits() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Min: ฿${_formatAmount(minAmount)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        Text(
          'Max: ฿${_formatAmount(maxAmount)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChongjaroenColors.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}