// lib/services/copy_trading_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/social_trader.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/market_data_provider.dart';

class CopyTradingService {
  static final CopyTradingService _instance = CopyTradingService._internal();
  factory CopyTradingService() => _instance;
  CopyTradingService._internal();
  
  final Map<String, List<String>> _copiedTraders = {}; // userId -> list of traderIds
  final Map<String, double> _copyAmounts = {}; // traderId -> amount
  final Map<String, bool> _copyStatus = {}; // traderId -> active
  Timer? _syncTimer;
  
  void startCopying(String userId, String traderId, double amount) {
    if (!_copiedTraders.containsKey(userId)) {
      _copiedTraders[userId] = [];
    }
    _copiedTraders[userId]!.add(traderId);
    _copyAmounts[traderId] = amount;
    _copyStatus[traderId] = true;
    
    _startSync();
  }
  
  void stopCopying(String userId, String traderId) {
    _copiedTraders[userId]?.remove(traderId);
    _copyAmounts.remove(traderId);
    _copyStatus.remove(traderId);
    
    if (_copiedTraders[userId]?.isEmpty ?? true) {
      _stopSync();
    }
  }
  
  void _startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _syncTrades();
    });
  }
  
  void _stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  Future<void> _syncTrades() async {
    for (var entry in _copiedTraders.entries) {
      final userId = entry.key;
      final traderIds = entry.value;
      
      for (var traderId in traderIds) {
        if (_copyStatus[traderId] == true) {
          await _copyTraderTrades(userId, traderId);
        }
      }
    }
  }
  
  Future<void> _copyTraderTrades(String userId, String traderId) async {
    // Fetch recent trades from trader
    final trades = await _getTraderTrades(traderId);
    final amount = _copyAmounts[traderId] ?? 0;
    
    for (var trade in trades) {
      if (_shouldCopyTrade(trade, userId)) {
        await _executeCopyTrade(userId, trade, amount);
      }
    }
  }
  
  Future<List<TradeCopy>> _getTraderTrades(String traderId) async {
    // Fetch from server/database
    return [];
  }
  
  bool _shouldCopyTrade(TradeCopy trade, String userId) {
    // Check if trade already copied
    return true;
  }
  
  Future<void> _executeCopyTrade(String userId, TradeCopy trade, double amount) async {
    // Calculate position size based on copy amount
    final positionSize = amount / trade.entryPrice * trade.quantity;
    
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: trade.symbol,
      type: OrderType.market,
      side: trade.side,
      quantity: positionSize,
      brokerId: userId,
      createdAt: DateTime.now(),
    );
    
    final orderProvider = OrderProvider();
    await orderProvider.placeOrder(order);
  }
  
  void dispose() {
    _syncTimer?.cancel();
  }
}
