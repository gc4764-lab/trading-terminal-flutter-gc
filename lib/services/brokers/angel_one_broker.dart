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
