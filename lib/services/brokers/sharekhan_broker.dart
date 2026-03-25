import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';

class SharekhanBroker extends BaseBroker {
  final String _brokerId = 'sharekhan';
  final String _brokerName = 'Sharekhan';
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
        baseUrl: 'https://api.sharekhan.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      final response = await _dio!.post('/api/v1/auth/login', data: {
        'user_id': credentials['userId'],
        'password': credentials['password'],
        'api_key': credentials['apiKey'],
      });
      
      if (response.statusCode == 200 && response.data['success']) {
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
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  void _initWebSocket() {
    _wsChannel = IOWebSocketChannel.connect(
      'wss://ws.sharekhan.com/stream?token=$_accessToken',
    );
    
    _wsChannel!.stream.listen(
      (data) {
        _handleWebSocketMessage(data);
      },
      onError: (error) {
        print('Sharekhan WebSocket error: $error');
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
      print('Error parsing Sharekhan message: $e');
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
    // Sharekhan token refresh implementation
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    try {
      final response = await _dio!.get(
        '/api/v1/market/quote',
        queryParameters: {'symbol': symbol},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        '/api/v1/market/history',
        queryParameters: {
          'symbol': symbol,
          'interval': interval,
          'from': from.millisecondsSinceEpoch ~/ 1000,
          'to': to.millisecondsSinceEpoch ~/ 1000,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
    
    final subscription = jsonEncode({
      'action': 'subscribe',
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
      'action': 'unsubscribe',
      'symbols': symbols,
    });
    
    _wsChannel?.sink.add(unsubscription);
  }
  
  @override
  Future<BrokerResponse> placeOrder(Order order) async {
    try {
      final orderData = {
        'symbol': order.symbol,
        'quantity': order.quantity,
        'order_type': _getOrderType(order.type),
        'transaction_type': order.side == OrderSide.buy ? 'BUY' : 'SELL',
        'price': order.price,
        'stop_price': order.stopPrice,
        'validity': 'DAY',
      };
      
      final response = await _dio!.post(
        '/api/v1/orders',
        data: orderData,
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        return 'STOP_LIMIT';
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
        'order_id': orderId,
        if (quantity != null) 'quantity': quantity,
        if (price != null) 'price': price,
        if (stopPrice != null) 'stop_price': stopPrice,
      };
      
      final response = await _dio!.put(
        '/api/v1/orders/$orderId',
        data: modifyData,
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        '/api/v1/orders/$orderId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        '/api/v1/orders',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
    try {
      final response = await _dio!.get(
        '/api/v1/orders/$orderId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
        return BrokerResponse(success: true, data: response.data['data']);
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
      final response = await _dio!.get(
        '/api/v1/account',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        '/api/v1/positions',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        '/api/v1/holdings',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
        '/api/v1/margin',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['success']) {
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
