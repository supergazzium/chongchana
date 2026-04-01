import 'dart:async';
import 'package:chongchana/models/service_response.dart';
import 'package:chongchana/services/api/fetcher.dart';

Future<ServiceResponse> authenticateUser(
    String username, String password) async {
  late ServiceResponse resp;
  try {
    const path = "/auth/local";
    resp = await Fetcher.fetch(Fetcher.post, path, params: {
      'identifier': username,
      'password': password,
    }, useAccesstoken: false);
  } catch (e) {
    resp.setErrorObject({
      "statusCode": 400,
      "message": e.toString(),
    });
  }
  return resp;
}

/// Request OTP for PIN reset via phone or email
Future<ServiceResponse> apiRequestPinResetOTP(String method) async {
  late ServiceResponse resp;
  try {
    const path = "/wallet/pin/request-reset-otp";
    resp = await Fetcher.fetch(Fetcher.post, path, params: {
      'method': method, // 'phone' or 'email'
    }, useAccesstoken: true);
  } catch (e) {
    resp.setErrorObject({
      "statusCode": 400,
      "message": e.toString(),
    });
  }
  return resp;
}

/// Verify OTP for PIN reset
Future<ServiceResponse> apiVerifyPinResetOTP(String otp, String method) async {
  late ServiceResponse resp;
  try {
    const path = "/wallet/pin/verify-reset-otp";
    resp = await Fetcher.fetch(Fetcher.post, path, params: {
      'otp': otp,
      'method': method,
    }, useAccesstoken: true);
  } catch (e) {
    resp.setErrorObject({
      "statusCode": 400,
      "message": e.toString(),
    });
  }
  return resp;
}

/// Reset PIN with verified token
Future<ServiceResponse> apiResetPinWithToken(String resetToken, String newPin) async {
  late ServiceResponse resp;
  try {
    const path = "/wallet/pin/reset-with-token";
    resp = await Fetcher.fetch(Fetcher.post, path, params: {
      'resetToken': resetToken,
      'newPin': newPin,
    }, useAccesstoken: true);
  } catch (e) {
    resp.setErrorObject({
      "statusCode": 400,
      "message": e.toString(),
    });
  }
  return resp;
}
