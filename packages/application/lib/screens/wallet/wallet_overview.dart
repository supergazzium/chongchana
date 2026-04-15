import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/models/wallet.dart';
import 'package:chongchana/models/wallet_transaction.dart';
import 'package:chongchana/screens/wallet/pay.dart';
import 'package:chongchana/screens/wallet/top_up.dart';
import 'package:chongchana/screens/wallet/transaction_history.dart';
import 'package:chongchana/screens/wallet/transaction_detail.dart';
import 'package:chongchana/screens/wallet/redeem_points.dart';
import 'package:chongchana/screens/wallet/transfer.dart';
import 'package:chongchana/screens/wallet/wallet_security.dart';
import 'package:chongchana/services/wallet.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:chongchana/screens/wallet/pin_setup.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Public helper class to manage pending payments
class WalletPaymentPending {
  static String? _pendingChargeId;
  static double? _pendingAmount;
  static String? _pendingPaymentMethod;

  static void setPendingPayment(String chargeId, double amount, String paymentMethod) {
    print('[WalletPaymentPending] 💾 Setting pending payment: chargeId=$chargeId, amount=$amount, method=$paymentMethod');
    _pendingChargeId = chargeId;
    _pendingAmount = amount;
    _pendingPaymentMethod = paymentMethod;
  }

  static void clearPendingPayment() {
    print('[WalletPaymentPending] 🗑️ Clearing pending payment');
    _pendingChargeId = null;
    _pendingAmount = null;
    _pendingPaymentMethod = null;
  }

  static String? get chargeId => _pendingChargeId;
  static double? get amount => _pendingAmount;
  static String? get paymentMethod => _pendingPaymentMethod;
}

class WalletOverviewScreen extends StatefulWidget {
  const WalletOverviewScreen({Key? key}) : super(key: key);

  @override
  _WalletOverviewScreenState createState() => _WalletOverviewScreenState();
}

class _WalletOverviewScreenState extends State<WalletOverviewScreen> with WidgetsBindingObserver {
  final String cardNumber = '4622'; // Last 4 digits
  final String fullCardNumber = '6179185185694622';
  final String userName = 'ChongJaroen User';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletService = Provider.of<WalletService>(context, listen: false);
      walletService.getSettings();
      walletService.getBalance();
      walletService.getTransactions(limit: 10);

      // Check PIN setup and prompt if needed
      _checkPinSetup();

