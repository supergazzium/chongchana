import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/top_up_promptpay.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TopUpPaymentMethodScreen extends StatefulWidget {
  final double amount;

  const TopUpPaymentMethodScreen({
    Key? key,
    required this.amount,
  }) : super(key: key);

  @override
  _TopUpPaymentMethodScreenState createState() =>
      _TopUpPaymentMethodScreenState();
}

class _TopUpPaymentMethodScreenState extends State<TopUpPaymentMethodScreen> {
  String selectedMethod = 'promptpay';
  bool isBankTransferExpanded = false;

  final double cardFeePercent = 0.03;
  final double cardFeeFixed = 2.00;

  final List<Map<String, dynamic>> bankingApps = [
    {
      'name': 'K PLUS',
      'scheme': 'kplus://',
      'package': 'com.kasikornbank.retail.kplus',
      'color': const Color(0xFF138F2D),
      'logo': 'assets/images/banks/KBANK.png'
    },
    {
      'name': 'SCB Easy',
      'scheme': 'scbeasy://',
      'package': 'com.scb.phone',
      'color': const Color(0xFF4E2A84),
      'logo': 'assets/images/banks/SCB.png'
    },
    {
      'name': 'Krungsri (KMA)',
      'scheme': 'kma://',
      'package': 'com.krungsri.kma',
      'color': const Color(0xFFFDB913),
      'logo': 'assets/images/banks/BAY.png'
    },
    {
      'name': 'BBL',
      'scheme': 'bualuang://',
      'package': 'th.co.bbl.mbanking',
      'color': const Color(0xFF152F8A),
      'logo': 'assets/images/banks/BBL.png'
    },
    {
      'name': 'KTB Next',
      'scheme': 'ktbnext://',
      'package': 'com.ktb.android.ktbnext',
      'color': const Color(0xFF00AEEF),
      'logo': 'assets/images/banks/KTB.png'
    },
  ];

  double _calculateCardFee() {
    return (widget.amount * cardFeePercent) + cardFeeFixed;
  }

  double _calculateNetAmount(String method) {
    if (method == 'card') {
      return widget.amount - _calculateCardFee();
    }
    return widget.amount;
  }

  Future<void> _openBankingApp(String scheme, String packageName, String bankName) async {
    final Uri uri = Uri.parse(scheme);

    try {
      final bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$bankName app is not installed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $bankName app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _continue() {
    if (selectedMethod == 'promptpay') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TopUpPromptPayScreen(
            amount: widget.amount,
          ),
        ),
      );
    } else if (selectedMethod == 'card') {
      // TODO: Navigate to card payment screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card payment coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (selectedMethod == 'bank_transfer') {
      // TODO: Navigate to bank transfer screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank transfer coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Top-up ฿${_formatAmount(widget.amount)}'),
        backgroundColor: ChongjaroenColors.primaryColors,
      ),
      backgroundColor: ChongjaroenColors.primaryColors.shade900,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose payment method:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethodOption(
                      method: 'card',
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      fee: 'Fee: ${(cardFeePercent * 100).toStringAsFixed(0)}% + ฿${cardFeeFixed.toStringAsFixed(2)} (฿${_formatAmount(_calculateCardFee())})',
                      netAmount: '฿${_formatAmount(_calculateNetAmount('card'))}',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodOption(
                      method: 'promptpay',
                      icon: Icons.qr_code_scanner,
                      title: 'PromptPay QR',
                      fee: 'Fee: Free',
                      netAmount: '฿${_formatAmount(_calculateNetAmount('promptpay'))}',
                    ),
                    const SizedBox(height: 12),
                    _buildBankTransferOption(),
                  ],
                ),
              ),
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildBankTransferOption() {
    final isSelected = selectedMethod == 'bank_transfer';

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              selectedMethod = 'bank_transfer';
              isBankTransferExpanded = !isBankTransferExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChongjaroenColors.primaryColors.shade800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ChongjaroenColors.secondaryColor
                    : ChongjaroenColors.primaryColors.shade600,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: 'bank_transfer',
                      groupValue: selectedMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedMethod = value!;
                          isBankTransferExpanded = !isBankTransferExpanded;
                        });
                      },
                      activeColor: ChongjaroenColors.secondaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bank Transfer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fee: Free',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(Mobile Banking Apps)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You'll receive: ฿${_formatAmount(_calculateNetAmount('bank_transfer'))}",
                            style: const TextStyle(
                              color: ChongjaroenColors.secondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isBankTransferExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isBankTransferExpanded) ...[
          const SizedBox(height: 12),
          ...bankingApps.map((bank) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildBankingAppOption(
              bankName: bank['name']!,
              scheme: bank['scheme']!,
              packageName: bank['package']!,
              bankColor: bank['color']!,
              logoUrl: bank['logo'],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildBankingAppOption({
    required String bankName,
    required String scheme,
    required String packageName,
    required Color bankColor,
    String? logoUrl,
  }) {
    return GestureDetector(
      onTap: () => _openBankingApp(scheme, packageName, bankName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: ChongjaroenColors.primaryColors.shade700,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChongjaroenColors.primaryColors.shade600,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: bankColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                bankName.split(' ')[0].substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: bankColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          bankName.split(' ')[0].substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String method,
    required IconData icon,
    required String title,
    required String fee,
    required String netAmount,
    String? subtitle,
  }) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ChongjaroenColors.primaryColors.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ChongjaroenColors.secondaryColor
                : ChongjaroenColors.primaryColors.shade600,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: method,
              groupValue: selectedMethod,
              onChanged: (value) {
                setState(() {
                  selectedMethod = value!;
                });
              },
              activeColor: ChongjaroenColors.secondaryColor,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fee,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    "You'll receive: $netAmount",
                    style: const TextStyle(
                      color: ChongjaroenColors.secondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
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
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}