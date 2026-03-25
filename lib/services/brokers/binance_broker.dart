import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_broker.dart';
import '../../models/order.dart';

class BinanceBroker extends BaseBroker {
  final String _brokerId = 'binance';
  final String _brokerName = 'Binance';
  bool _isConnected = false;
  Dio? _dio;
  WebSocketChannel? _wsChannel;
  String? _apiKey;
  String? _apiSecret;
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
      _apiKey = credentials['apiKey'];
      _apiSecret = credentials['apiSecret'];
      
      _dio = Dio(BaseOptions(
        baseUrl: 'https://api.binance.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'X-MBX-APIKEY': _apiKey!,
        },
      ));
      
      // Test connection
      final response = await _dio!.get('/api/v3/account', queryParameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (response.statusCode == 200) {
        _isConnected = true;
        _initWebSocket();
        
        return BrokerResponse(
          success: true,
          data: response.data,
        );
      } else {
        return BrokerResponse(
          success: false,
          error: 'Connection failed',
        );
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  void _initWebSocket() {
    _wsChannel = IOWebSocketChannel.connect(
      'wss://stream.binance.com:9443/ws',
    );
    
    _wsChannel!.stream.listen(
      (data) {
        _handleWebSocketMessage(data);
      },
      onError: (error) {
        print('Binance WebSocket error: $error');
      },
    );
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final message = jsonDecode(data);
      final symbol = message['s'];
      
      if (_subscribers.containsKey(symbol)) {
        _subscribers[symbol]!(message);
      }
    } catch (e) {
      print('Error parsing Binance message: $e');
    }
  }
  
  @override
  Future<BrokerResponse> logout() async {
    _isConnected = false;
    _apiKey = null;
    _apiSecret = null;
    disconnectWebSocket();
    _dio = null;
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> refreshToken() async {
    // Binance uses API keys that don't require refresh
    return BrokerResponse(success: true);
  }
  
  @override
  Future<BrokerResponse> getMarketData(String symbol) async {
    try {
      final response = await _dio!.get('/api/v3/ticker/24hr', queryParameters: {
        'symbol': symbol.toUpperCase(),
      });
      
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
      final response = await _dio!.get('/api/v3/klines', queryParameters: {
        'symbol': symbol.toUpperCase(),
        'interval': _getInterval(interval),
        'startTime': from.millisecondsSinceEpoch,
        'endTime': to.millisecondsSinceEpoch,
        'limit': 1000,
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
      case '1m': return '1m';
      case '5m': return '5m';
      case '15m': return '15m';
      case '30m': return '30m';
      case '1h': return '1h';
      case '4h': return '4h';
      case '1d': return '1d';
      case '1w': return '1w';
      default: return '1h';
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
      'method': 'SUBSCRIBE',
      'params': symbols.map((s) => '${s.toLowerCase()}@ticker').toList(),
      'id': DateTime.now().millisecondsSinceEpoch,
    });
    
    _wsChannel?.sink.add(subscription);
  }
  
  @override
  Future<void> unsubscribeRealtimeData(List<String> symbols) async {
    for (var symbol in symbols) {
      _subscribers.remove(symbol);
    }
    
    final unsubscription = jsonEncode({
      'method': 'UNSUBSCRIBE',
      'params': symbols.map((s) => '${s.toLowerCase()}@ticker').toList(),
      'id': DateTime.now().millisecondsSinceEpoch,
    });
    
    _wsChannel?.sink.add(unsubscription);
  }
  
  String _generateSignature(String queryString) {
    final hmac = Hmac(sha256, utf8.encode(_apiSecret!));
    final digest = hmac.convert(utf8.encode(queryString));
    return digest.toString();
  }
  
  @override
  Future<BrokerResponse> placeOrder(Order order) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final params = {
        'symbol': order.symbol.toUpperCase(),
        'side': order.side == OrderSide.buy ? 'BUY' : 'SELL',
        'type': _getOrderType(order.type),
        'quantity': order.quantity.toStringAsFixed(8),
        'timestamp': timestamp.toString(),
      };
      
      if (order.type == OrderType.limit && order.price != null) {
        params['price'] = order.price.toString();
        params['timeInForce'] = 'GTC';
      }
      
      if (order.type == OrderType.stop && order.stopPrice != null) {
        params['stopPrice'] = order.stopPrice.toString();
      }
      
      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final signature = _generateSignature(queryString);
      
      final response = await _dio!.post(
        '/api/v3/order',
        queryParameters: {
          ...params,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        return BrokerResponse(
          success: true,
          data: response.data,
        );
      } else {
        return BrokerResponse(
          success: false,
          error: response.data['msg'],
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
        return 'STOP_LOSS';
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
    // Binance requires cancel and place new order for modification
    final cancelResult = await cancelOrder(orderId);
    if (!cancelResult.success) {
      return cancelResult;
    }
    
    // Create new order with modified parameters
    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: '', // This needs to be populated
      type: OrderType.limit,
      side: OrderSide.buy,
      quantity: quantity ?? 0,
      price: price,
      stopPrice: stopPrice,
      brokerId: _brokerId,
      createdAt: DateTime.now(),
    );
    
    return await placeOrder(newOrder);
  }
  
  @override
  Future<BrokerResponse> cancelOrder(String orderId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final params = {
        'symbol': '', // This needs to be populated
        'orderId': orderId,
        'timestamp': timestamp.toString(),
      };
      
      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final signature = _generateSignature(queryString);
      
      final response = await _dio!.delete(
        '/api/v3/order',
        queryParameters: {
          ...params,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: response.data['msg']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getOrders({OrderStatus? status}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final params = {
        'timestamp': timestamp.toString(),
      };
      
      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final signature = _generateSignature(queryString);
      
      final response = await _dio!.get(
        '/api/v3/openOrders',
        queryParameters: {
          ...params,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: response.data['msg']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getOrderDetails(String orderId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final params = {
        'orderId': orderId,
        'timestamp': timestamp.toString(),
      };
      
      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final signature = _generateSignature(queryString);
      
      final response = await _dio!.get(
        '/api/v3/order',
        queryParameters: {
          ...params,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: response.data['msg']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getAccountInfo() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final params = {
        'timestamp': timestamp.toString(),
      };
      
      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final signature = _generateSignature(queryString);
      
      final response = await _dio!.get(
        '/api/v3/account',
        queryParameters: {
          ...params,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        return BrokerResponse(success: true, data: response.data);
      } else {
        return BrokerResponse(success: false, error: response.data['msg']);
      }
    } catch (e) {
      return BrokerResponse(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResponse> getPositions() async {
    // For Binance, positions are the same as account info
    return await getAccountInfo();
  }
  
  @override
  Future<BrokerResponse> getHoldings() async {
    // For Binance, holdings are the same as account info
    return await getAccountInfo();
  }
  
  @override
  Future<BrokerResponse> getMargin() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final params = {
        'timestamp': timestamp.toString(),
      };
      
      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final signature = _generateSignature(queryString);
      
      final response = await _dio!.get(
        '/api/v3/account',
        queryParameters: {
          ...params,
          'signature': signature,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return BrokerResponse(
          success: true,
          data: {
            'total_margin': data['totalWalletBalance'],
            'used_margin': data['totalMaintMargin'],
            'available_margin': data['totalWalletBalance'] - data['totalMaintMargin'],
          },
        );
      } else {
        return BrokerResponse(success: false, error: response.data['msg']);
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
