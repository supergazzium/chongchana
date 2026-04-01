import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:chongchana/services/api/fetcher.dart';

/// Omise Payment Service for handling payment gateway operations
class OmisePaymentService extends ChangeNotifier {
  bool _isInitialized = true; // No SDK initialization needed on client side
  bool _isProcessing = false;
  String? _lastError;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;

  /// Initialize Omise (No-op as we handle everything via backend)
  Future<void> initialize() async {
    _isInitialized = true;
    _lastError = null;
    notifyListeners();
  }

  /// Create a token and process payment via backend
  /// Card information is sent directly to backend which creates the token securely
  Future<String?> createToken({
    required String cardNumber,
    required String cardHolderName,
    required String expirationMonth,
    required String expirationYear,
    required String securityCode,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Send card data to backend to create token securely
      // Backend will use Omise SDK to create token
      final serviceResponse = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/payment/create-token',
        params: {
          'cardNumber': cardNumber,
          'cardHolderName': cardHolderName,
          'expirationMonth': expirationMonth,
          'expirationYear': expirationYear,
          'securityCode': securityCode,
        },
      );

      _isProcessing = false;
      notifyListeners();

      if (serviceResponse.isSuccess && serviceResponse.data != null) {
        final data = serviceResponse.data['data'];
        if (data['success'] == true && data['tokenId'] != null) {
          return data['tokenId'];
        } else {
          // Handle error which can be String or Map
          final error = data['error'];
          if (error is String) {
            _lastError = error;
          } else if (error is Map) {
            _lastError = error['message']?.toString() ?? error.toString();
          } else {
            _lastError = 'Failed to create token';
          }
          return null;
        }
      } else {
        // Handle errorMessage which can be String or Map
        if (serviceResponse.errorMessage is String) {
          _lastError = serviceResponse.errorMessage as String;
        } else if (serviceResponse.errorMessage is Map) {
          final errorMap = serviceResponse.errorMessage as Map;
          _lastError = errorMap['message']?.toString() ?? errorMap.toString();
        } else {
          _lastError = 'Failed to create token';
        }
        return null;
      }
    } catch (e) {
      _lastError = 'Failed to create token: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Process payment for wallet top-up using credit card token
  /// Returns transaction ID if successful, null otherwise
  Future<Map<String, dynamic>?> processTopUpPayment({
    required double amount,
    required String currency,
    String? tokenId,
    String? sourceType,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Call backend API to create charge
      final serviceResponse = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/payment/create-charge',
        params: {
          'tokenId': tokenId,
          'amount': amount.toString(),
          'currency': currency,
        },
      );

      _isProcessing = false;
      notifyListeners();

      if (serviceResponse.isSuccess && serviceResponse.data != null) {
        final data = serviceResponse.data['data'];
        if (data['success'] == true) {
          return {
            'success': true,
            'transactionId': data['transactionId'],
            'chargeId': data['chargeId'],
            'amount': amount,
            'currency': currency,
            'status': data['status'],
            'paid': data['paid'],
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          // Handle failureMessage which can be String or null
          final failureMsg = data['failureMessage'];
          _lastError = failureMsg?.toString() ?? 'Payment failed';
          return null;
        }
      } else {
        // Handle errorMessage which can be String or Map
        if (serviceResponse.errorMessage is String) {
          _lastError = serviceResponse.errorMessage as String;
        } else if (serviceResponse.errorMessage is Map) {
          final errorMap = serviceResponse.errorMessage as Map;
          _lastError = errorMap['message']?.toString() ?? errorMap.toString();
        } else {
          _lastError = 'Payment failed';
        }
        return null;
      }
    } catch (e) {
      _lastError = 'Payment processing failed: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Create a charge for Internet Banking payment
  Future<Map<String, dynamic>?> createInternetBankingCharge({
    required double amount,
    required String currency,
    required String paymentMethod, // e.g., 'mobile_banking_bbl', 'mobile_banking_kbank'
    String? returnUri,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Detect platform for Omise optimization
      String platformType = Platform.isIOS ? 'IOS' : 'ANDROID';

      print('[OmisePaymentService] Creating internet banking charge:');
      print('[OmisePaymentService]   amount: $amount');
      print('[OmisePaymentService]   currency: $currency');
      print('[OmisePaymentService]   paymentMethod: $paymentMethod');
      print('[OmisePaymentService]   platformType: $platformType');
      print('[OmisePaymentService]   returnUri: ${returnUri ?? 'chongjaroen://payment-result'}');

      // Call backend API to create payment source and charge
      final serviceResponse = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/payment/create-source',
        params: {
          'amount': amount.toString(), // Backend handles conversion to satangs
          'currency': currency,
          'paymentMethod': paymentMethod,
          'platformType': platformType,
          'returnUri': returnUri ?? 'chongjaroen://payment-result',
        },
      );

      print('[OmisePaymentService] Backend response:');
      print('[OmisePaymentService]   isSuccess: ${serviceResponse.isSuccess}');
      print('[OmisePaymentService]   statusCode: ${serviceResponse.statusCode}');
      print('[OmisePaymentService]   data: ${serviceResponse.data}');

      _isProcessing = false;
      notifyListeners();

      if (serviceResponse.isSuccess && serviceResponse.data != null) {
        final data = serviceResponse.data['data'];
        if (data['success'] == true) {
          return {
            'success': true,
            'chargeId': data['chargeId'],
            'sourceId': data['sourceId'],
            'amount': amount,
            'currency': currency,
            'status': data['status'],
            'authorizeUri': data['authorizeUri'],
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          _lastError = 'Failed to create payment source';
          return null;
        }
      } else {
        // Handle errorMessage which can be String or Map
        if (serviceResponse.errorMessage is String) {
          _lastError = serviceResponse.errorMessage as String;
        } else if (serviceResponse.errorMessage is Map) {
          final errorMap = serviceResponse.errorMessage as Map;
          _lastError = errorMap['message']?.toString() ?? errorMap.toString();
        } else {
          _lastError = 'Failed to create payment source';
        }
        return null;
      }
    } catch (e) {
      _lastError = 'Failed to create charge: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Create a source for PromptPay payment
  Future<Map<String, dynamic>?> createPromptPaySource({
    required double amount,
    required String currency,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      print('[OmisePaymentService] Creating PromptPay source for amount: $amount, currency: $currency');

      // Call backend API to create PromptPay source
      final serviceResponse = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/payment/create-source',
        params: {
          'amount': amount.toString(),
          'currency': currency,
          'paymentMethod': 'promptpay',
        },
      );

      print('[OmisePaymentService] serviceResponse.isSuccess: ${serviceResponse.isSuccess}');
      print('[OmisePaymentService] serviceResponse.data: ${serviceResponse.data}');
      print('[OmisePaymentService] serviceResponse.errorMessage: ${serviceResponse.errorMessage}');
      print('[OmisePaymentService] serviceResponse.statusCode: ${serviceResponse.statusCode}');

      _isProcessing = false;
      notifyListeners();

      if (serviceResponse.isSuccess && serviceResponse.data != null) {
        final data = serviceResponse.data['data'];
        print('[OmisePaymentService] Extracted data: $data');

        if (data != null && data['success'] == true) {
          print('[OmisePaymentService] PromptPay source created successfully');
          return {
            'success': true,
            'chargeId': data['chargeId'],
            'sourceId': data['sourceId'],
            'amount': amount,
            'currency': currency,
            'type': 'promptpay',
            'status': data['status'],
            'scannableCode': data['scannableCode'],
            'expiresAt': data['expiresAt'],
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          print('[OmisePaymentService] ERROR: data is null or success is false');
          _lastError = 'Failed to create PromptPay source';
          return null;
        }
      } else {
        print('[OmisePaymentService] ERROR: serviceResponse is not successful or data is null');
        // Handle error message which can be a String or Map
        if (serviceResponse.errorMessage is String) {
          _lastError = serviceResponse.errorMessage as String;
        } else if (serviceResponse.errorMessage is Map) {
          final errorMap = serviceResponse.errorMessage as Map;
          _lastError = errorMap['message']?.toString() ?? errorMap.toString();
        } else {
          _lastError = 'Failed to create PromptPay source';
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('[OmisePaymentService] EXCEPTION: $e');
      print('[OmisePaymentService] Stack trace: $stackTrace');
      _lastError = 'Failed to create PromptPay source: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  /// Verify payment status
  /// Query backend to check the payment status
  Future<bool> verifyPayment(String chargeId) async {
    print('[OmisePayment] verifyPayment called for chargeId: $chargeId');
    _isProcessing = true;
    notifyListeners();

    try {
      print('[OmisePayment] Calling backend API: /wallet/payment/status/$chargeId');

      // Call backend API to check payment status
      final serviceResponse = await Fetcher.fetch(
        Fetcher.get,
        '/wallet/payment/status/$chargeId',
      );

      print('[OmisePayment] API response received:');
      print('[OmisePayment]   isSuccess: ${serviceResponse.isSuccess}');
      print('[OmisePayment]   data: ${serviceResponse.data}');

      _isProcessing = false;
      notifyListeners();

      if (serviceResponse.isSuccess && serviceResponse.data != null) {
        final data = serviceResponse.data['data'];
        print('[OmisePayment]   data[\'data\']: $data');

        if (data != null && data['paid'] == true) {
          print('[OmisePayment] Payment is PAID! Returning true');
          return true;
        } else {
          print('[OmisePayment] Payment not paid yet. paid=${data?['paid']}, status=${data?['status']}');
        }
      }

      print('[OmisePayment] Returning false');
      return false;
    } catch (e) {
      print('[OmisePayment] ERROR in verifyPayment: $e');
      _lastError = 'Payment verification failed: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear the last error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Reset the service state
  void reset() {
    _isProcessing = false;
    _lastError = null;
    notifyListeners();
  }
}