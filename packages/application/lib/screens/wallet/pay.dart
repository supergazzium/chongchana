
import 'dart:async';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/wallet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({Key? key}) : super(key: key);

  @override
  _PayScreenState createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  String? _qrToken;
  DateTime? _qrExpiry;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 900; // 15 minutes
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _qrData;

  @override
  void initState() {
    super.initState();
    _initializeQR();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeQR() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final walletService = Provider.of<WalletService>(context, listen: false);

    try {
      // Fetch wallet balance first
      await walletService.getBalance();

      // Generate payment QR
      await _generateQR();

      // Start auto-refresh timer (every 15 minutes)
      _startRefreshTimer();

      // Start countdown timer (every second)
      _startCountdownTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateQR() async {
    final walletService = Provider.of<WalletService>(context, listen: false);

    try {
      print('[PayScreen] Generating payment QR...');

      final response = await walletService.generatePaymentQR(
        purpose: 'payment',
      );

      if (response != null) {
        setState(() {
          _qrData = response;
          _qrToken = response['qrData'] ?? response['token'];
          _qrExpiry = response['expiresAt'] != null
              ? DateTime.parse(response['expiresAt'])
              : DateTime.now().add(const Duration(seconds: 900));
          _secondsRemaining = 900;
          _isLoading = false;
          _error = null;
        });
        print('[PayScreen] QR generated successfully');
        print('[PayScreen] Token: ${_qrToken?.substring(0, 20)}...');
      } else {
        setState(() {
          _error = walletService.error ?? 'Failed to generate QR code';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('[PayScreen] Error generating QR: $e');
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 900), (timer) {
      print('[PayScreen] Auto-refreshing QR code...');
      _generateQR();
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining = _qrExpiry != null
            ? _qrExpiry!.difference(DateTime.now()).inSeconds.clamp(0, 900)
            : _secondsRemaining - 1;

        if (_secondsRemaining < 0) {
          _secondsRemaining = 0;
        }
      });
    });
  }

  String get _qrDisplayData => _qrToken ?? 'GENERATING...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Pay'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Consumer<WalletService>(
        builder: (context, walletService, child) {
          final wallet = walletService.wallet;
          final walletBalance = wallet?.balance ?? 0.0;
          final userId = wallet?.userId.toString() ?? 'Loading...';
          final userName = _qrData?['user']?['username'] ?? 'User';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildWalletCard(userId),
                const SizedBox(height: 16),
                _buildCardSelector(userName, userId),
                const SizedBox(height: 24),
                _buildCardBalance(walletBalance),
                const SizedBox(height: 32),
                _buildQRCode(),
                const SizedBox(height: 16),
                _buildCardNumber(userId),
                const SizedBox(height: 12),
                _buildInstructions(),
                const SizedBox(height: 24),
                _buildRefreshButton(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(String cardNumber) {
    final lastFour = cardNumber.length > 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChongjaroenColors.primaryColors.shade400,
            ChongjaroenColors.primaryColors.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ChongjaroenColors.primaryColors.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative pattern background
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '($lastFour)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSelector(String userName, String cardNumber) {
    final lastFour = cardNumber.length > 4
        ? cardNumber.substring(cardNumber.length - 4)
        : cardNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$userName ($lastFour)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBalance(double walletBalance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARD BALANCE',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '฿${_formatAmount(walletBalance)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _secondsRemaining <= 60
                      ? Colors.red.withOpacity(0.1)
                      : ChongjaroenColors.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: _secondsRemaining <= 60
                          ? Colors.red
                          : ChongjaroenColors.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _secondsRemaining <= 60
                            ? Colors.red
                            : ChongjaroenColors.secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'As of ${_formatDateTime(DateTime.now())}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: const SizedBox(
          height: 220,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.shade200,
            width: 1,
          ),
        ),
        child: SizedBox(
          height: 220,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Failed to generate QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _secondsRemaining <= 60
              ? Colors.red.shade200
              : Colors.grey.shade200,
          width: _secondsRemaining <= 60 ? 2 : 1,
        ),
      ),
      child: QrImageView(
        data: _qrDisplayData,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: _secondsRemaining <= 60 ? Colors.red : Colors.black,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: _secondsRemaining <= 60 ? Colors.red : Colors.black,
        ),
        errorStateBuilder: (cxt, err) {
          return const Center(
            child: Text(
              'Error generating QR code',
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardNumber(String userId) {
    return Center(
      child: Text(
        userId,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Show this QR code to staff to pay at stores',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'QR code refreshes automatically every 15 minutes for security',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _generateQR,
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('Refresh QR Code'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ChongjaroenColors.primaryColors,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM y HH:mm').format(date);
  }
}