      // Check for pending payment when screen loads (for programmatic navigation after 3DS)
      if (WalletPaymentPending.chargeId != null) {
        print('[WalletOverview] 💳 Pending payment detected on init');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && WalletPaymentPending.chargeId != null) {
            _checkPendingPayment(
              WalletPaymentPending.chargeId!,
              WalletPaymentPending.amount!,
              WalletPaymentPending.paymentMethod ?? 'unknown',
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[WalletOverview] 🔄 App lifecycle changed to: $state');
    print('[WalletOverview]   chargeId: ${WalletPaymentPending.chargeId}');
    print('[WalletOverview]   amount: ${WalletPaymentPending.amount}');
    print('[WalletOverview]   paymentMethod: ${WalletPaymentPending.paymentMethod}');

    if (state == AppLifecycleState.resumed && WalletPaymentPending.chargeId != null) {
      print('[WalletOverview] 🔙 App resumed with pending payment, checking status...');
      // User returned from payment - check if it succeeded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && WalletPaymentPending.chargeId != null) {
          _checkPendingPayment(
            WalletPaymentPending.chargeId!,
            WalletPaymentPending.amount!,
            WalletPaymentPending.paymentMethod ?? 'unknown',
          );
        }
      });
    }
  }

  Future<void> _checkPinSetup() async {
    final authService = Provider.of<WalletAuthService>(context, listen: false);

    // If PIN is not setup, prompt user to set it up
    if (!authService.hasPinSetup) {
      // Add a small delay to let the screen fully load
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PinSetupScreen(isFirstTimeSetup: true),
        ),
      );

      if (result == true) {
        Fluttertoast.showToast(
          msg: 'Wallet security enabled! Your wallet is now protected.',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        // User cancelled or failed PIN setup
        Fluttertoast.showToast(
          msg: 'PIN setup is required for wallet security',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletService>(
      builder: (context, walletService, child) {
        final wallet = walletService.wallet ?? Wallet();
        final recentTransactions = walletService.transactions.take(3).toList();

        return Scaffold(
          backgroundColor: ChongjaroenColors.primaryColors,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopActionBar(wallet),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: walletService.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                _buildCardBalanceHeader(wallet),
                                const SizedBox(height: 16),
                                _buildBillboard(walletService),
                                const SizedBox(height: 24),
                                _buildPointsRedeemSection(wallet),
                                const SizedBox(height: 24),
                                _buildRecentTransactions(recentTransactions),
                                const SizedBox(height: 24),
                                _buildBenefitsSection(),
                                const SizedBox(height: 24),
                              ],
                            ),
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

  Widget _buildTopActionBar(Wallet wallet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Header with title and security button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletSecurityScreen(),
                    ),
                  );
                },
                tooltip: 'Wallet Security',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTopAction(
                icon: Icons.account_balance_wallet,
                label: 'Add money',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopUpScreen(),
                    ),
                  ).then((_) {
                    // Refresh wallet after top-up
                    final walletService =
                        Provider.of<WalletService>(context, listen: false);
                    walletService.getBalance();
                    walletService.getTransactions(limit: 10);
                  });
                },
              ),
              _buildTopAction(
                icon: Icons.swap_horiz,
                label: 'Transfer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransferScreen(
                        availableBalance: wallet.balance,
                      ),
                    ),
                  );
                },
              ),
              _buildTopAction(
                icon: Icons.qr_code_scanner,
                label: 'Pay in store',
                onTap: () async {
                  // Require authentication before showing payment QR
                  final authService = Provider.of<WalletAuthService>(context, listen: false);

                  final authenticated = await authService.authenticate(
                    context: context,
                    reason: 'Authenticate to generate payment QR code',
                  );

                  if (authenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PayScreen(),
                      ),
                    );
                  } else {
                    Fluttertoast.showToast(
                      msg: 'Authentication required to generate payment QR',
                      backgroundColor: Colors.red,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ChongjaroenColors.primaryColors.shade700,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBalanceHeader(Wallet wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
              Text(
                '฿${_formatAmount(wallet.balance)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
        ],
      ),
    );
  }

  Widget _buildBillboard(WalletService walletService) {
    final settings = walletService.settings;
    final billboard = settings?.billboard;

    // If billboard is not enabled or no images, return empty container
    if (billboard == null || !billboard.enabled || billboard.images.isEmpty) {
      return const SizedBox.shrink();
    }

    final images = billboard.images;

    // Single image - display without carousel
    if (images.length == 1) {
      return _buildSingleBillboardImage(images[0]);
    }

    // Multiple images - use carousel
    return _buildBillboardCarousel(images, billboard.autoPlayInterval);
  }

  Widget _buildSingleBillboardImage(dynamic image) {
    final imageUrl = image.imageUrl;
    final linkUrl = image.linkUrl;

    return GestureDetector(
      onTap: linkUrl != null && linkUrl.isNotEmpty
          ? () => _openBillboardLink(linkUrl)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillboardCarousel(List<dynamic> images, int autoPlayInterval) {
    return StatefulBuilder(
      builder: (context, setState) {
        int currentIndex = 0;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 1.0,
                      autoPlay: true,
                      autoPlayInterval: Duration(milliseconds: autoPlayInterval),
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                    ),
                    items: images.map((image) {
                      return GestureDetector(
                        onTap: image.linkUrl != null && image.linkUrl.isNotEmpty
                            ? () => _openBillboardLink(image.linkUrl)
                            : null,
                        child: CachedNetworkImage(
                          imageUrl: image.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: currentIndex == entry.key ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: currentIndex == entry.key
                        ? ChongjaroenColors.secondaryColor
                        : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openBillboardLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildPointsRedeemSection(Wallet wallet) {
    final walletService = Provider.of<WalletService>(context, listen: false);
    final settings = walletService.settings;

    // Use API conversion rate (default: 1 point = 1 baht)
    final double conversionRate = settings != null
        ? wallet.points * settings.pointConversion.rate
        : wallet.points * 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ChongjaroenColors.secondaryColor.withOpacity(0.1),
            ChongjaroenColors.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ChongjaroenColors.secondaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ChongjaroenColors.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reward Points',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${wallet.points}',
                          style: const TextStyle(
                            color: ChongjaroenColors.secondaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'pts',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Redeem ${wallet.points} pts ≈ ฿${_formatAmount(conversionRate)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RedeemPointsScreen(
                      availablePoints: wallet.points,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ChongjaroenColors.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Redeem Points to Cash',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<WalletTransaction> recentTransactions) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: ChongjaroenColors.secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No transactions yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          )
        else
          ...recentTransactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final bool isPositive = transaction.amount >= 0;
    final String amountStr =
        '${isPositive ? '+' : ''}฿${_formatAmount(transaction.amount.abs())}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: isPositive ? Colors.green : Colors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.getTypeLabel(),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        amountStr,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(transaction.createdAt)}  •  ${_getTransactionSubtitle(transaction)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: ChongjaroenColors.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'YOUR BENEFIT(S)',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ChongjaroenColors.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: ChongjaroenColors.secondaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Free Upsize',
                          style: TextStyle(
                            color: ChongjaroenColors.secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ChongjaroenColors.secondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'x2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '*Apply your reward before check out!',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM y HH:mm').format(date);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date.toLocal());
  }

  String _getTransactionSubtitle(WalletTransaction transaction) {
    // For transfers, show customer name if available
    if (transaction.type == 'transfer' && transaction.customerName != null && transaction.customerName!.isNotEmpty) {
      return transaction.customerName!;
    }
    // Otherwise fall back to description or payment method
    return transaction.description ?? transaction.paymentMethod ?? '';
  }

  Future<void> _checkPendingPayment(String chargeId, double amount, String paymentMethod) async {
    print('[WalletOverview] 🔍 Checking pending payment...');
    print('[WalletOverview]   chargeId: $chargeId');
    print('[WalletOverview]   amount: $amount');
    print('[WalletOverview]   paymentMethod: $paymentMethod');

    // Show checking dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Checking payment status...'),
          ],
        ),
      ),
    );

    // Wait a moment for webhook to process
    await Future.delayed(const Duration(seconds: 2));

    // Refresh wallet data
    final walletService = Provider.of<WalletService>(context, listen: false);
    await walletService.getBalance();
    await walletService.getTransactions(limit: 10);

    if (!mounted) return;
    Navigator.pop(context); // Close checking dialog

    // Look for matching transaction
    final transactions = walletService.transactions;
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 5));

    final matchingTransaction = transactions.cast<WalletTransaction?>().firstWhere(
      (tx) {
        if (tx == null) return false;
        final txTime = DateTime.parse(tx.createdAt.toString()).toLocal();
        final isRecent = txTime.isAfter(cutoffTime);
        final isTopUp = tx.type == 'top_up';
        final amountMatches = (tx.amount - amount).abs() <= 0.01;

        print('[WalletOverview] Checking tx ${tx.id}: recent=$isRecent, topUp=$isTopUp, amountMatch=$amountMatches');
        return isRecent && isTopUp && amountMatches;
      },
      orElse: () => null,
    );

    if (matchingTransaction != null) {
      print('[WalletOverview] ✅ Payment confirmed! Showing success dialog');
      _showPaymentSuccessDialog(amount, paymentMethod);
      WalletPaymentPending.clearPendingPayment();
    } else {
      print('[WalletOverview] ⚠️ Payment not found in transactions');
      _showPaymentCheckDialog(chargeId, amount, paymentMethod);
    }
  }

  void _showPaymentCheckDialog(String chargeId, double amount, String paymentMethod) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Payment Status'),
          ],
        ),
        content: const Text(
          'Payment verification is taking longer than usual. Please check your transaction history in a moment.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              WalletPaymentPending.clearPendingPayment();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _checkPendingPayment(chargeId, amount, paymentMethod);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChongjaroenColors.secondaryColor,
            ),
            child: const Text(
              'Check Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccessDialog(double amount, String paymentMethod) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Your wallet has been topped up',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Payment Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '฿${NumberFormat('#,##0.00').format(amount)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),

                    // Payment Method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Method',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              paymentMethod == 'credit_card'
                                  ? Icons.credit_card
                                  : Icons.account_balance,
                              size: 18,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              paymentMethod == 'credit_card'
                                  ? 'Credit Card'
                                  : 'Mobile Banking',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close success dialog

                    // Refresh wallet data
                    final walletService = Provider.of<WalletService>(context, listen: false);
                    walletService.getBalance();
                    walletService.getTransactions(limit: 10);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChongjaroenColors.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}