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
