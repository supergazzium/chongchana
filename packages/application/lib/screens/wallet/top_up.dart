import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/screens/wallet/credit_card_form.dart';
import 'package:chongchana/screens/wallet/mobile_banking_waiting.dart';
import 'package:chongchana/screens/wallet/promptpay_qr.dart';
import 'package:chongchana/screens/wallet/pin_setup.dart';
import 'package:chongchana/screens/wallet/transaction_confirmation.dart';
import 'package:chongchana/services/omise_payment.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:chongchana/widgets/pin_auth_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  _TopUpScreenState createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> with WidgetsBindingObserver {
  final TextEditingController _amountController = TextEditingController();
  double? selectedAmount;
  final double currentBalance = .00;
  final double minAmount = 1.00;
  final double maxAmount = 20000.00;

  final String cardNumber = '4622';
  final String userName = 'ChongJaroen User';
  String? selectedPaymentMethod;

  final List<double> quickAmounts = [300, 500, 1000, 3000, 5000, 10000];

  // Track pending mobile banking payment
  String? _pendingChargeId;
  bool _isCheckingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _amountController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background, check if there's a pending payment
    if (state == AppLifecycleState.resumed && _pendingChargeId != null && !_isCheckingPayment) {
      print('[TopUp] App resumed, checking payment status for: $_pendingChargeId');
      _checkPendingPayment();
    }
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

  void _continue() async {
    if (selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
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

    // Show transaction confirmation screen with PIN verification
    String paymentMethodName = _getPaymentMethodName(selectedPaymentMethod!);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionConfirmationScreen(
          type: TransactionType.topUp,
          amount: selectedAmount!,
          details: [
            TransactionDetail(
              label: 'Wallet',
              value: '$userName ($cardNumber)',
            ),
            TransactionDetail(
              label: 'Payment Method',
              value: paymentMethodName,
            ),
            const TransactionDetail.divider(),
            TransactionDetail(
              label: 'Amount',
              value: '฿${_formatAmount(selectedAmount!)}',
              isHighlighted: true,
            ),
          ],
          onConfirm: (pin) async {
            // This callback is called after PIN is verified
            // Process the actual payment
            return await _processPayment();
          },
          onSuccess: () {
            // Payment processed successfully
            Navigator.pop(context); // Close confirmation screen
            // Then show the appropriate payment flow
            if (selectedPaymentMethod == 'credit_card') {
              _handleCreditCardPayment();
            } else if (selectedPaymentMethod == 'mobile_banking' ||
                       selectedPaymentMethod!.startsWith('mobile_banking_')) {
              _handleMobileBankingPayment();
            } else if (selectedPaymentMethod == 'promptpay') {
              _handlePromptPayPayment();
            } else {
              _showSuccessDialog('Mock payment successful');
            }
          },
        ),
      ),
    );
  }

  void _handlePromptPayPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromptPayQRScreen(
          amount: selectedAmount!,
        ),
      ),
    );
  }

  void _handleCreditCardPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditCardFormScreen(
          amount: selectedAmount!,
          onPaymentSuccess: (transactionId) {
            _showSuccessDialog(transactionId);
          },
        ),
      ),
    );
  }

  Future<void> _handleMobileBankingPayment() async {
    final omiseService = Provider.of<OmisePaymentService>(context, listen: false);
    String bankName = _getBankName(selectedPaymentMethod!);

    BuildContext? loadingDialogContext;
    bool userCancelled = false;

    void dismissLoadingDialog() {
      if (loadingDialogContext != null) {
        final ctx = loadingDialogContext!;
        loadingDialogContext = null;
        if (Navigator.canPop(ctx)) {
          Navigator.pop(ctx);
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingDialogContext = dialogContext;
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Creating payment with $bankName...',
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  userCancelled = true;
                  dismissLoadingDialog();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );

    try {
      print('[TopUp] Selected payment method: $selectedPaymentMethod');
      print('[TopUp] Amount: $selectedAmount');

      // Create internet banking charge
      final result = await omiseService.createInternetBankingCharge(
        amount: selectedAmount!,
        currency: 'THB',
        paymentMethod: selectedPaymentMethod!,
        metadata: {
          'type': 'wallet_topup',
          'user': userName,
        },
      );

      print('[TopUp] Result from createInternetBankingCharge: $result');

      // Always close loading dialog first - by its own context, not by route stack
      dismissLoadingDialog();

      if (userCancelled || !mounted) return;

      if (result != null && result['success'] == true) {
        final chargeId = result['chargeId'];
        final authorizeUri = result['authorizeUri'];

        // Store charge ID for payment verification when app resumes
        setState(() {
          _pendingChargeId = chargeId;
        });

        // Launch banking app and navigate to waiting screen
        if (authorizeUri != null) {
          final uri = Uri.parse(authorizeUri);
          if (await canLaunchUrl(uri)) {
            // Launch the bank app
            await launchUrl(uri, mode: LaunchMode.externalApplication);

            // Navigate to waiting screen that will poll for payment status
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MobileBankingWaitingScreen(
                    amount: selectedAmount!,
                    bankName: bankName,
                    chargeId: chargeId,
                  ),
                ),
              );

              // Clear pending charge when returning from waiting screen
              if (mounted) {
                setState(() {
                  _pendingChargeId = null;
                });

                // If payment was successful, go back to wallet overview
                if (result == true) {
                  Navigator.pop(context); // Pop TopUpScreen to return to WalletOverview
                }
              }
            }
          } else {
            // Banking app not installed or URL cannot be launched
            _showErrorDialog(
              'Cannot open $bankName app. Please make sure it is installed.',
            );
            setState(() {
              _pendingChargeId = null; // Clear pending payment
            });
          }
        }
      } else {
        _showErrorDialog('Failed to create payment. Please try again.');
      }
    } catch (e) {
      print('[TopUp] Error in _handleMobileBankingPayment: $e');
      dismissLoadingDialog();
      if (!mounted || userCancelled) return;
      _showErrorDialog('An error occurred: ${e.toString()}');
    }
  }

  Future<void> _checkPendingPayment() async {
    if (_pendingChargeId == null || _isCheckingPayment) return;

    setState(() {
      _isCheckingPayment = true;
    });

    final omiseService = Provider.of<OmisePaymentService>(context, listen: false);

    try {
      print('[TopUp] Checking payment status for: $_pendingChargeId');

      final paymentData = await omiseService.verifyPayment(_pendingChargeId!);

      if (!mounted) return;

      if (paymentData != null && paymentData['paid'] == true) {
        // Payment successful!
        print('[TopUp] Payment completed successfully');

        final transactionId = paymentData['transactionId'];
        setState(() {
          _pendingChargeId = null;
          _isCheckingPayment = false;
        });

        // Show success dialog
        _showSuccessDialog(transactionId);
      } else {
        print('[TopUp] Payment not yet completed');
        setState(() {
          _isCheckingPayment = false;
        });
      }
    } catch (e) {
      print('[TopUp] Error checking payment: $e');
      if (mounted) {
        setState(() {
          _isCheckingPayment = false;
        });
      }
    }
  }

  void _showSuccessDialog(String transactionId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Top-up Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ฿${selectedAmount != null ? _formatAmount(selectedAmount!) : "0.00"}',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment Method: ${selectedPaymentMethod != null ? selectedPaymentMethod!.replaceAll('_', ' ').toUpperCase() : "N/A"}',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: $transactionId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your wallet has been topped up successfully.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to wallet overview
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChongjaroenColors.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: ChongjaroenColors.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Add money'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildCardSelector(),
              const SizedBox(height: 24),
              _buildAmountSection(),
              const SizedBox(height: 24),
              _buildPaymentMethodSection(),
              const SizedBox(height: 32),
              _buildContinueButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ChongjaroenColors.primaryColors.shade400,
                        ChongjaroenColors.primaryColors.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userName ($cardNumber)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '฿${_formatAmount(currentBalance)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedAmount != null
                    ? ChongjaroenColors.secondaryColor
                    : Colors.grey.shade300,
                width: selectedAmount != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: _onCustomAmountChanged,
                    onSubmitted: (_) {
                      // Dismiss keyboard when Done is tapped
                      FocusScope.of(context).unfocus();
                    },
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                if (selectedAmount != null)
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The value of a card should not exceed ฿${_formatAmount(maxAmount)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: quickAmounts.map((amount) => _buildQuickAmountButton(amount)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    final isSelected = selectedAmount == amount;

    return GestureDetector(
      onTap: () => _selectAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ChongjaroenColors.secondaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ChongjaroenColors.secondaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          amount.toStringAsFixed(0),
          style: TextStyle(
            color: isSelected
                ? ChongjaroenColors.secondaryColor
                : Colors.black87,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      children: [
        const Divider(height: 1),
        _buildPaymentMethodOption(
          icon: Icons.credit_card,
          title: 'Credit / Debit Card',
          value: 'credit_card',
        ),
        const Divider(height: 1),
        _buildPaymentMethodOption(
          icon: Icons.qr_code_scanner,
          title: 'PromptPay QR',
          value: 'promptpay',
        ),
        const Divider(height: 1),
        _buildPaymentMethodOption(
          icon: Icons.phone_android,
          title: 'Mobile Banking',
          value: 'mobile_banking',
          hasSubOptions: true,
        ),
        if (selectedPaymentMethod == 'mobile_banking' ||
            (selectedPaymentMethod != null && selectedPaymentMethod!.startsWith('mobile_banking_'))) ...[
          _buildBankOption('Bangkok Bank Mobile Banking', 'bbl'),
          _buildBankOption('K PLUS (Kasikorn)', 'kbank'),
          _buildBankOption('SCB Easy', 'scb'),
          _buildBankOption('Krungsri (Bank of Ayudhya)', 'bay'),
          // TODO: Uncomment when Omise activates KTB for this account
          // _buildBankOption('Krungthai NEXT', 'ktb'),
        ],
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required String value,
    bool hasSubOptions = false,
  }) {
    // For mobile banking, also consider it selected if any sub-bank is selected
    final isSelected = selectedPaymentMethod == value ||
        (hasSubOptions &&
         value == 'mobile_banking' &&
         selectedPaymentMethod != null &&
         selectedPaymentMethod!.startsWith('mobile_banking_'));

    return InkWell(
      onTap: () {
        setState(() {
          if (selectedPaymentMethod == value && hasSubOptions) {
            selectedPaymentMethod = null;
          } else {
            selectedPaymentMethod = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? ChongjaroenColors.secondaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected
                    ? ChongjaroenColors.secondaryColor
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.circle,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.grey.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            if (hasSubOptions)
              Icon(
                isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankOption(String name, String value) {
    final isSelected = selectedPaymentMethod == 'mobile_banking_$value';

    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = 'mobile_banking_$value';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.only(left: 40),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? ChongjaroenColors.secondaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected
                    ? ChongjaroenColors.secondaryColor
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ChongjaroenColors.primaryColors.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    color: ChongjaroenColors.primaryColors,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = selectedAmount != null && selectedPaymentMethod != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled ? _continue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ChongjaroenColors.secondaryColor,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: Text(
            'Continue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _getBankName(String paymentMethod) {
    switch (paymentMethod) {
      case 'mobile_banking_bbl':
        return 'Bangkok Bank Mobile Banking';
      case 'mobile_banking_kbank':
        return 'K PLUS (Kasikorn)';
      case 'mobile_banking_scb':
        return 'SCB Easy';
      case 'mobile_banking_bay':
        return 'Krungsri (Bank of Ayudhya)';
      // TODO: Uncomment when Omise activates KTB for this account
      // case 'mobile_banking_ktb':
      //   return 'Krungthai NEXT';
      default:
        return 'Mobile Banking';
    }
  }

  String _getPaymentMethodName(String paymentMethod) {
    switch (paymentMethod) {
      case 'credit_card':
        return 'Credit / Debit Card';
      case 'promptpay':
        return 'PromptPay QR';
      case 'mobile_banking':
        return 'Mobile Banking';
      default:
        if (paymentMethod.startsWith('mobile_banking_')) {
          return _getBankName(paymentMethod);
        }
        return paymentMethod.replaceAll('_', ' ').toUpperCase();
    }
  }

  Future<bool> _processPayment() async {
    // Simulate payment processing
    // In a real app, this would integrate with your payment backend
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Return true for success, false for failure
  }
}
