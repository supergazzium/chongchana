import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Manages secure wallet session state with automatic expiration
///
/// Features:
/// - 5-minute session validity after PIN/biometric authentication
/// - 60-second background timeout with automatic session expiration
/// - Lifecycle observation for app state changes
/// - Session state persistence across app restarts
class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Session constants
  static const Duration _sessionValidityDuration = Duration(minutes: 5);
  static const Duration _backgroundTimeoutDuration = Duration(seconds: 60);

  // SharedPreferences keys
  static const String _keyLastAuthTimestamp = 'wallet_last_auth_timestamp';
  static const String _keyBackgroundTimestamp = 'wallet_background_timestamp';

  // Session state
  DateTime? _lastAuthenticationTime;
  DateTime? _backgroundTime;
  Timer? _backgroundTimer;
  bool _isInitialized = false;

  // Listeners
  final List<VoidCallback> _sessionListeners = [];

  /// Initialize the session manager and start observing lifecycle
  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    await _loadSessionState();
    _isInitialized = true;
  }

  /// Clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _sessionListeners.clear();
  }

  /// Load session state from persistent storage
  Future<void> _loadSessionState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load last authentication timestamp
    final lastAuthMillis = prefs.getInt(_keyLastAuthTimestamp);
    if (lastAuthMillis != null) {
      _lastAuthenticationTime = DateTime.fromMillisecondsSinceEpoch(lastAuthMillis);
    }

    // Load background timestamp
    final backgroundMillis = prefs.getInt(_keyBackgroundTimestamp);
    if (backgroundMillis != null) {
      _backgroundTime = DateTime.fromMillisecondsSinceEpoch(backgroundMillis);

      // Check if we exceeded background timeout while app was closed
      final now = DateTime.now();
      if (_backgroundTime != null &&
          now.difference(_backgroundTime!) > _backgroundTimeoutDuration) {
        await expireSession();
      }
    }
  }

  /// Save session state to persistent storage
  Future<void> _saveSessionState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_lastAuthenticationTime != null) {
      await prefs.setInt(
        _keyLastAuthTimestamp,
        _lastAuthenticationTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_keyLastAuthTimestamp);
    }

    if (_backgroundTime != null) {
      await prefs.setInt(
        _keyBackgroundTimestamp,
        _backgroundTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_keyBackgroundTimestamp);
    }
  }

  /// Mark session as authenticated (user entered correct PIN or biometric)
  Future<void> authenticateSession() async {
    _lastAuthenticationTime = DateTime.now();
    await _saveSessionState();
    _notifyListeners();
  }

  /// Check if the current session is valid (not expired)
  bool isSessionValid() {
    if (_lastAuthenticationTime == null) return false;

    final now = DateTime.now();
    final timeSinceAuth = now.difference(_lastAuthenticationTime!);

    return timeSinceAuth < _sessionValidityDuration;
  }

  /// Expire the current session (requires re-authentication)
  Future<void> expireSession() async {
    _lastAuthenticationTime = null;
    _backgroundTime = null;
    await _saveSessionState();
    _notifyListeners();
  }

  /// Get time remaining in current session (if valid)
  Duration? getTimeRemaining() {
    if (!isSessionValid()) return null;

    final now = DateTime.now();
    final elapsed = now.difference(_lastAuthenticationTime!);
    final remaining = _sessionValidityDuration - elapsed;

    return remaining.isNegative ? null : remaining;
  }

  /// Add a listener for session state changes
  void addListener(VoidCallback listener) {
    _sessionListeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _sessionListeners.remove(listener);
  }

  /// Notify all listeners of session state change
  void _notifyListeners() {
    for (final listener in _sessionListeners) {
      listener();
    }
  }

  // WidgetsBindingObserver implementation for lifecycle events

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppBackground();
        break;
      case AppLifecycleState.resumed:
        _onAppForeground();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Handle app going to background
  void _onAppBackground() {
    _backgroundTime = DateTime.now();
    _saveSessionState();

    // Start background timeout timer
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(_backgroundTimeoutDuration, () {
      expireSession();
    });
  }

  /// Handle app coming to foreground
  void _onAppForeground() async {
    _backgroundTimer?.cancel();

    if (_backgroundTime != null) {
      final now = DateTime.now();
      final backgroundDuration = now.difference(_backgroundTime!);

      // If app was in background for more than timeout duration, expire session
      if (backgroundDuration > _backgroundTimeoutDuration) {
        await expireSession();
      }
    }

    _backgroundTime = null;
    await _saveSessionState();
  }

  /// Get formatted time remaining (for UI display)
  String getFormattedTimeRemaining() {
    final remaining = getTimeRemaining();
    if (remaining == null) return '0:00';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}