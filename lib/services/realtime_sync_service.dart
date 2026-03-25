// lib/services/realtime_sync_service.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/symbol.dart';
import '../models/order.dart';
import '../providers/market_data_provider.dart';

class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._internal();
  
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, List<Function(Symbol)>> _subscribers = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Queue<Symbol> _updateQueue = Queue();
  Timer? _batchTimer;
  bool _isBatching = false;
  
  void initialize() {
    _startBatchProcessor();
  }
  
  void subscribeSymbol(String symbol, Function(Symbol) onUpdate) {
    if (!_subscribers.containsKey(symbol)) {
      _subscribers[symbol] = [];
      _connectWebSocket(symbol);
    }
    _subscribers[symbol]!.add(onUpdate);
  }
  
  void unsubscribeSymbol(String symbol, Function(Symbol) onUpdate) {
    if (_subscribers.containsKey(symbol)) {
      _subscribers[symbol]!.remove(onUpdate);
      if (_subscribers[symbol]!.isEmpty) {
        _subscribers.remove(symbol);
        _disconnectWebSocket(symbol);
      }
    }
  }
  
  void _connectWebSocket(String symbol) {
    try {
      final channel = IOWebSocketChannel.connect(
        'wss://stream.tradingdata.com/market/$symbol',
        pingInterval: const Duration(seconds: 30),
      );
      
      _channels[symbol] = channel;
      
      channel.stream.listen(
        (data) {
          _handleIncomingData(symbol, data);
        },
        onError: (error) {
          debugPrint('WebSocket error for $symbol: $error');
          _reconnectWebSocket(symbol);
        },
        onDone: () {
          debugPrint('WebSocket closed for $symbol');
          _reconnectWebSocket(symbol);
        },
      );
      
      // Send subscription confirmation
      channel.sink.add(jsonEncode({
        'action': 'subscribe',
        'symbol': symbol,
        'type': 'ticker',
      }));
      
    } catch (e) {
      debugPrint('Failed to connect WebSocket for $symbol: $e');
      _scheduleReconnect(symbol);
    }
  }
  
  void _handleIncomingData(String symbol, dynamic data) {
    try {
      final jsonData = jsonDecode(data);
      final symbolData = Symbol.fromJson(jsonData);
      
      // Add to batch queue for processing
      _updateQueue.add(symbolData);
      
      if (!_isBatching) {
        _processBatch();
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket data: $e');
    }
  }
  
  void _processBatch() {
    _isBatching = true;
    
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 100), () {
      final updates = <String, Symbol>{};
      
      // Process queued updates
      while (_updateQueue.isNotEmpty) {
        final symbolData = _updateQueue.removeFirst();
        updates[symbolData.symbol] = symbolData;
      }
      
      // Notify subscribers
      for (var entry in updates.entries) {
        final symbol = entry.key;
        final data = entry.value;
        
        if (_subscribers.containsKey(symbol)) {
          for (var callback in _subscribers[symbol]!) {
            callback(data);
          }
        }
      }
      
      _isBatching = false;
      
      if (_updateQueue.isNotEmpty) {
        _processBatch();
      }
    });
  }
  
  void _startBatchProcessor() {
    _batchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_updateQueue.isNotEmpty && !_isBatching) {
        _processBatch();
      }
    });
  }
  
  void _disconnectWebSocket(String symbol) {
    final channel = _channels[symbol];
    if (channel != null) {
      channel.sink.close();
      _channels.remove(symbol);
    }
    
    final timer = _heartbeatTimers[symbol];
    if (timer != null) {
      timer.cancel();
      _heartbeatTimers.remove(symbol);
    }
  }
  
  void _reconnectWebSocket(String symbol) {
    _disconnectWebSocket(symbol);
    _scheduleReconnect(symbol);
  }
  
  void _scheduleReconnect(String symbol) {
    Future.delayed(const Duration(seconds: 5), () {
      if (_subscribers.containsKey(symbol)) {
        _connectWebSocket(symbol);
      }
    });
  }
  
  void sendHeartbeat(String symbol) {
    final channel = _channels[symbol];
    if (channel != null) {
      channel.sink.add(jsonEncode({
        'action': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    }
  }
  
  void dispose() {
    for (var channel in _channels.values) {
      channel.sink.close();
    }
    _channels.clear();
    _subscribers.clear();
    
    for (var timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();
    
    _batchTimer?.cancel();
  }
}
