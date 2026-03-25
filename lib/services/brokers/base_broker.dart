import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/order.dart';
import '../../models/symbol.dart';

class BrokerResponse {
  final bool success;
  final String? error;
  final dynamic data;
  
  BrokerResponse({required this.success, this.error, this.data});
}

abstract class BaseBroker {
  String get brokerId;
  String get brokerName;
  bool get isConnected;
  
  // Authentication
  Future<BrokerResponse> login(Map<String, dynamic> credentials);
  Future<BrokerResponse> logout();
  Future<BrokerResponse> refreshToken();
  
  // Market Data
  Future<BrokerResponse> getMarketData(String symbol);
  Future<BrokerResponse> getHistoricalData(String symbol, String interval, DateTime from, DateTime to);
  Future<void> subscribeRealtimeData(List<String> symbols, Function(Map<String, dynamic>) onData);
  Future<void> unsubscribeRealtimeData(List<String> symbols);
  
  // Orders
  Future<BrokerResponse> placeOrder(Order order);
  Future<BrokerResponse> modifyOrder(String orderId, {double? quantity, double? price, double? stopPrice});
  Future<BrokerResponse> cancelOrder(String orderId);
  Future<BrokerResponse> getOrders({OrderStatus? status});
  Future<BrokerResponse> getOrderDetails(String orderId);
  
  // Account
  Future<BrokerResponse> getAccountInfo();
  Future<BrokerResponse> getPositions();
  Future<BrokerResponse> getHoldings();
  Future<BrokerResponse> getMargin();
  
  // WebSocket management
  void disconnectWebSocket();
}

class BrokerConfig {
  final String apiKey;
  final String apiSecret;
  final String? accessToken;
  final String? refreshToken;
  final String baseUrl;
  final String wsUrl;
  final Map<String, String> headers;
  
  BrokerConfig({
    required this.apiKey,
    required this.apiSecret,
    this.accessToken,
    this.refreshToken,
    required this.baseUrl,
    required this.wsUrl,
    this.headers = const {},
  });
}




// lib/services/brokers/base_broker.dart (updated)
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/order.dart';
import '../../models/symbol.dart';
import '../secure_storage_service.dart';

abstract class BaseBroker {
  String get brokerId;
  String get brokerName;
  bool get isConnected;
  
  // Authentication
  Future<BrokerResponse> login(Map<String, dynamic> credentials);
  Future<BrokerResponse> logout();
  Future<BrokerResponse> refreshToken();
  
  // Token persistence
  Future<void> saveCredentials(Map<String, String> credentials);
  Future<Map<String, String>> loadCredentials();
  Future<bool> hasStoredCredentials();
  Future<void> clearCredentials();
  
  // Market Data
  Future<BrokerResponse> getMarketData(String symbol);
  Future<BrokerResponse> getHistoricalData(String symbol, String interval, DateTime from, DateTime to);
  Future<void> subscribeRealtimeData(List<String> symbols, Function(Map<String, dynamic>) onData);
  Future<void> unsubscribeRealtimeData(List<String> symbols);
  
  // Orders
  Future<BrokerResponse> placeOrder(Order order);
  Future<BrokerResponse> modifyOrder(String orderId, {double? quantity, double? price, double? stopPrice});
  Future<BrokerResponse> cancelOrder(String orderId);
  Future<BrokerResponse> getOrders({OrderStatus? status});
  Future<BrokerResponse> getOrderDetails(String orderId);
  
  // Account
  Future<BrokerResponse> getAccountInfo();
  Future<BrokerResponse> getPositions();
  Future<BrokerResponse> getHoldings();
  Future<BrokerResponse> getMargin();
  
  // WebSocket management
  void disconnectWebSocket();
}

class BrokerResponse {
  final bool success;
  final String? error;
  final dynamic data;
  
  BrokerResponse({required this.success, this.error, this.data});
}





// lib/services/brokers/base_broker.dart (Enhanced)
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/order.dart';
import '../../models/symbol.dart';
import '../secure_storage_service.dart';

abstract class BaseBroker {
  String get brokerId;
  String get brokerName;
  bool get isConnected;
  bool get needsTokenRefresh;
  
  // Authentication
  Future<BrokerResponse> login(Map<String, dynamic> credentials);
  Future<BrokerResponse> logout();
  Future<BrokerResponse> refreshToken();
  
  // Token Management
  Future<void> saveCredentials(Map<String, String> credentials);
  Future<Map<String, String>> loadCredentials();
  Future<bool> hasStoredCredentials();
  Future<void> clearCredentials();
  Future<void> scheduleTokenRefresh();
  Future<void> cancelTokenRefresh();
  
  // API Calls with Auto Refresh
  Future<BrokerResponse> authenticatedRequest(
    Future<BrokerResponse> Function() request,
    {int retries = 3}
  );
  
  // Market Data
  Future<BrokerResponse> getMarketData(String symbol);
  Future<BrokerResponse> getHistoricalData(String symbol, String interval, DateTime from, DateTime to);
  Future<void> subscribeRealtimeData(List<String> symbols, Function(Map<String, dynamic>) onData);
  Future<void> unsubscribeRealtimeData(List<String> symbols);
  
  // Orders
  Future<BrokerResponse> placeOrder(Order order);
  Future<BrokerResponse> modifyOrder(String orderId, {double? quantity, double? price, double? stopPrice});
  Future<BrokerResponse> cancelOrder(String orderId);
  Future<BrokerResponse> getOrders({OrderStatus? status});
  Future<BrokerResponse> getOrderDetails(String orderId);
  
  // Account
  Future<BrokerResponse> getAccountInfo();
  Future<BrokerResponse> getPositions();
  Future<BrokerResponse> getHoldings();
  Future<BrokerResponse> getMargin();
  
  // WebSocket
  void disconnectWebSocket();
  Future<void> reconnectWebSocket();
}

class BrokerResponse {
  final bool success;
  final String? error;
  final dynamic data;
  final int? statusCode;
  final bool requiresTokenRefresh;
  
  BrokerResponse({
    required this.success,
    this.error,
    this.data,
    this.statusCode,
    this.requiresTokenRefresh = false,
  });
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  @override
  String toString() => message;
}


