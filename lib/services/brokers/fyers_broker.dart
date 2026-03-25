import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';
import '../../models/symbol.dart';

class FyersBroker extends BaseBroker {
  final String _brokerId = 'fyers';
  final String _brokerName = 'Fyers';
  bool _isConnected = false;
  Dio? _dio;
  WebSocketChannel? _wsChannel;
  String? _accessToken;
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
        baseUrl: 'https://api.fyers.in/api/v2',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ));
      
      final response = await _dio!.post('/auth', data: {
        'app_id': credentials['apiKey'],
        'secret_key': credentials['apiSecret'],
        'grant_type': 'authorization_code',
        'code': credentials['authCode'],
      });
      
      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        _isConnected = true;
        
        // Initialize WebSocket
        _initWebSocket();
        
        return BrokerResponse(
          success: true,
          data: {
            'access_token': _accessToken,
            'user_id': response.data['user_id'],
          },
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return BrokerResponse(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  void _initWebSocket() {
    _wsChannel = IOWebSocketChannel.connect(
      'wss://api.fyers.in/socket/v2/$_accessToken',
    );
    
    _wsChannel!.stream.listen(
      (data) {
        _handleWebSocketMessage(data);
      },
      onError: (error) {
        print('Fyers WebSocket error: $error');
      },
      onDone: () {
        print('Fyers WebSocket disconnected');
      },
    );
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final symbol = message['symbol'];
      
      if (_subscribers.containsKey(symbol)) {
        _subscribers[symbol]!(message);
      }
    } catch (e) {
      print('Error parsing Fyers message: $e');
    }
  }
  
  @override
  Future<BrokerResponse> logout() async {
    _isConnected = false;
    _accessToken = null;
    disconnectWebSocket();
    _dio = null;
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> refreshToken() async {
    // Fyers token refresh implementation
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    try {
      final response = await _dio!.get('/quotes', queryParameters: {
        'symbols': symbol,
      });
      
      if (response.statusCode == 200) {
        return BrokerResponse(
          success: true,
          data: response.data,
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
    DateTime to
  ) async {
    try {
      final response = await _dio!.get('/history', queryParameters: {
        'symbol': symbol,
        'resolution': _getResolution(interval),
        'from': from.millisecondsSinceEpoch ~/ 1000,
        'to': to.millisecondsSinceEpoch ~/ 1000,
      });
      
      if (response.statusCode == 200) {
        return BrokerResponse(
          success: true,
          data: response.data,
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
  
  String _getResolution(String interval) {
    switch (interval) {
      case '1m': return '1';
      case '5m': return '5';
      case '15m': return '15';
      case '30m': return '30';
      case '1h': return '60';
      case '1d': return 'D';
      default: return 'D';
    }
  }
  
  @override
  Future<void> subscribeRealtimeData(
    List<String> symbols, 
    Function(Map<String, dynamic>) onData
  ) async {
    for (var symbol in symbols) {
      _subscribers[symbol] = onData;
      
      // Send subscription message
      final subscription = jsonEncode({
        'type': 'subscribe',
        'symbols': symbols,
      });
      
      _wsChannel?.sink.add(subscription);
    }
  }
  
  @override
  Future<void> unsubscribeRealtimeData(List<String> symbols) async {
    for (var symbol in symbols) {
      _subscribers.remove(symbol);
    }
    
    final unsubscription = jsonEncode({
      'type': 'unsubscribe',
      'symbols': symbols,
    });
    
    _wsChannel?.sink.add(unsubscription);
  }
  
  @override
  Future<BrokerResponse> placeOrder(Order order) async {
    try {
      final orderData = {
        'symbol': order.symbol,
        'qty': order.quantity.toInt(),
        'type': _getOrderType(order.type),
        'side': _getOrderSide(order.side),
        'productType': 'INTRADAY',
        'limitPrice': order.price,
        'stopPrice': order.stopPrice,
        'validity': 'DAY',
      };
      
      final response = await _dio!.post('/orders', data: orderData);
      
      if (response.statusCode == 200) {
        return BrokerResponse(
          success: true,
          data: response.data,
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
        return 'STOP_LIMIT';
      default:
        return 'MARKET';
    }
  }
  
  String _getOrderSide(OrderSide side) {
    return side == OrderSide.buy ? 'BUY' : 'SELL';
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
        'id': orderId,
        if (quantity != null) 'qty': quantity.toInt(),
        if (price != null) 'limitPrice': price,
        if (stopPrice != null) 'stopPrice': stopPrice,
      };
      
      final response = await _dio!.put('/orders', data: modifyData);
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
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
      final response = await _dio!.delete('/orders/$orderId');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
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
      final response = await _dio!.get('/orders');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getOrderDetails(String orderId) async {
    try {
      final response = await _dio!.get('/orders/$orderId');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: response.data['message']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getAccountInfo() async {
    try {
      final response = await _dio!.get('/funds');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
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
      final response = await _dio!.get('/positions');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
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
      final response = await _dio!.get('/holdings');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
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
      final response = await _dio!.get('/margin');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
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




// lib/services/brokers/fyers_broker.dart (Complete with Token Refresh)
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';
import '../secure_storage_service.dart';

class FyersBroker extends BaseBroker {
  final String _brokerId = 'fyers';
  final String _brokerName = 'Fyers';
  bool _isConnected = false;
  Dio? _dio;
  WebSocketChannel? _wsChannel;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  Timer? _refreshTimer;
  Map<String, Function(Map<String, dynamic>)> _subscribers = {};
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // API Endpoints
  static const String _baseUrl = 'https://api.fyers.in/api/v2';
  static const String _authUrl = 'https://api.fyers.in/api/v2/auth';
  static const String _tokenUrl = 'https://api.fyers.in/api/v2/token';
  static const String _wsUrl = 'wss://api.fyers.in/socket/v2';
  
  @override
  String get brokerId => _brokerId;
  
  @override
  String get brokerName => _brokerName;
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  bool get needsTokenRefresh => _tokenExpiry != null && 
      DateTime.now().isAfter(_tokenExpiry!.subtract(const Duration(minutes: 5)));
  
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
        },
      ));
      
      final response = await _dio!.post('/auth', data: {
        'app_id': credentials['apiKey'],
        'secret_key': credentials['apiSecret'],
        'grant_type': 'authorization_code',
        'code': credentials['authCode'],
      });
      
      if (response.statusCode == 200 && response.data['s'] == 'ok') {
        _accessToken = response.data['access_token'];
        _refreshToken = response.data['refresh_token'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 24));
        _isConnected = true;
        
        // Save credentials
        await saveCredentials({
          'apiKey': credentials['apiKey'],
          'apiSecret': credentials['apiSecret'],
          'authCode': credentials['authCode'],
          'access_token': _accessToken!,
          'refresh_token': _refreshToken!,
          'token_expiry': _tokenExpiry!.toIso8601String(),
          'user_id': response.data['user_id'],
        });
        
        // Initialize Dio with auth header
        _dio!.options.headers['Authorization'] = 'Bearer $_accessToken';
        
        // Initialize WebSocket
        await _initWebSocket();
        
        // Schedule token refresh
        await scheduleTokenRefresh();
        
        return BrokerResponse(
          success: true,
          data: {
            'access_token': _accessToken,
            'refresh_token': _refreshToken,
            'user_id': response.data['user_id'],
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
    if (_refreshToken == null) {
      return BrokerResponse(
        success: false,
        error: 'No refresh token available',
      );
    }
    
    try {
      final response = await _dio!.post('/refresh', data: {
        'refresh_token': _refreshToken,
        'grant_type': 'refresh_token',
      });
      
      if (response.statusCode == 200 && response.data['s'] == 'ok') {
        _accessToken = response.data['access_token'];
        _refreshToken = response.data['refresh_token'];
        _tokenExpiry = DateTime.now().add(const Duration(hours: 24));
        
        // Update stored credentials
        final creds = await loadCredentials();
        creds['access_token'] = _accessToken!;
        creds['refresh_token'] = _refreshToken!;
        creds['token_expiry'] = _tokenExpiry!.toIso8601String();
        await saveCredentials(creds);
        
        // Update Dio headers
        _dio!.options.headers['Authorization'] = 'Bearer $_accessToken';
        
        // Reconnect WebSocket
        await reconnectWebSocket();
        
        return BrokerResponse(success: true, data: {
          'access_token': _accessToken,
          'refresh_token': _refreshToken,
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
    
    final refreshTime = _tokenExpiry!.subtract(const Duration(minutes: 5));
    final delay = refreshTime.difference(DateTime.now());
    
    if (delay.isNegative) {
      // Token already expired or about to expire, refresh now
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
          // Token expired, try to refresh
          final refreshResponse = await refreshToken();
          if (refreshResponse.success) {
            // Retry the original request
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
          // Try to refresh token and retry
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
    if (creds.isNotEmpty && creds.containsKey('access_token')) {
      _accessToken = creds['access_token'];
      _refreshToken = creds['refresh_token'];
      
      if (creds.containsKey('token_expiry')) {
        _tokenExpiry = DateTime.parse(creds['token_expiry']!);
      }
      
      // Initialize Dio
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      ));
      
      // Check if token is still valid
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
    if (_accessToken == null) return;
    
    try {
      _wsChannel = IOWebSocketChannel.connect('$_wsUrl/$_accessToken');
      
      _wsChannel!.stream.listen(
        (data) {
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          print('Fyers WebSocket error: $error');
          _scheduleWebSocketReconnect();
        },
        onDone: () {
          print('Fyers WebSocket disconnected');
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
      final symbol = message['symbol'];
      
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
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    await clearCredentials();
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get('/quotes', queryParameters: {
          'symbols': symbol,
        });
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
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
        final resolution = _getResolution(interval);
        final response = await _dio!.get('/history', queryParameters: {
          'symbol': symbol,
          'resolution': resolution,
          'from': from.millisecondsSinceEpoch ~/ 1000,
          'to': to.millisecondsSinceEpoch ~/ 1000,
        });
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(
            success: true,
            data: response.data['candles'],
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
          'symbol': order.symbol,
          'qty': order.quantity.toInt(),
          'type': _getOrderType(order.type),
          'side': _getOrderSide(order.side),
          'productType': 'INTRADAY',
          'limitPrice': order.price,
          'stopPrice': order.stopPrice,
          'validity': 'DAY',
        };
        
        final response = await _dio!.post('/orders', data: orderData);
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(
            success: true,
            data: response.data,
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
  Future<BrokerResponse> getOrders({OrderStatus? status}) async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get('/orders');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(
            success: true,
            data: response.data['orderBook'],
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
  Future<BrokerResponse> getAccountInfo() async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get('/funds');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(
            success: true,
            data: response.data,
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
  Future<BrokerResponse> getPositions() async {
    return authenticatedRequest(() async {
      try {
        final response = await _dio!.get('/positions');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(
            success: true,
            data: response.data,
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
          'id': orderId,
          if (quantity != null) 'qty': quantity.toInt(),
          if (price != null) 'limitPrice': price,
          if (stopPrice != null) 'stopPrice': stopPrice,
        };
        
        final response = await _dio!.put('/orders', data: modifyData);
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(success: true, data: response.data);
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
        final response = await _dio!.delete('/orders/$orderId');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(success: true, data: response.data);
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
        final response = await _dio!.get('/orders/$orderId');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(success: true, data: response.data);
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
        final response = await _dio!.get('/holdings');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(success: true, data: response.data);
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
        final response = await _dio!.get('/margin');
        
        if (response.statusCode == 200 && response.data['s'] == 'ok') {
          return BrokerResponse(success: true, data: response.data);
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
      'type': 'subscribe',
      'symbols': symbols,
    });
    
    _wsChannel?.sink.add(subscription);
  }
  
  @override
  Future<void> unsubscribeRealtimeData(List<String> symbols) async {
    for (var symbol in symbols) {
      _subscribers.remove(symbol);
    }
    
    final unsubscription = jsonEncode({
      'type': 'unsubscribe',
      'symbols': symbols,
    });
    
    _wsChannel?.sink.add(unsubscription);
  }
  
  @override
  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
    _subscribers.clear();
  }
  
  String _getResolution(String interval) {
    switch (interval) {
      case '1m': return '1';
      case '5m': return '5';
      case '15m': return '15';
      case '30m': return '30';
      case '1h': return '60';
      case '1d': return 'D';
      default: return 'D';
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
        return 'STOP_LIMIT';
      default:
        return 'MARKET';
    }
  }
  
  String _getOrderSide(OrderSide side) {
    return side == OrderSide.buy ? 'BUY' : 'SELL';
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

