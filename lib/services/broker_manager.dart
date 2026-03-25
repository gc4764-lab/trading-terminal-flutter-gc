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





// lib/services/broker_manager.dart (updated)
import 'dart:async';
import 'brokers/base_broker.dart';
import 'brokers/fyers_broker.dart';
import 'brokers/angel_one_broker.dart';
// import other brokers...

class BrokerManager {
  static final BrokerManager _instance = BrokerManager._internal();
  factory BrokerManager() => _instance;
  BrokerManager._internal();
  
  final Map<String, BaseBroker> _brokers = {};
  final Map<String, bool> _connectedBrokers = {};
  
  void initializeBrokers() {
    // Register brokers
    registerBroker(FyersBroker());
    registerBroker(AngelOneBroker());
    // register others...
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
  
  Future<void> restoreSessions() async {
    for (var broker in _brokers.values) {
      if (await broker.hasStoredCredentials()) {
        // If the broker has a restoreSession method, call it
        if (broker is FyersBroker) {
          await (broker as FyersBroker).restoreSession();
        } else if (broker is AngelOneBroker) {
          await (broker as AngelOneBroker).restoreSession();
        }
        // Add similar for other brokers
        
        if (broker.isConnected) {
          _connectedBrokers[broker.brokerId] = true;
        }
      }
    }
  }
  
  bool isBrokerConnected(String brokerId) {
    return _connectedBrokers[brokerId] ?? false;
  }
  
  Future<bool> connectBroker(String brokerId, Map<String, dynamic> credentials) async {
    final broker = _brokers[brokerId];
    if (broker == null) return false;
    
    final response = await broker.login(credentials);
    if (response.success) {
      _connectedBrokers[brokerId] = true;
      return true;
    }
    return false;
  }
  
  Future<bool> disconnectBroker(String brokerId) async {
    final broker = _brokers[brokerId];
    if (broker == null) return false;
    
    await broker.logout();
    await broker.clearCredentials();
    _connectedBrokers.remove(brokerId);
    return true;
  }
  
  void disconnectAllBrokers() {
    for (var brokerId in _connectedBrokers.keys.toList()) {
      disconnectBroker(brokerId);
    }
  }
}


// lib/services/broker_manager.dart (Updated)
import 'dart:async';
import 'brokers/base_broker.dart';
import 'brokers/fyers_broker.dart';
import 'brokers/angel_one_broker.dart';
import 'brokers/sharekhan_broker.dart';
import 'brokers/binance_broker.dart';
import 'brokers/dhan_broker.dart';
import 'brokers/forex_broker.dart';
import 'token_refresh_manager.dart';

class BrokerManager {
  static final BrokerManager _instance = BrokerManager._internal();
  factory BrokerManager() => _instance;
  BrokerManager._internal();
  
  final Map<String, BaseBroker> _brokers = {};
  final Map<String, bool> _connectedBrokers = {};
  final TokenRefreshManager _tokenRefreshManager = TokenRefreshManager();
  
  void initializeBrokers() {
    // Register brokers
    final fyers = FyersBroker();
    final angelOne = AngelOneBroker();
    final sharekhan = SharekhanBroker();
    final binance = BinanceBroker();
    final dhan = DhanBroker();
    final forex = ForexBroker(brokerId: 'mt4_demo', brokerName: 'MT4 Demo');
    
    registerBroker(fyers);
    registerBroker(angelOne);
    registerBroker(sharekhan);
    registerBroker(binance);
    registerBroker(dhan);
    registerBroker(forex);
    
    // Start token refresh manager
    _tokenRefreshManager.initialize();
  }
  
  void registerBroker(BaseBroker broker) {
    _brokers[broker.brokerId] = broker;
    _tokenRefreshManager.registerBroker(broker);
  }
  
  BaseBroker? getBroker(String brokerId) {
    return _brokers[brokerId];
  }
  
  List<BaseBroker> getAllBrokers() {
    return _brokers.values.toList();
  }
  
  List<String> getConnectedBrokers() {
    return _connectedBrokers.keys.toList();
  }
  
  Future<void> restoreSessions() async {
    for (var broker in _brokers.values) {
      if (await broker.hasStoredCredentials()) {
        try {
          if (broker is FyersBroker) {
            await (broker as FyersBroker).restoreSession();
          } else if (broker is AngelOneBroker) {
            await (broker as AngelOneBroker).restoreSession();
          } else if (broker is SharekhanBroker) {
            await (broker as SharekhanBroker).restoreSession();
          } else if (broker is BinanceBroker) {
            await (broker as BinanceBroker).restoreSession();
          } else if (broker is DhanBroker) {
            await (broker as DhanBroker).restoreSession();
          }
          
          if (broker.isConnected) {
            _connectedBrokers[broker.brokerId] = true;
          }
        } catch (e) {
          debugPrint('Failed to restore session for ${broker.brokerId}: $e');
          // Clear invalid credentials
          await broker.clearCredentials();
        }
      }
    }
  }
  
  bool isBrokerConnected(String brokerId) {
    return _connectedBrokers[brokerId] ?? false;
  }
  
  Future<bool> connectBroker(String brokerId, Map<String, dynamic> credentials) async {
    final broker = _brokers[brokerId];
    if (broker == null) return false;
    
    final response = await broker.login(credentials);
    if (response.success) {
      _connectedBrokers[brokerId] = true;
      return true;
    }
    return false;
  }
  
  Future<bool> disconnectBroker(String brokerId) async {
    final broker = _brokers[brokerId];
    if (broker == null) return false;
    
    await broker.logout();
    await broker.clearCredentials();
    _connectedBrokers.remove(brokerId);
    return true;
  }
  
  void disconnectAllBrokers() {
    for (var brokerId in _connectedBrokers.keys.toList()) {
      disconnectBroker(brokerId);
    }
  }
  
  void dispose() {
    _tokenRefreshManager.dispose();
    disconnectAllBrokers();
  }
}


