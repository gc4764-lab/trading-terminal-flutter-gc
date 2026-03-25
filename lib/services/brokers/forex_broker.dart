import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';

// Generic Forex Broker implementation for MetaTrader 4/5 and other forex platforms
class ForexBroker extends BaseBroker {
  final String _brokerId;
  final String _brokerName;
  bool _isConnected = false;
  Dio? _dio;
  WebSocketChannel? _wsChannel;
  String? _sessionToken;
  Map<String, Function(Map<String, dynamic>)> _subscribers = {};
  
  ForexBroker({required String brokerId, required String brokerName}) 
      : _brokerId = brokerId,
        _brokerName = brokerName;
  
  @override
  String get brokerId => _brokerId;
  
  @override
  String get brokerName => _brokerName;
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  Future<BrokerResponse> login(Map<String, dynamic> credentials) async {
    try {
      // Support for multiple forex brokers through their APIs
      final apiType = credentials['api_type'] ?? 'mt5';
      
      switch (apiType) {
        case 'mt4':
          return await _loginMT4(credentials);
        case 'mt5':
          return await _loginMT5(credentials);
        case 'fxcm':
          return await _loginFXCM(credentials);
        case 'oanda':
          return await _loginOanda(credentials);
        default:
          return BrokerResponse(
            success: false,
            error: 'Unsupported forex API type',
          );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  Future<BrokerResponse> _loginMT4(Map<String, dynamic> credentials) async {
    // MT4/MT5 API integration
    _dio = Dio(BaseOptions(
      baseUrl: credentials['server_url'] ?? 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    final response = await _dio!.post('/api/login', data: {
      'login': credentials['login'],
      'password': credentials['password'],
      'server': credentials['server'],
    });
    
    if (response.statusCode == 200 && response.data['success']) {
      _sessionToken = response.data['token'];
      _isConnected = true;
      _initWebSocket(credentials);
      
      return BrokerResponse(
        success: true,
        data: response.data,
      );
    }
    
    return BrokerResponse(
      success: false,
      error: 'MT4 login failed',
    );
  }
  
  Future<BrokerResponse> _loginMT5(Map<String, dynamic> credentials) async {
    // Similar to MT4 but with MT5 specific endpoints
    return await _loginMT4(credentials);
  }
  
  Future<BrokerResponse> _loginFXCM(Map<String, dynamic> credentials) async {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.fxcm.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    final response = await _dio!.post('/v1/session', data: {
      'username': credentials['username'],
      'password': credentials['password'],
    });
    
    if (response.statusCode == 200 && response.data['status'] == 'success') {
      _sessionToken = response.data['token'];
      _isConnected = true;
      _initWebSocket(credentials);
      
      return BrokerResponse(
        success: true,
        data: response.data,
      );
    }
    
    return BrokerResponse(
      success: false,
      error: 'FXCM login failed',
    );
  }
  
  Future<BrokerResponse> _loginOanda(Map<String, dynamic> credentials) async {
    _dio = Dio(BaseOptions(
      baseUrl: credentials['practice'] == true 
          ? 'https://api-fxpractice.oanda.com'
          : 'https://api-fxtrade.oanda.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer ${credentials['api_key']}',
        'Content-Type': 'application/json',
      },
    ));
    
    final response = await _dio!.get('/v3/accounts');
    
    if (response.statusCode == 200) {
      _sessionToken = credentials['api_key'];
      _isConnected = true;
      _initWebSocket(credentials);
      
      return BrokerResponse(
        success: true,
        data: response.data,
      );
    }
    
    return BrokerResponse(
      success: false,
      error: 'Oanda login failed',
    );
  }
  
  void _initWebSocket(Map<String, dynamic> credentials) {
    final apiType = credentials['api_type'] ?? 'mt5';
    String wsUrl;
    
    switch (apiType) {
      case 'mt4':
      case 'mt5':
        wsUrl = credentials['ws_url'] ?? 'ws://localhost:8080/ws';
        break;
      case 'fxcm':
        wsUrl = 'wss://ws.fxcm.com/v1/stream';
        break;
      case 'oanda':
        wsUrl = credentials['practice'] == true
            ? 'wss://stream-fxpractice.oanda.com/v3/accounts'
            : 'wss://stream-fxtrade.oanda.com/v3/accounts';
        break;
      default:
        return;
    }
    
    _wsChannel = IOWebSocketChannel.connect(wsUrl);
    
    _wsChannel!.stream.listen(
      (data) {
        _handleWebSocketMessage(data);
      },
      onError: (error) {
        print('Forex WebSocket error: $error');
      },
    );
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final symbol = message['symbol'] ?? message['instrument'];
      
      if (_subscribers.containsKey(symbol)) {
        _subscribers[symbol]!(message);
      }
    } catch (e) {
      print('Error parsing Forex message: $e');
    }
  }
  
  @override
  Future<BrokerResponse> logout() async {
    _isConnected = false;
    _sessionToken = null;
    disconnectWebSocket();
    _dio = null;
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> refreshToken() async {
    // Implement token refresh based on broker type
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    try {
      final response = await _dio!.get('/quotes/$symbol');
      
      if (response.statusCode == 200) {
        return BrokerResponse(
          success: true,
          data: response.data,
        );
      } else {
        return BrokerResponse(
          success: false,
          error: 'Failed to get market data',
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
      final response = await _dio!.get('/history', queryParameters: {
        'symbol': symbol,
        'interval': _getInterval(interval),
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        return BrokerResponse(
          success: true,
          data: response.data,
        );
      } else {
        return BrokerResponse(
          success: false,
          error: 'Failed to get historical data',
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  String _getInterval(String interval) {
    switch (interval) {
      case '1m': return 'M1';
      case '5m': return 'M5';
      case '15m': return 'M15';
      case '30m': return 'M30';
      case '1h': return 'H1';
      case '4h': return 'H4';
      case '1d': return 'D1';
      case '1w': return 'W1';
      default: return 'H1';
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
  Future<BrokerResponse> placeOrder(Order order) async {
    try {
      final orderData = {
        'symbol': order.symbol,
        'volume': order.quantity,
        'type': _getOrderType(order.type),
        'side': order.side == OrderSide.buy ? 'buy' : 'sell',
        'price': order.price,
        'stop_loss': order.stopPrice,
        'take_profit': order.takeProfit,
      };
      
      final response = await _dio!.post('/orders', data: orderData);
      
      if (response.statusCode == 200 && response.data['success']) {
        return BrokerResponse(
          success: true,
          data: response.data,
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['message'] ?? 'Order placement failed',
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  String _getOrderType(OrderType type) {
    switch (type) {
      case OrderType.market:
        return 'market';
      case OrderType.limit:
        return 'limit';
      case OrderType.stop:
        return 'stop';
      case OrderType.stopLimit:
        return 'stop_limit';
      default:
        return 'market';
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
        'order_id': orderId,
        if (quantity != null) 'volume': quantity,
        if (price != null) 'price': price,
        if (stopPrice != null) 'stop_loss': stopPrice,
      };
      
      final response = await _dio!.put('/orders/$orderId', data: modifyData);
      
      if (response.statusCode == 200 && response.data['success']) {
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
      
      if (response.statusCode == 200 && response.data['success']) {
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
        return BrokerResponse(success: false, error: 'Failed to get orders');
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
        return BrokerResponse(success: false, error: 'Failed to get order details');
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getAccountInfo() async {
    try {
      final response = await _dio!.get('/account');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: 'Failed to get account info');
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
        return BrokerResponse(success: false, error: 'Failed to get positions');
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getHoldings() async {
    // For forex, holdings are typically the same as positions
    return await getPositions();
  }
  
  @override
  Future<BrokerResponse> getMargin() async {
    try {
      final response = await _dio!.get('/margin');
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: 'Failed to get margin info');
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
