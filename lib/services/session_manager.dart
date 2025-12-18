import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session state enum
enum SessionState {
  locked,
  unlocked,
}

/// Session manager for handling auto-lock and session timeout
class SessionManager extends ChangeNotifier {
  SessionState _state = SessionState.locked;
  Timer? _timeoutTimer;
  DateTime? _lastActivityTime;
  int _timeoutMinutes = 5; // Default 5 minutes

  SessionState get state => _state;
  int get timeoutMinutes => _timeoutMinutes;
  DateTime? get lastActivityTime => _lastActivityTime;

  static const String _keyTimeoutMinutes = 'session_timeout_minutes';

  /// Initialize session manager and load preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _timeoutMinutes = prefs.getInt(_keyTimeoutMinutes) ?? 5;
  }

  /// Set timeout in minutes
  Future<void> setTimeoutMinutes(int minutes) async {
    if (minutes < 1 || minutes > 60) {
      throw ArgumentError('Timeout must be between 1 and 60 minutes');
    }
    _timeoutMinutes = minutes;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeoutMinutes, minutes);
    
    // Reset timer if unlocked
    if (_state == SessionState.unlocked) {
      _startTimeout();
    }
    
    notifyListeners();
  }

  /// Mark session as unlocked
  void unlock() {
    _state = SessionState.unlocked;
    _lastActivityTime = DateTime.now();
    _startTimeout();
    notifyListeners();
  }

  /// Mark session as locked
  void lock() {
    _state = SessionState.locked;
    _cancelTimeout();
    _lastActivityTime = null;
    notifyListeners();
  }

  /// Register user activity to reset timeout
  void recordActivity() {
    if (_state == SessionState.unlocked) {
      _lastActivityTime = DateTime.now();
      _startTimeout();
    }
  }

  /// Start or restart the timeout timer
  void _startTimeout() {
    _cancelTimeout();
    _timeoutTimer = Timer(Duration(minutes: _timeoutMinutes), () {
      lock();
    });
  }

  /// Cancel the timeout timer
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  void dispose() {
    _cancelTimeout();
    super.dispose();
  }
}

/// Global session manager instance
final sessionManager = SessionManager();
