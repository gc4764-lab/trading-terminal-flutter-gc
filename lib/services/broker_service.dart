import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/order.dart';

class BrokerResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;
  
  BrokerResult({required this.success, this.error, this.data});
}

abstract class Broker {
  String get id;
  String get name;
  
  Future<BrokerResult> placeOrder(Order order);
  Future<BrokerResult> cancelOrder(String orderId);
  Future<BrokerResult> modifyOrder(String orderId, {double? quantity, double? price, double? stopPrice});
  Future<BrokerResult> getAccountInfo();
  Future<BrokerResult> getPositions();
  Future<BrokerResult> getOrderStatus(String orderId);
  Future<void> connect(Map<String, dynamic> credentials);
  Future<void> disconnect();
}

class DemoBroker implements Broker {
  final String _id = 'demo';
  final String _name = 'Demo Broker';
  Dio? _dio;
  
  @override
  String get id => _id;
  
  @override
  String get name => _name;
  
  @override
  Future<void> connect(Map<String, dynamic> credentials) async {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://demo-api.broker.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // Simulate connection
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  @override
  Future<void> disconnect() async {
    _dio = null;
  }
  
  @override
  Future<BrokerResult> placeOrder(Order order) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Random success/failure for demo
      final isSuccess = DateTime.now().millisecondsSinceEpoch % 10 > 2;
      
      if (isSuccess) {
        return BrokerResult(
          success: true,
          data: {
            'orderId': order.id,
            'status': 'accepted',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        return BrokerResult(
          success: false,
          error: 'Insufficient margin',
        );
      }
    } catch (e) {
      return BrokerResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  @override
  Future<BrokerResult> cancelOrder(String orderId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      return BrokerResult(success: true);
    } catch (e) {
      return BrokerResult(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResult> modifyOrder(String orderId, {double? quantity, double? price, double? stopPrice}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      return BrokerResult(success: true);
    } catch (e) {
      return BrokerResult(success: false, error: e.toString());
    }
  }
  
  @override
  Future<BrokerResult> getAccountInfo() async {
    return BrokerResult(
      success: true,
      data: {
        'accountId': 'DEMO123',
        'balance': 100000.0,
        'equity': 100000.0,
        'marginUsed': 0.0,
        'marginAvailable': 100000.0,
      },
    );
  }
  
  @override
  Future<BrokerResult> getPositions() async {
    return BrokerResult(
      success: true,
      data: {'positions': []},
    );
  }
  
  @override
  Future<BrokerResult> getOrderStatus(String orderId) async {
    return BrokerResult(
      success: true,
      data: {'orderId': orderId, 'status': 'filled'},
    );
  }
}

class BrokerService {
  static final Map<String, Broker> _brokers = {
    'demo': DemoBroker(),
  };
  
  static Broker getBroker(String brokerId) {
    if (!_brokers.containsKey(brokerId)) {
      throw Exception('Broker not found: $brokerId');
    }
    return _brokers[brokerId]!;
  }
  
  static Future<void> connectBroker(String brokerId, Map<String, dynamic> credentials) async {
    final broker = getBroker(brokerId);
    await broker.connect(credentials);
  }
  
  static Future<void> disconnectBroker(String brokerId) async {
    final broker = getBroker(brokerId);
    await broker.disconnect();
  }
  
  static void registerBroker(Broker broker) {
    _brokers[broker.id] = broker;
  }
  
  static List<String> getAvailableBrokers() {
    return _brokers.keys.toList();
  }
}
