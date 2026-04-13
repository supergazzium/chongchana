import 'package:chongchana/constants/locales.dart';
import 'package:chongchana/models/service_response.dart';
import 'package:chongchana/services/api/user_profile.dart';
import 'package:flutter/widgets.dart';

import 'package:chongchana/services/api/authentication.dart';
import 'package:chongchana/models/user.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication service
class ChongjaroenAuth extends ChangeNotifier {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool _signedIn = false;
  bool _loadingFetchProfile = false;
  bool alreadyFetchProfile = false;
  late User user = User();

  bool get signedIn => _signedIn;
  bool get isSpecial => user.special;
  bool get loadingFetchProfile => _loadingFetchProfile;
  Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await _prefs;
    final token = prefs.getString("accessToken");

    // DEBUG: Print JWT token for testing
    if (token != null) {
      print('=' * 80);
      print('🔑 JWT TOKEN FOR TESTING:');
      print(token);
      print('=' * 80);
    }

    return token;
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await _prefs;
    _signedIn = false;
    user = User();
    prefs.remove("accessToken");
    prefs.remove("signedIn");
    notifyListeners();
  }

  Future<bool> accountDeleted() async {
    ServiceResponse resp = await accountDelete();
    if (resp.isSuccess) {
      signOut();
    }
    notifyListeners();
    return resp.isSuccess;
  }

  Future<ServiceResponse> signIn(String username, String password) async {
    final SharedPreferences prefs = await _prefs;
    ServiceResponse resp = await authenticateUser(username, password);
    if (resp.isSuccess) {
      user = User.fromJson({
        ...resp.data["user"],
        "userID": resp.data["user"]["id"],
        "accessToken": resp.data["jwt"],
      });

      _signedIn = true;
      prefs.setString("accessToken", user.accessToken);
    } else {
      _signedIn = false;
      prefs.remove("accessToken");

      if (resp.errorMessages.isNotEmpty) {
        String message = resp.errorMessages[0].message;
        if (resp.errorMessages[0].id == "Auth.form.error.invalid") {
          message = Locales.ErrorAuthticateFailed;
        }

        resp.setErrorObject({
          "statusCode": resp.statusCode,
          "message": message,
        });
      }
      // ignore: todo
      // TODO: Need to handle in case error
    }
    notifyListeners();
    return resp;
  }

  Future fetchProfile() async {
    _loadingFetchProfile = true;
    alreadyFetchProfile = true;

    ServiceResponse resp = await getUserProfile();
    if (resp.isSuccess) {
      user = User.fromJson({
        ...resp.data,
        "userID": resp.data["id"],
      });

      _signedIn = true;
      OneSignal.login("${user.userId}");
    } else {
      _signedIn = false;
      // prefs.remove("isSpecial");
      // prefs.setBool("signedIn", _signedIn);

      // ignore: todo
      // TODO: Need to handle in case error
    }
    _loadingFetchProfile = false;

    notifyListeners();
    return this;
  }

  /// Request OTP for PIN reset via phone or email
  Future<Map<String, dynamic>> requestPinResetOTP({
    required String method,
  }) async {
    try {
      ServiceResponse resp = await apiRequestPinResetOTP(method);

      if (resp.isSuccess) {
        return {
          'success': true,
          'maskedContact': resp.data['maskedContact'] ?? '',
          'message': resp.data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': resp.errorMessages.isNotEmpty
              ? resp.errorMessages[0].message
              : 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Verify OTP for PIN reset
  Future<Map<String, dynamic>> verifyPinResetOTP({
    required String otp,
    required String method,
  }) async {
    try {
      ServiceResponse resp = await apiVerifyPinResetOTP(otp, method);

      if (resp.isSuccess) {
        return {
          'success': true,
          'resetToken': resp.data['resetToken'] ?? '',
          'message': resp.data['message'] ?? 'OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': resp.errorMessages.isNotEmpty
              ? resp.errorMessages[0].message
              : 'Invalid OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Reset PIN with verified token
  Future<Map<String, dynamic>> resetPinWithToken({
    required String resetToken,
    required String newPin,
  }) async {
    try {
      ServiceResponse resp = await apiResetPinWithToken(resetToken, newPin);

      if (resp.isSuccess) {
        // PIN reset successful - update local storage to match backend
        // Import WalletAuthService to update the local PIN
        final storage = const FlutterSecureStorage();
        await storage.write(key: 'wallet_pin', value: newPin);

        // Also update the hasPinSetup flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_pin_setup', true);
        await prefs.setBool('pin_enabled', true);

        return {
          'success': true,
          'message': resp.data['message'] ?? 'PIN reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': resp.errorMessages.isNotEmpty
              ? resp.errorMessages[0].message
              : 'Failed to reset PIN',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}

class ChongjaroenAuthScope extends InheritedNotifier<ChongjaroenAuth> {
  const ChongjaroenAuthScope({
    required ChongjaroenAuth notifier,
    required Widget child,
    Key? key,
  }) : super(key: key, notifier: notifier, child: child);

  static ChongjaroenAuth of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ChongjaroenAuthScope>()!
      .notifier!;
}
