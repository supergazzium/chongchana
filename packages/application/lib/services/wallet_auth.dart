import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:chongchana/services/session_manager.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/widgets/numeric_pin_keypad.dart';

enum AuthMethod {
  biometric,
  pin,
  none,
}

enum PinAuthLevel {
  always,       // PIN required for every transaction
  aboveAmount,  // PIN required only for transactions above threshold
  never,        // PIN disabled (not recommended)
}

class WalletAuthService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SessionManager _sessionManager = SessionManager();

  // Storage keys
  static const String _pinKey = 'wallet_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _hasPinSetupKey = 'has_pin_setup';
  static const String _pinAuthLevelKey = 'pin_auth_level';
  static const String _pinThresholdAmountKey = 'pin_threshold_amount';

  bool _isBiometricAvailable = false;
  List<local_auth.BiometricType> _availableBiometrics = [];
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = true; // Default to true for security
  bool _hasPinSetup = false;
  PinAuthLevel _pinAuthLevel = PinAuthLevel.always; // Default to always require PIN
  double _pinThresholdAmount = 300.0; // Default threshold for aboveAmount mode

  bool get isBiometricAvailable => _isBiometricAvailable;
  List<local_auth.BiometricType> get availableBiometrics => _availableBiometrics;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isPinEnabled => _isPinEnabled;
  bool get hasPinSetup => _hasPinSetup;
  bool get isAuthenticationRequired => _isPinEnabled || _isBiometricEnabled;
  PinAuthLevel get pinAuthLevel => _pinAuthLevel;
  double get pinThresholdAmount => _pinThresholdAmount;

  WalletAuthService() {
    _initialize();
  }

  /// Initialize the authentication service
  Future<void> _initialize() async {
    await _sessionManager.initialize();
    await checkBiometricAvailability();
    await _loadSettings();
  }

  /// Check if biometric authentication is available on the device
  Future<void> checkBiometricAvailability() async {
    try {
      _isBiometricAvailable = await _localAuth.canCheckBiometrics;

      if (_isBiometricAvailable) {
        final List<BiometricType> biometrics = await _localAuth.getAvailableBiometrics();
        _availableBiometrics = biometrics;
      }

      notifyListeners();
    } catch (e) {
      print('[WalletAuth] Error checking biometric availability: $e');
      _isBiometricAvailable = false;
      _availableBiometrics = [];
    }
  }

  /// Load authentication settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBiometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      _isPinEnabled = prefs.getBool(_pinEnabledKey) ?? true;
      _hasPinSetup = prefs.getBool(_hasPinSetupKey) ?? false;

      // Load PIN authorization level
      final authLevelIndex = prefs.getInt(_pinAuthLevelKey) ?? PinAuthLevel.always.index;
      _pinAuthLevel = PinAuthLevel.values[authLevelIndex];

      // Load PIN threshold amount
      _pinThresholdAmount = prefs.getDouble(_pinThresholdAmountKey) ?? 300.0;

      // If biometric is enabled but not available, disable it
      if (_isBiometricEnabled && !_isBiometricAvailable) {
        _isBiometricEnabled = false;
        await setBiometricEnabled(false);
      }

      notifyListeners();
    } catch (e) {
      print('[WalletAuth] Error loading settings: $e');
    }
  }

  /// Set up a new PIN
  Future<bool> setupPin(String pin) async {
    try {
      if (pin.length != 6) {
        throw Exception('PIN must be 6 digits');
      }

      await _secureStorage.write(key: _pinKey, value: pin);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPinSetupKey, true);
      await prefs.setBool(_pinEnabledKey, true);

      _hasPinSetup = true;
      _isPinEnabled = true;

      notifyListeners();
      return true;
    } catch (e) {
      print('[WalletAuth] Error setting up PIN: $e');
      return false;
    }
  }

  /// Verify if the provided PIN is correct
  Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      return storedPin == pin;
    } catch (e) {
      print('[WalletAuth] Error verifying PIN: $e');
      return false;
    }
  }

  /// Change the PIN (requires old PIN verification)
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final isOldPinCorrect = await verifyPin(oldPin);
      if (!isOldPinCorrect) {
        return false;
      }

      return await setupPin(newPin);
    } catch (e) {
      print('[WalletAuth] Error changing PIN: $e');
      return false;
    }
  }

  /// Authenticate using biometric (Face ID, Touch ID, Fingerprint)
  Future<bool> authenticateWithBiometric({
    String reason = 'Please authenticate to continue',
  }) async {
    if (!_isBiometricAvailable || !_isBiometricEnabled) {
      return false;
    }

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('[WalletAuth] Biometric authentication error: $e');
      return false;
    }
  }

  /// Main authentication method - tries biometric first, then falls back to PIN
  /// Checks session validity first to avoid re-authentication within 5 minutes
  Future<bool> authenticate({
    required BuildContext context,
    String reason = 'Authenticate to proceed with transaction',
    bool skipSessionCheck = false,
  }) async {
    // If no authentication is required, return true
    if (!isAuthenticationRequired) {
      return true;
    }

    // If PIN is not set up yet, require setup first
    if (!_hasPinSetup) {
      return false;
    }

    // Check if session is still valid (skip re-authentication)
    if (!skipSessionCheck && _sessionManager.isSessionValid()) {
      _showSessionActiveMessage(context);
      return true;
    }

    // Try biometric first if enabled and available
    if (_isBiometricEnabled && _isBiometricAvailable) {
      try {
        final biometricResult = await authenticateWithBiometric(reason: reason);
        if (biometricResult) {
          await _sessionManager.authenticateSession();
          return true;
        }
      } catch (e) {
        print('[WalletAuth] Biometric authentication failed: $e');
        // Fall through to PIN authentication
      }
    }

    // Fall back to PIN authentication
    if (_isPinEnabled) {
      final pinResult = await _showPinDialog(context, reason);
      if (pinResult) {
        await _sessionManager.authenticateSession();
      }
      return pinResult;
    }

    return false;
  }

  /// Show a message indicating the session is still active
  void _showSessionActiveMessage(BuildContext context) {
    final timeRemaining = _sessionManager.getFormattedTimeRemaining();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Secure Session Active ($timeRemaining remaining)',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: ChongjaroenColors.primaryColors,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show PIN entry dialog using custom numeric keypad
  Future<bool> _showPinDialog(BuildContext context, String reason) async {
    final enteredPin = await NumericPinKeypad.show(
      context: context,
      title: 'Enter PIN',
      subtitle: reason,
      obscureInput: true,
    );

    if (enteredPin == null) {
      return false; // User cancelled
    }

    // Verify the entered PIN
    final isCorrect = await verifyPin(enteredPin);

    if (!isCorrect && context.mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Incorrect PIN. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return isCorrect;
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled && !_isBiometricAvailable) {
      throw Exception('Biometric authentication is not available on this device');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  /// Enable or disable PIN authentication
  Future<void> setPinEnabled(bool enabled) async {
    if (enabled && !_hasPinSetup) {
      throw Exception('PIN must be set up first');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
    _isPinEnabled = enabled;
    notifyListeners();
  }

  /// Get a user-friendly name for available biometric type
  String getBiometricTypeName() {
    if (_availableBiometrics.isEmpty) {
      return 'None';
    }

    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    }

    return 'Biometric';
  }

  /// Set PIN authorization level (always, aboveAmount, never)
  Future<void> setPinAuthLevel(PinAuthLevel level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pinAuthLevelKey, level.index);
      _pinAuthLevel = level;
      notifyListeners();
    } catch (e) {
      print('[WalletAuth] Error setting PIN auth level: $e');
    }
  }

  /// Set PIN threshold amount for aboveAmount mode
  Future<void> setPinThresholdAmount(double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_pinThresholdAmountKey, amount);
      _pinThresholdAmount = amount;
      notifyListeners();
    } catch (e) {
      print('[WalletAuth] Error setting PIN threshold amount: $e');
    }
  }

  /// Check if PIN is required for a transaction based on authorization level and amount
  bool shouldRequirePin(double transactionAmount) {
    // If PIN is not set up, no authentication is possible
    if (!_hasPinSetup) {
      return false;
    }

    switch (_pinAuthLevel) {
      case PinAuthLevel.always:
        return true;
      case PinAuthLevel.aboveAmount:
        return transactionAmount > _pinThresholdAmount;
      case PinAuthLevel.never:
        return false;
    }
  }

  /// Reset all authentication settings (for security or troubleshooting)
  Future<void> resetAuthentication() async {
    try {
      await _secureStorage.delete(key: _pinKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_pinEnabledKey);
      await prefs.remove(_hasPinSetupKey);
      await prefs.remove(_pinAuthLevelKey);
      await prefs.remove(_pinThresholdAmountKey);

      _isBiometricEnabled = false;
      _isPinEnabled = false;
      _hasPinSetup = false;
      _pinAuthLevel = PinAuthLevel.always;
      _pinThresholdAmount = 300.0;

      notifyListeners();
    } catch (e) {
      print('[WalletAuth] Error resetting authentication: $e');
    }
  }
}