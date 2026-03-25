import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/risk_settings.dart';
import '../models/order.dart';

class RiskProvider extends ChangeNotifier {
  RiskSettings _settings = RiskSettings.defaultSettings();
  double _dailyPnL = 0.0;
  int _openPositions = 0;
  
  RiskSettings get settings => _settings;
  double get dailyPnL => _dailyPnL;
  int get openPositions => _openPositions;
  
  RiskProvider() {
    loadSettings();
  }
  
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('risk_settings');
    
    if (settingsJson != null) {
      _settings = RiskSettings.fromJson(jsonDecode(settingsJson));
    }
    
    notifyListeners();
  }
  
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('risk_settings', jsonEncode(_settings.toJson()));
  }
  
  void updateSettings(RiskSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }
  
  String? validateOrder(Order order, double accountBalance, double currentPositionValue) {
    // Check trading hours
    if (_settings.restrictTradingHours) {
      final now = TimeOfDay.now();
      if (!_isWithinTradingHours(now)) {
        return 'Trading is restricted outside of allowed hours';
      }
    }
    
    // Check symbol restrictions
    if (_settings.restrictedSymbols.contains(order.symbol)) {
      return '${order.symbol} is restricted from trading';
    }
    
    if (_settings.allowedSymbols.isNotEmpty && 
        !_settings.allowedSymbols.contains(order.symbol)) {
      return '${order.symbol} is not in allowed symbols list';
    }
    
    // Check position size limits
    final positionValue = order.quantity * (order.price ?? 0);
    final maxPositionValue = accountBalance * (_settings.maxPositionSizePercent / 100);
    
    if (positionValue > maxPositionValue) {
      return 'Position size exceeds maximum allowed (${_settings.maxPositionSizePercent}% of account)';
    }
    
    // Check daily loss limit
    final dailyLossLimit = accountBalance * (_settings.maxDailyLossPercent / 100);
    if (_dailyPnL < -dailyLossLimit) {
      return 'Daily loss limit reached (${_settings.maxDailyLossPercent}%)';
    }
    
    // Check risk per trade
    final riskAmount = _calculateRiskAmount(order, accountBalance);
    final maxRiskAmount = accountBalance * (_settings.maxRiskPerTradePercent / 100);
    
    if (riskAmount > maxRiskAmount) {
      return 'Risk per trade exceeds limit (${_settings.maxRiskPerTradePercent}%)';
    }
    
    // Check order size limits
    if (_settings.maxOrderValue != null && positionValue > _settings.maxOrderValue!) {
      return 'Order value exceeds maximum allowed (${_settings.maxOrderValue})';
    }
    
    if (_settings.maxOrderQuantity != null && order.quantity > _settings.maxOrderQuantity!) {
      return 'Order quantity exceeds maximum allowed (${_settings.maxOrderQuantity})';
    }
    
    // Check open positions limit
    if (_openPositions >= _settings.maxOpenPositions) {
      return 'Maximum number of open positions reached (${_settings.maxOpenPositions})';
    }
    
    // Check leverage
    final leverage = (currentPositionValue + positionValue) / accountBalance;
    if (leverage > _settings.maxLeverage) {
      return 'Leverage exceeds maximum allowed (${_settings.maxLeverage}x)';
    }
    
    return null;
  }
  
  double _calculateRiskAmount(Order order, double accountBalance) {
    if (order.type == OrderType.market && _settings.defaultStopLossPercent > 0) {
      // Calculate risk based on stop loss
      final stopLossPrice = (order.side == OrderSide.buy) 
          ? (order.price ?? 0) * (1 - _settings.defaultStopLossPercent / 100)
          : (order.price ?? 0) * (1 + _settings.defaultStopLossPercent / 100);
      
      final riskPerShare = (order.price ?? 0) - stopLossPrice;
      return riskPerShare.abs() * order.quantity;
    }
    
    return 0;
  }
  
  bool _isWithinTradingHours(TimeOfDay now) {
    final startMinutes = _settings.tradingStartTime.hour * 60 + _settings.tradingStartTime.minute;
    final endMinutes = _settings.tradingEndTime.hour * 60 + _settings.tradingEndTime.minute;
    final currentMinutes = now.hour * 60 + now.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight session
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
  
  void updateDailyPnL(double pnl) {
    _dailyPnL = pnl;
    notifyListeners();
  }
  
  void updateOpenPositions(int count) {
    _openPositions = count;
    notifyListeners();
  }
  
  double calculatePositionSize(double accountBalance, double entryPrice, double stopLossPrice) {
    final riskAmount = accountBalance * (_settings.maxRiskPerTradePercent / 100);
    final riskPerShare = (entryPrice - stopLossPrice).abs();
    
    if (riskPerShare == 0) return 0;
    
    return riskAmount / riskPerShare;
  }
}
