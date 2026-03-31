import 'package:chongchana/models/service_response.dart';
import 'package:chongchana/models/wallet.dart';
import 'package:chongchana/models/wallet_transaction.dart';
import 'package:chongchana/models/wallet_settings.dart';
import 'package:chongchana/services/api/fetcher.dart';
import 'package:flutter/material.dart';

class WalletService extends ChangeNotifier {
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  WalletSettings? _settings;
  bool _isLoading = false;
  String? _error;

  Wallet? get wallet => _wallet;
  List<WalletTransaction> get transactions => _transactions;
  WalletSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get wallet balance
  Future<Wallet?> getBalance() async {
    try {
      print('[WalletService] getBalance() called');

      // Check if user is authenticated
      final token = await Fetcher.chongjaroenAuth.getAccessToken();
      print('[WalletService] Token present: ${token != null}, Token length: ${token?.length ?? 0}');

      _isLoading = true;
      _error = null;
      notifyListeners();

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.get,
        '/wallet/balance',
      );

      print('[WalletService] getBalance response - isSuccess: ${response.isSuccess}');
      print('[WalletService] getBalance response - statusCode: ${response.statusCode}');
      print('[WalletService] getBalance response - data: ${response.data}');

      if (response.isSuccess) {
        final data = response.data['data'];
        print('[WalletService] getBalance data: $data');
        _wallet = Wallet(
          userId: data['userId'] ?? 0,
          balance: (data['balance'] is int)
              ? (data['balance'] as int).toDouble()
              : (data['balance'] ?? 0.0).toDouble(),
          pendingBalance: (data['pendingBalance'] is int)
              ? (data['pendingBalance'] as int).toDouble()
              : (data['pendingBalance'] ?? 0.0).toDouble(),
          frozenBalance: (data['frozenBalance'] is int)
              ? (data['frozenBalance'] as int).toDouble()
              : (data['frozenBalance'] ?? 0.0).toDouble(),
          totalBalance: (data['totalBalance'] is int)
              ? (data['totalBalance'] as int).toDouble()
              : (data['totalBalance'] ?? 0.0).toDouble(),
          currency: data['currency'] ?? 'THB',
          status: data['status'] ?? 'active',
          points: data['points'] ?? 0,
          lastTransaction: data['lastTransaction'] != null
              ? DateTime.parse(data['lastTransaction'])
              : null,
        );
        print('[WalletService] Wallet created: balance=${_wallet?.balance}, userId=${_wallet?.userId}');
        _isLoading = false;
        notifyListeners();
        return _wallet;
      } else {
        _error = response.errorMessage ?? 'Failed to fetch balance';
        print('[WalletService] getBalance error: $_error');
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] getBalance exception: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get transaction history
  Future<List<WalletTransaction>> getTransactions({
    int limit = 20,
    int offset = 0,
    String? type,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      print('[WalletService] getTransactions() called');
      _isLoading = true;
      _error = null;
      notifyListeners();

      Map<String, dynamic> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (type != null) params['type'] = type;
      if (status != null) params['status'] = status;
      if (fromDate != null) params['fromDate'] = fromDate;
      if (toDate != null) params['toDate'] = toDate;

      print('[WalletService] getTransactions params: $params');

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.get,
        '/wallet/transactions',
        params: params,
      );

      print('[WalletService] getTransactions response - isSuccess: ${response.isSuccess}');
      print('[WalletService] getTransactions response - statusCode: ${response.statusCode}');
      print('[WalletService] getTransactions response - data: ${response.data}');

      if (response.isSuccess) {
        final data = response.data['data'];
        final List<dynamic> transactionsData = data['transactions'] ?? [];
        print('[WalletService] getTransactions found ${transactionsData.length} transactions');

        _transactions = transactionsData.map((tx) {
          return WalletTransaction(
            id: tx['id'] ?? '',
            type: tx['type'] ?? 'unknown',
            amount: (tx['amount'] is int)
                ? (tx['amount'] as int).toDouble()
                : tx['amount'] ?? 0.0,
            balanceAfter: (tx['balanceAfter'] is int)
                ? (tx['balanceAfter'] as int).toDouble()
                : tx['balanceAfter'] ?? 0.0,
            balanceBefore: (tx['balanceBefore'] is int)
                ? (tx['balanceBefore'] as int).toDouble()
                : tx['balanceBefore'] ?? 0.0,
            status: tx['status'] ?? 'unknown',
            paymentMethod: tx['paymentMethod'],
            description: tx['description'],
            referenceId: tx['referenceId'],
            createdAt: tx['createdAt'] != null
                ? DateTime.parse(tx['createdAt'])
                : DateTime.now(),
          );
        }).toList();

        print('[WalletService] Transactions parsed: ${_transactions.length} items');
        _isLoading = false;
        notifyListeners();
        return _transactions;
      } else {
        _error = response.errorMessage ?? 'Failed to fetch transactions';
        print('[WalletService] getTransactions error: $_error');
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] getTransactions exception: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Make payment using wallet
  Future<Map<String, dynamic>?> makePayment({
    required double amount,
    required String referenceType,
    required String referenceId,
    String? branchId,
    String? description,
    int usePoints = 0,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/pay',
        params: {
          'amount': amount.toString(),
          'referenceType': referenceType,
          'referenceId': referenceId,
          if (branchId != null) 'branchId': branchId,
          if (description != null) 'description': description,
          'usePoints': usePoints.toString(),
        },
      );

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        return response.data['data'];
      } else {
        _error = response.errorMessage ?? 'Payment failed';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Redeem voucher
  Future<Map<String, dynamic>?> redeemVoucher(String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/voucher/redeem',
        params: {'code': code},
      );

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        return response.data['data'];
      } else {
        _error = response.errorMessage ?? 'Failed to redeem voucher';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get wallet settings (conversion rates, limits, fees)
  Future<WalletSettings?> getSettings() async {
    try {
      print('[WalletService] getSettings() called');

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.get,
        '/wallet/settings',
      );

      print('[WalletService] getSettings response - isSuccess: ${response.isSuccess}');
      print('[WalletService] getSettings response - statusCode: ${response.statusCode}');
      print('[WalletService] getSettings response - data: ${response.data}');

      if (response.isSuccess) {
        final data = response.data['data'];
        print('[WalletService] getSettings data: $data');
        _settings = WalletSettings.fromJson(data);
        print('[WalletService] Settings loaded: rate=${_settings?.pointConversion.rate}, minRedemption=${_settings?.pointConversion.minimumRedemption}');
        notifyListeners();
        return _settings;
      } else {
        _error = response.errorMessage ?? 'Failed to fetch settings';
        print('[WalletService] getSettings error: $_error');
        return null;
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] getSettings exception: $e');
      return null;
    }
  }

  /// Convert points to wallet credit
  Future<Map<String, dynamic>?> convertPoints(int points) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/points/convert',
        params: {'points': points.toString()},
      );

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        return response.data['data'];
      } else {
        _error = response.errorMessage ?? 'Failed to convert points';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Look up user by phone number for transfer
  Future<Map<String, dynamic>?> lookupUserByPhone(String phoneNumber) async {
    try {
      print('[WalletService] lookupUserByPhone() called');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/lookup-user',
        params: {'phoneNumber': phoneNumber},
      );

      print('[WalletService] lookupUserByPhone response - isSuccess: ${response.isSuccess}');
      print('[WalletService] lookupUserByPhone response - data: ${response.data}');

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        return response.data['data'];
      } else {
        _error = response.errorMessage ?? 'Failed to lookup user';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] lookupUserByPhone exception: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Transfer funds to another user
  /// Uses idempotency key to prevent double transfers
  Future<Map<String, dynamic>?> transferFunds({
    required int receiverUserId,
    required double amount,
    String? description,
  }) async {
    try {
      print('[WalletService] transferFunds() called');
      print('[WalletService]   receiverUserId: $receiverUserId');
      print('[WalletService]   amount: $amount');

      _isLoading = true;
      _error = null;
      notifyListeners();

      // Generate idempotency key to prevent double transfers
      final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}_${receiverUserId}_${amount}';

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/transfer',
        params: {
          'receiverUserId': receiverUserId.toString(),
          'amount': amount.toString(),
          'description': description ?? '',
          'idempotencyKey': idempotencyKey,
        },
      );

      print('[WalletService] transferFunds response - isSuccess: ${response.isSuccess}');
      print('[WalletService] transferFunds response - data: ${response.data}');

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        final data = response.data['data'];
        // Refresh wallet balance after successful transfer
        await getBalance();
        return data;
      } else {
        _error = response.errorMessage ?? 'Transfer failed';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] transferFunds exception: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Generate payment QR code for in-store payments
  /// Returns JWT token to be encoded in QR code
  Future<Map<String, dynamic>?> generatePaymentQR({
    String purpose = 'store_payment', // or 'beer_machine'
  }) async {
    try {
      print('[WalletService] generatePaymentQR() called');
      print('[WalletService]   purpose: $purpose');

      _isLoading = true;
      _error = null;
      notifyListeners();

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.post,
        '/wallet/payment-qr/generate',
        params: {
          'purpose': purpose,
        },
      );

      print('[WalletService] generatePaymentQR response - isSuccess: ${response.isSuccess}');
      print('[WalletService] generatePaymentQR response - data: ${response.data}');

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        return response.data['data'];
      } else {
        _error = response.errorMessage ?? 'Failed to generate payment QR';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] generatePaymentQR exception: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get payment QR history
  Future<List<dynamic>> getPaymentQRHistory({
    int page = 1,
    int limit = 20,
    String? type, // 'store_payment' or 'beer_machine_payment'
  }) async {
    try {
      print('[WalletService] getPaymentQRHistory() called');
      _isLoading = true;
      _error = null;
      notifyListeners();

      Map<String, dynamic> params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (type != null) params['type'] = type;

      final ServiceResponse response = await Fetcher.fetch(
        Fetcher.get,
        '/wallet/payment-qr/history',
        params: params,
      );

      print('[WalletService] getPaymentQRHistory response - isSuccess: ${response.isSuccess}');
      print('[WalletService] getPaymentQRHistory response - data: ${response.data}');

      _isLoading = false;
      notifyListeners();

      if (response.isSuccess) {
        final data = response.data['data'];
        return data['transactions'] ?? [];
      } else {
        _error = response.errorMessage ?? 'Failed to fetch payment history';
        return [];
      }
    } catch (e) {
      _error = e.toString();
      print('[WalletService] getPaymentQRHistory exception: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Clear all wallet data (called on logout)
  void clearWalletData() {
    _wallet = null;
    _transactions = [];
    _settings = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
