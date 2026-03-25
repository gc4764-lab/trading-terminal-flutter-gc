import 'dart:collection';
import 'brokers/base_broker.dart';
import 'brokers/fyers_broker.dart';
import 'brokers/angel_one_broker.dart';
import 'brokers/sharekhan_broker.dart';
import 'brokers/binance_broker.dart';
import 'brokers/dhan_broker.dart';
import 'brokers/forex_broker.dart';

class BrokerManager {
  static final BrokerManager _instance = BrokerManager._internal();
  factory BrokerManager() => _instance;
  BrokerManager._internal();
  
  final Map<String, BaseBroker> _brokers = {};
  final Map<String, String> _activeBroker = {};
  
  void initializeBrokers() {
    // Register Indian brokers
    registerBroker(FyersBroker());
    registerBroker(AngelOneBroker());
    registerBroker(SharekhanBroker());
    registerBroker(DhanBroker());
    
    // Register Crypto broker
    registerBroker(BinanceBroker());
    
    // Register Forex brokers
    registerBroker(ForexBroker(
      brokerId: 'mt4_demo',
      brokerName: 'MT4 Demo',
    ));
    registerBroker(ForexBroker(
      brokerId: 'mt5_demo',
      brokerName: 'MT5 Demo',
    ));
    registerBroker(ForexBroker(
      brokerId: 'fxcm',
      brokerName: 'FXCM',
    ));
    registerBroker(ForexBroker(
      brokerId: 'oanda',
      brokerName: 'Oanda',
    ));
  }
  
  void registerBroker(BaseBroker broker) {
    _brokers[broker.brokerId] = broker;
  }
  
  BaseBroker? getBroker(String brokerId) {
    return _brokers[brokerId];
  }
  
  List<BaseBroker> getAllBrokers() {
    return _brokers.values.toList();
  }
  
  List<String> getAvailableBrokerIds() {
    return _brokers.keys.toList();
  }
  
  Future<bool> connectBroker(String brokerId, Map<String, dynamic> credentials) async {
    final broker = _brokers[brokerId];
    if (broker == null) return false;
    
    final response = await broker.login(credentials);
    if (response.success) {
      _activeBroker[brokerId] = 'connected';
      return true;
    }
    return false;
  }
  
  Future<bool> disconnectBroker(String brokerId) async {
    final broker = _brokers[brokerId];
    if (broker == null) return false;
    
    await broker.logout();
    _activeBroker.remove(brokerId);
    return true;
  }
  
  bool isBrokerConnected(String brokerId) {
    return _activeBroker.containsKey(brokerId);
  }
  
  void disconnectAllBrokers() {
    for (var brokerId in _activeBroker.keys) {
      disconnectBroker(brokerId);
    }
  }
  
  Future<Map<String, dynamic>> getCombinedMarketData(List<String> symbols) async {
    final results = <String, dynamic>{};
    
    for (var entry in _activeBroker.entries) {
      final broker = _brokers[entry.key];
      if (broker != null && broker.isConnected) {
        for (var symbol in symbols) {
          final data = await broker.getMarketData(symbol);
          if (data.success) {
            results['${entry.key}_$symbol'] = data.data;
          }
        }
      }
    }
    
    return results;
  }
  
  Future<void> subscribeAllBrokers(List<String> symbols, Function(Map<String, dynamic>) onData) async {
    for (var entry in _activeBroker.entries) {
      final broker = _brokers[entry.key];
      if (broker != null && broker.isConnected) {
        await broker.subscribeRealtimeData(symbols, (data) {
          onData({
            'broker': entry.key,
            'data': data,
          });
        });
      }
    }
  }
}
