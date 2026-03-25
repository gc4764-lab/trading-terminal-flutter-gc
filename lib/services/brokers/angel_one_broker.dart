import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';

class AngelOneBroker extends BaseBroker {
  final String _brokerId = 'angel_one';
  final String _brokerName = 'Angel One';
  bool _isConnected = false;
  Dio? _dio;
  WebSocketChannel? _wsChannel;
  String? _jwtToken;
  String? _clientId;
  Map<String, Function(Map<String, dynamic>)> _subscribers = {};
  
  @override
  String get brokerId => _brokerId;
  
  @override
  String get brokerName => _brokerName;
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Future<BrokerResponse> login(Map<String, dynamic> credentials) async {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: 'https://apiconnect.angelone.in',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-ClientLocalIP': '127.0.0.1',
          'X-ClientPublicIP': '127.0.0.1',
          'X-MACAddress': '00:00:00:00:00:00',
          'X-PrivateKey': credentials['apiKey'],
        },
      ));
      
      final response = await _dio!.post('/rest/auth/angelbroking/user/v1/loginByPassword', data: {
        'clientcode': credentials['clientId'],
        'password': credentials['password'],
        'totp': credentials['totp'] ?? '',
      });
      
      if (response.statusCode == 200 && response.data['status']) {
        _jwtToken = response.data['data']['jwtToken'];
        _clientId = credentials['clientId'];
        _isConnected = true;
        
        // Initialize WebSocket
        _initWebSocket();
        
        return BrokerResponse(
          success: true,
          data: {
            'jwt_token': _jwtToken,
            'client_id': _clientId,
          },
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  void _initWebSocket() {
    _wsChannel = IOWebSocketChannel.connect(
      'wss://wsfeeds.angelone.in/NestHtml5Mobile/socket/stream/$_jwtToken/$_clientId',
    );
    
    _wsChannel!.stream.listen(
      (data) {
        _handleWebSocketMessage(data);
      },
      onError: (error) {
        print('Angel One WebSocket error: $error');
      },
    );
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final symbol = message['token'];
      
      if (_subscribers.containsKey(symbol)) {
        _subscribers[symbol]!(message);
      }
    } catch (e) {
      print('Error parsing Angel One message: $e');
    }
  }
  
  @override
  Future<BrokerResponse> logout() async {
    _isConnected = false;
    _jwtToken = null;
    _clientId = null;
    disconnectWebSocket();
    _dio = null;
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> refreshToken() async {
    // Angel One token refresh
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/order/v1/getQuote',
        queryParameters: {'symbol': symbol},
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(
          success: true,
          data: response.data['data'],
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'],
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getHistoricalData(
    String symbol,
    String interval,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/order/v1/getCandleData',
        queryParameters: {
          'symbol': symbol,
          'interval': interval,
          'fromdate': from.toIso8601String(),
          'todate': to.toIso8601String(),
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(
          success: true,
          data: response.data['data'],
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'],
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<void> subscribeRealtimeData(
    List<String> symbols,
    Function(Map<String, dynamic>) onData,
  ) async {
    for (var symbol in symbols) {
      _subscribers[symbol] = onData;
    }
    
    // Send subscription via WebSocket
    final subscription = jsonEncode({
      'action': 'subscribe',
      'tokens': symbols,
    });
    
    _wsChannel?.sink.add(subscription);
  }
  
  @override
  Future<void> unsubscribeRealtimeData(List<String> symbols) async {
    for (var symbol in symbols) {
      _subscribers.remove(symbol);
    }
    
    final unsubscription = jsonEncode({
      'action': 'unsubscribe',
      'tokens': symbols,
    });
    
    _wsChannel?.sink.add(unsubscription);
  }
  
  @override
  Future<BrokerResponse> placeOrder(Order order) async {
    try {
      final orderData = {
        'variety': 'NORMAL',
        'trading_symbol': order.symbol,
        'transaction_type': order.side == OrderSide.buy ? 'BUY' : 'SELL',
        'exchange': 'NSE',
        'order_type': _getOrderType(order.type),
        'quantity': order.quantity.toInt(),
        'price': order.price?.toString() ?? '0',
        'trigger_price': order.stopPrice?.toString() ?? '0',
        'product_type': 'INTRADAY',
        'duration': 'DAY',
      };
      
      final response = await _dio!.post(
        '/rest/secure/angelbroking/order/v1/placeOrder',
        data: orderData,
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(
          success: true,
          data: response.data['data'],
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'],
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  String _getOrderType(OrderType type) {
    switch (type) {
      case OrderType.market:
        return 'MARKET';
      case OrderType.limit:
        return 'LIMIT';
      case OrderType.stop:
        return 'STOP';
      case OrderType.stopLimit:
        return 'STOP_LOSS_LIMIT';
      default:
        return 'MARKET';
    }
  }
  
  @override
  Future<BrokerResponse> modifyOrder(
    String orderId, {
    double? quantity,
    double? price,
    double? stopPrice,
  }) async {
    try {
      final modifyData = {
        'variety': 'NORMAL',
        'order_id': orderId,
        if (quantity != null) 'quantity': quantity.toInt(),
        if (price != null) 'price': price.toString(),
        if (stopPrice != null) 'trigger_price': stopPrice.toString(),
      };
      
      final response = await _dio!.put(
        '/rest/secure/angelbroking/order/v1/modifyOrder',
        data: modifyData,
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> cancelOrder(String orderId) async {
    try {
      final response = await _dio!.delete(
        '/rest/secure/angelbroking/order/v1/cancelOrder',
        data: {'order_id': orderId},
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getOrders({OrderStatus? status}) async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/order/v1/getOrderBook',
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getOrderDetails(String orderId) async {
    // Angel One specific implementation
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getAccountInfo() async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/user/v1/getProfile',
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getPositions() async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/order/v1/getPosition',
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getHoldings() async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/portfolio/v1/getHolding',
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getMargin() async {
    try {
      final response = await _dio!.get(
        '/rest/secure/angelbroking/user/v1/getRMS',
        options: Options(
          headers: {'Authorization': 'Bearer $_jwtToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['status']) {
        return BrokerResponse(success: true, data: response.data['data']);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _subscribers.clear();
  }
}






// lib/services/brokers/angel_one_broker.dart (Enhanced with Token Refresh)
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';
import '../secure_storage_service.dart';

class AngelOneBroker extends BaseBroker {
  final String _brokerId = 'angel_one';
  final String _brokerName = 'Angel One';
  bool _isConnected = false;
  Dio? _dio;
  WebSocketChannel? _wsChannel;
  String? _jwtToken;
  String? _refreshToken;
  String? _clientId;
  DateTime? _tokenExpiry;
  Timer? _refreshTimer;
  Map<String, Function(Map<String, dynamic>)> _subscribers = {};
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // API Endpoints
  static const String _baseUrl = 'https://apiconnect.angelone.in';
  static const String _authUrl = '/rest/auth/angelbroking/user/v1/loginByPassword';
  static const String _refreshUrl = '/rest/auth/angelbroking/user/v1/refresh';
  static const String _wsUrl = 'wss://wsfeeds.angelone.in/NestHtml5Mobile/socket/stream';
  
  @override
  String get brokerId => _brokerId;
  
  @override
  String get brokerName => _brokerName;
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  bool get needsTokenRefresh => _tokenExpiry != null && 
      DateTime.now().isAfter(_tokenExpiry!.subtract(const Duration(minutes: 10)));
  
  @override
  Future<void> saveCredentials(Map<String, String> credentials) async {
    await _secureStorage.saveBrokerCredentials(_brokerId, credentials);
  }
  
  @override
  Future<Map<String, String>> loadCredentials() async {
    return await _secureStorage.getBrokerCredentials(_brokerId);
  }
  
  @override
  Future<bool> hasStoredCredentials() async {
    return await _secureStorage.isBrokerConnected(_brokerId);
  }
  
  @override
  Future<void> clearCredentials() async {
    await _secureStorage.removeBrokerCredentials(_brokerId);
  }
  
  @override
  Future<BrokerResponse> login(Map<String, dynamic> credentials) async {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-ClientLocalIP': '127.0.0.1',
          'X-ClientPublicIP': '127.0.0.1',
          'X-MACAddress': '00:00:00:00:00:00',
          'X-PrivateKey': credentials['apiKey'],
        },
      ));
      
      final response = await _dio!.post(_authUrl, data: {
        'clientcode': credentials['clientId'],
        'password': credentials['password'],
        'totp': credentials['totp'] ?? '',
      });
      
      if (response.statusCode == 200 && response.data['status']) {
        _jwtToken = response.data['data']['jwtToken'];
        _refreshToken = response.data['data']['refreshToken'];
        _clientId = credentials['clientId'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 24));
        _isConnected = true;
        
        // Save credentials
        await saveCredentials({
          'apiKey': credentials['apiKey'],
          'clientId': credentials['clientId'],
          'jwtToken': _jwtToken!,
          'refreshToken': _refreshToken!,
          'tokenExpiry': _tokenExpiry!.toIso8601String(),
        });
        
        // Initialize Dio with auth header
        _dio!.options.headers['Authorization'] = 'Bearer $_jwtToken';
        
        // Initialize WebSocket
        await _initWebSocket();
        
        // Schedule token refresh
        await scheduleTokenRefresh();
        
        return BrokerResponse(
          success: true,
          data: {
            'jwtToken': _jwtToken,
            'refreshToken': _refreshToken,
            'clientId': _clientId,
          },
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return BrokerResponse(
        success: false,
        error: _handleDioError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> refreshToken() async {
    if (_refreshToken == null || _clientId == null) {
      return BrokerResponse(
        success: false,
        error: 'No refresh token available',
        requiresTokenRefresh: true,
      );
    }
    
    try {
      final response = await _dio!.post(_refreshUrl, data: {
        'clientcode': _clientId,
        'refreshToken': _refreshToken,
      });
      
      if (response.statusCode == 200 && response.data['status']) {
        _jwtToken = response.data['data']['jwtToken'];
        _refreshToken = response.data['data']['refreshToken'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 24));
        
        // Update stored credentials
        final creds = await loadCredentials();
        creds['jwtToken'] = _jwtToken!;
        creds['refreshToken'] = _refreshToken!;
        creds['tokenExpiry'] = _tokenExpiry!.toIso8601String();
        await saveCredentials(creds);
        
        // Update Dio headers
        _dio!.options.headers['Authorization'] = 'Bearer $_jwtToken';
        
        // Reconnect WebSocket
        await reconnectWebSocket();
        
        return BrokerResponse(success: true, data: {
          'jwtToken': _jwtToken,
          'refreshToken': _refreshToken,
        });
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'] ?? 'Token refresh failed',
          requiresTokenRefresh: true,
        );
      }
    } on DioException catch (e) {
      return BrokerResponse(
        success: false,
        error: _handleDioError(e),
        requiresTokenRefresh: true,
      );
    } catch (e) {
      return BrokerResponse(
        success: false,
        error: e.toString(),
        requiresTokenRefresh: true,
      );
    }
  }
  
  @override
  Future<void> scheduleTokenRefresh() async {
    if (_tokenExpiry == null) return;
    
    cancelTokenRefresh();
    
    final refreshTime = _tokenExpiry!.subtract(const Duration(minutes: 10));
    final delay = refreshTime.difference(DateTime.now());
    
    if (delay.isNegative) {
      await refreshToken();
    } else {
      _refreshTimer = Timer(delay, () async {
        await refreshToken();
      });
    }
  }
  
  @override
  void cancelTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  @override
  Future<BrokerResponse> authenticatedRequest(
    Future<BrokerResponse> Function() request,
    {int retries = 3}
  ) async {
    for (var i = 0; i < retries; i++) {
      try {
        final response = await request();
        
        if (response.requiresTokenRefresh || 
            (response.statusCode == 401 && response.error?.contains('token') == true)) {
          final refreshResponse = await refreshToken();
          if (refreshResponse.success) {
            continue;
          } else {
            return BrokerResponse(
              success: false,
              error: 'Authentication failed. Please login again.',
            );
          }
        }
        
        return response;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 && i < retries - 1) {
          final refreshResponse = await refreshToken();
          if (refreshResponse.success) {
            continue;
          }
        }
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      } catch (e) {
        if (i == retries - 1) {
          return BrokerResponse(success: false, error: e.toString());
        }
      }
    }
    
    return BrokerResponse(success: false, error: 'Max retries exceeded');
  }
  
  Future<void> restoreSession() async {
    final creds = await loadCredentials();
    if (creds.isNotEmpty && creds.containsKey('jwtToken')) {
      _jwtToken = creds['jwtToken'];
      _refreshToken = creds['refreshToken'];
      _clientId = creds['clientId'];
      
      if (creds.containsKey('tokenExpiry')) {
        _tokenExpiry = DateTime.parse(creds['tokenExpiry']!);
      }
      
      // Initialize Dio
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-PrivateKey': creds['apiKey'],
        },
      ));
      
      // Check if token needs refresh
      if (needsTokenRefresh) {
        await refreshToken();
      }
      
      _isConnected = true;
      
      // Initialize WebSocket
      await _initWebSocket();
      
      // Schedule next refresh
      await scheduleTokenRefresh();
    }
  }
  
  Future<void> _initWebSocket() async {
    if (_jwtToken == null || _clientId == null) return;
    
    try {
      _wsChannel = IOWebSocketChannel.connect(
        '$_wsUrl/$_jwtToken/$_clientId',
      );
      
      _wsChannel!.stream.listen(
        (data) {
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          print('Angel One WebSocket error: $error');
          _scheduleWebSocketReconnect();
        },
        onDone: () {
          print('Angel One WebSocket disconnected');
          _scheduleWebSocketReconnect();
        },
      );
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
      _scheduleWebSocketReconnect();
    }
  }
  
  void _scheduleWebSocketReconnect() {
    Future.delayed(const Duration(seconds: 5), () async {
      if (_isConnected) {
        await reconnectWebSocket();
      }
    });
  }
  
  @override
  Future<void> reconnectWebSocket() async {
    _wsChannel?.sink.close();
    await _initWebSocket();
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final symbol = message['token'];
      
      if (_subscribers.containsKey(symbol)) {
        _subscribers[symbol]!(message);
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }
  
  @override
  Future<BrokerResponse> logout() async {
    cancelTokenRefresh();
    _isConnected = false;
    disconnectWebSocket();
    _dio = null;
    _jwtToken = null;
    _refreshToken = null;
    _clientId = null;
    _tokenExpiry = null;
    await clearCredentials();
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/order/v1/getQuote',
          queryParameters: {'symbol': symbol},
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(
            success: true,
            data: response.data['data'],
          );
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getHistoricalData(
    String symbol,
    String interval,
    DateTime from,
    DateTime to,
  ) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/order/v1/getCandleData',
          queryParameters: {
            'symbol': symbol,
            'interval': interval,
            'fromdate': from.toIso8601String(),
            'todate': to.toIso8601String(),
          },
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(
            success: true,
            data: response.data['data'],
          );
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> placeOrder(Order order) async {
    return authenticatedRequest(() async {
      try {
        final orderData = {
          'variety': 'NORMAL',
          'trading_symbol': order.symbol,
          'transaction_type': order.side == OrderSide.buy ? 'BUY' : 'SELL',
          'exchange': 'NSE',
          'order_type': _getOrderType(order.type),
          'quantity': order.quantity.toInt(),
          'price': order.price?.toString() ?? '0',
          'trigger_price': order.stopPrice?.toString() ?? '0',
          'product_type': 'INTRADAY',
          'duration': 'DAY',
        };
        
        final response = await _dio!.post(
          '/rest/secure/angelbroking/order/v1/placeOrder',
          data: orderData,
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(
            success: true,
            data: response.data['data'],
          );
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> modifyOrder(
    String orderId, {
    double? quantity,
    double? price,
    double? stopPrice,
  }) async {
    return authenticatedRequest(() async {
      try {
        final modifyData = {
          'variety': 'NORMAL',
          'order_id': orderId,
          if (quantity != null) 'quantity': quantity.toInt(),
          if (price != null) 'price': price.toString(),
          if (stopPrice != null) 'trigger_price': stopPrice.toString(),
        };
        
        final response = await _dio!.put(
          '/rest/secure/angelbroking/order/v1/modifyOrder',
          data: modifyData,
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> cancelOrder(String orderId) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.delete(
          '/rest/secure/angelbroking/order/v1/cancelOrder',
          data: {'order_id': orderId},
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getOrders({OrderStatus? status}) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/order/v1/getOrderBook',
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getOrderDetails(String orderId) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/order/v1/getOrderBook',
          queryParameters: {'order_id': orderId},
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getAccountInfo() async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/user/v1/getProfile',
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getPositions() async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/order/v1/getPosition',
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getHoldings() async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/portfolio/v1/getHolding',
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<BrokerResponse> getMargin() async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get(
          '/rest/secure/angelbroking/user/v1/getRMS',
        );
        
        if (response.statusCode == 200 && response.data['status']) {
          return BrokerResponse(success: true, data: response.data['data']);
        } else {
          return BrokerResponse(
            success: false,
            error: response.data['message'],
            statusCode: response.statusCode,
          );
        }
      } on DioException catch (e) {
        return BrokerResponse(
          success: false,
          error: _handleDioError(e),
          statusCode: e.response?.statusCode,
        );
      }
    });
  }
  
  @override
  Future<void> subscribeRealtimeData(
    List<String> symbols,
    Function(Map<String, dynamic>) onData,
  ) async {
    for (var symbol in symbols) {
      _subscribers[symbol] = onData;
    }
    
    final subscription = jsonEncode({
      'action': 'subscribe',
      'tokens': symbols,
    });
    
    _wsChannel?.sink.add(subscription);
  }
  
  @override
  Future<void> unsubscribeRealtimeData(List<String> symbols) async {
    for (var symbol in symbols) {
      _subscribers.remove(symbol);
    }
    
    final unsubscription = jsonEncode({
      'action': 'unsubscribe',
      'tokens': symbols,
    });
    
    _wsChannel?.sink.add(unsubscription);
  }
  
  @override
  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _subscribers.clear();
  }
  
  @override
  Future<void> reconnectWebSocket() async {
    _wsChannel?.sink.close();
    await _initWebSocket();
  }
  
  String _getOrderType(OrderType type) {
    switch (type) {
      case OrderType.market:
        return 'MARKET';
      case OrderType.limit:
        return 'LIMIT';
      case OrderType.stop:
        return 'STOP';
      case OrderType.stopLimit:
        return 'STOP_LOSS_LIMIT';
      default:
        return 'MARKET';
    }
  }
  
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return error.response?.data['message'] ?? 'Server error: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return error.message ?? 'Network error';
    }
  }
}


