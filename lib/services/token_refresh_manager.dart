// lib/services/token_refresh_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'brokers/base_broker.dart';
import 'broker_manager.dart';

class TokenRefreshManager {
  static final TokenRefreshManager _instance = TokenRefreshManager._internal();
  factory TokenRefreshManager() => _instance;
  TokenRefreshManager._internal();
  
  Timer? _refreshTimer;
  final List<BaseBroker> _brokers = [];
  
  void initialize() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), _checkAndRefreshTokens);
  }
  
  void registerBroker(BaseBroker broker) {
    _brokers.add(broker);
  }
  
  void unregisterBroker(BaseBroker broker) {
    _brokers.remove(broker);
  }
  
  Future<void> _checkAndRefreshTokens(Timer timer) async {
    for (var broker in _brokers) {
      if (broker.isConnected && broker.needsTokenRefresh) {
        try {
          final response = await broker.refreshToken();
          if (!response.success) {
            debugPrint('Failed to refresh token for ${broker.brokerId}: ${response.error}');
            // Notify user that re-authentication is needed
            _notifyTokenExpired(broker);
          }
        } catch (e) {
          debugPrint('Error refreshing token for ${broker.brokerId}: $e');
        }
      }
    }
  }
  
  void _notifyTokenExpired(BaseBroker broker) {
    // You can implement a notification system here
    debugPrint('Token expired for ${broker.brokerName}. Please re-authenticate.');
  }
  
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _brokers.clear();
  }
}
