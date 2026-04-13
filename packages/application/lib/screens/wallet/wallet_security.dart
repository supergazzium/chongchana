import 'package:chongchana/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:chongchana/screens/wallet/pin_setup.dart';
import 'package:chongchana/screens/wallet/forgot_pin.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' as math;

class WalletSecurityScreen extends StatefulWidget {
  const WalletSecurityScreen({Key? key}) : super(key: key);

  @override
  _WalletSecurityScreenState createState() => _WalletSecurityScreenState();
}

class _WalletSecurityScreenState extends State<WalletSecurityScreen> {

  void _changePin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(isFirstTimeSetup: false),
      ),
    );

    if (result == true) {
      Fluttertoast.showToast(
        msg: 'PIN changed successfully',
        backgroundColor: Colors.green,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Topological background
          Positioned(
            top: -80,
            right: -60,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ChongjaroenColors.secondaryColors.withOpacity(0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ChongjaroenColors.primaryColors.withOpacity(0.06),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Topology-styled app bar
              Container(
                decoration: BoxDecoration(
                  color: ChongjaroenColors.primaryColors,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      // Topology circles
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                ChongjaroenColors.secondaryColors.withOpacity(0.2),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -15,
                        left: 20,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ChongjaroenColors.primaryColors.shade700,
                          ),
                        ),
                      ),

                      // App bar content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Wallet Security',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPaymentAuthorization(),
                      const SizedBox(height: 12),
                      _buildAuthenticationMethod(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAuthorization() {
    return Consumer<WalletAuthService>(
      builder: (context, authService, child) {
        return _buildSection(
          icon: Icons.lock_outline,
          title: 'PIN Authorization',
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildAuthLevelOption(
                icon: Icons.verified_user,
                label: 'Always',
                subtitle: 'PIN required for every transaction',
                level: PinAuthLevel.always,
                authService: authService,
              ),
              const SizedBox(height: 8),
              _buildAuthLevelOption(
                icon: Icons.account_balance_wallet,
                label: 'Above ฿${_formatAmount(authService.pinThresholdAmount)}',
                subtitle: 'PIN required for high-value transactions',
                level: PinAuthLevel.aboveAmount,
                authService: authService,
              ),
              const SizedBox(height: 8),
              _buildAuthLevelOption(
                icon: Icons.lock_open,
                label: 'Never',
                subtitle: 'Security disabled',
                level: PinAuthLevel.never,
                authService: authService,
                showWarning: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthenticationMethod() {
    return Consumer<WalletAuthService>(
      builder: (context, authService, child) {
        return _buildSection(
          icon: Icons.fingerprint,
          title: 'Authentication',
          child: Column(
            children: [
              const SizedBox(height: 12),
              if (authService.isBiometricAvailable)
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  title: authService.getBiometricTypeName(),
                  value: authService.isBiometricEnabled,
                  onChanged: (value) async {
                    try {
                      await authService.setBiometricEnabled(value);
                      Fluttertoast.showToast(
                        msg: value ? 'Biometric enabled' : 'Biometric disabled',
                        backgroundColor: Colors.green,
                      );
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: 'Update failed',
                        backgroundColor: Colors.red,
                      );
                    }
                  },
                ),
              if (authService.isBiometricAvailable) const SizedBox(height: 8),
              _buildSwitchTile(
                icon: Icons.dialpad,
                title: '6-digit PIN',
                value: authService.isPinEnabled && authService.hasPinSetup,
                onChanged: authService.hasPinSetup
                    ? (value) async {
                        try {
                          await authService.setPinEnabled(value);
                          Fluttertoast.showToast(
                            msg: value ? 'PIN enabled' : 'PIN disabled',
                            backgroundColor: Colors.green,
                          );
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: 'Update failed',
                            backgroundColor: Colors.red,
                          );
                        }
                      }
                    : null,
              ),
              if (!authService.hasPinSetup) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Setup PIN for security',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _changePin,
                      icon: Icon(
                        authService.hasPinSetup ? Icons.edit : Icons.add,
                        size: 18,
                      ),
                      label: Text(
                        authService.hasPinSetup ? 'Change PIN' : 'Setup PIN',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChongjaroenColors.primaryColors,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              if (authService.hasPinSetup) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPinScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Forgot PIN?'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ChongjaroenColors.secondaryColors,
                    side: BorderSide(color: ChongjaroenColors.secondaryColors),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await authService.resetAuthentication();
                  Fluttertoast.showToast(
                    msg: 'Authentication reset',
                    backgroundColor: Colors.orange,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('🔧 Reset'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ChongjaroenColors.primaryColors.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: ChongjaroenColors.primaryColors,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAuthLevelOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required PinAuthLevel level,
    required WalletAuthService authService,
    bool showWarning = false,
  }) {
    final isSelected = authService.pinAuthLevel == level;
    // Starbucks color: Deep Green #006241
    final deepGreen = const Color(0xFF006241);
    final lightRed = Colors.red.shade50;
    final warningRed = Colors.red.shade400;

    return GestureDetector(
      onTap: () async {
        // Auto-save: update immediately without Save button
        await authService.setPinAuthLevel(level);

        // Show brief haptic-like snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Setting Updated'),
                ],
              ),
              backgroundColor: deepGreen,
              duration: const Duration(milliseconds: 1200),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Pure white background with high negative space
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? deepGreen : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: deepGreen.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? deepGreen.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? deepGreen : Colors.grey[600],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? deepGreen : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? deepGreen : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? deepGreen : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
          ),
          // Show "Not Recommended" warning for "Never" option
          if (showWarning && isSelected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: lightRed,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: warningRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: warningRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Not Recommended - Your wallet is unprotected',
                      style: TextStyle(
                        fontSize: 12,
                        color: warningRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? ChongjaroenColors.primaryColors : Colors.grey[600],
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ChongjaroenColors.primaryColors,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}

// Login History Screen
class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginHistory = [
      {
        'date': DateTime(2025, 3, 8, 14, 30),
        'device': 'iPhone 13 Pro',
        'location': 'Bangkok, Thailand',
        'ip': '103.xx.xx.xx',
      },
      {
        'date': DateTime(2025, 3, 7, 18, 15),
        'device': 'iPhone 13 Pro',
        'location': 'Bangkok, Thailand',
        'ip': '103.xx.xx.xx',
      },
      {
        'date': DateTime(2025, 3, 6, 12, 0),
        'device': 'iPhone 13 Pro',
        'location': 'Bangkok, Thailand',
        'ip': '103.xx.xx.xx',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ChongjaroenColors.primaryColors,
        title: const Text(
          'Login History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loginHistory.length,
        itemBuilder: (context, index) {
          final login = loginHistory[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy, HH:mm').format(login['date'] as DateTime),
                  style: TextStyle(
                    color: ChongjaroenColors.primaryColors,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildHistoryRow(Icons.phone_android, login['device'] as String),
                const SizedBox(height: 4),
                _buildHistoryRow(Icons.location_on, login['location'] as String),
                const SizedBox(height: 4),
                _buildHistoryRow(Icons.dns, login['ip'] as String),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }
}