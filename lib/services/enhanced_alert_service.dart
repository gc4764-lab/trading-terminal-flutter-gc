// lib/services/enhanced_alert_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alert.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/market_data_provider.dart';

class EnhancedAlertService {
  static final EnhancedAlertService _instance = EnhancedAlertService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, Timer> _alertTimers = {};
  final Map<String, DateTime> _lastTriggerTime = {};
  
  factory EnhancedAlertService() => _instance;
  EnhancedAlertService._internal();
  
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(initializationSettings);
  }
  
  Future<void> checkAndTriggerAlerts(
    List<Alert> alerts,
    Map<String, double> currentPrices,
    Function(Alert) onAlertTriggered,
  ) async {
    for (var alert in alerts) {
      if (!alert.isActive) continue;
      
      // Check for recurring alerts cooldown
      if (!alert.recurring && _lastTriggerTime.containsKey(alert.id)) {
        continue;
      }
      
      // Check cooldown period for recurring alerts
      if (alert.recurring && _lastTriggerTime.containsKey(alert.id)) {
        final lastTrigger = _lastTriggerTime[alert.id]!;
        final cooldownPeriod = alert.cooldownMinutes ?? 1;
        if (DateTime.now().difference(lastTrigger).inMinutes < cooldownPeriod) {
          continue;
        }
      }
      
      final currentPrice = currentPrices[alert.symbol];
      if (currentPrice == null) continue;
      
      bool shouldTrigger = false;
      double? previousPrice;
      
      // Check for cross conditions (need previous price)
      if (alert.condition == AlertCondition.crossesAbove || 
          alert.condition == AlertCondition.crossesBelow) {
        previousPrice = currentPrices['${alert.symbol}_prev'];
      }
      
      shouldTrigger = _evaluateCondition(
        alert.condition,
        currentPrice,
        alert.triggerPrice,
        previousPrice,
      );
      
      if (shouldTrigger) {
        await _triggerAlert(alert, currentPrice, onAlertTriggered);
        _lastTriggerTime[alert.id] = DateTime.now();
        
        if (!alert.recurring) {
          alert.isActive = false;
        }
      }
    }
  }
  
  bool _evaluateCondition(
    AlertCondition condition,
    double currentPrice,
    double triggerPrice,
    double? previousPrice,
  ) {
    switch (condition) {
      case AlertCondition.above:
        return currentPrice > triggerPrice;
      case AlertCondition.below:
        return currentPrice < triggerPrice;
      case AlertCondition.crossesAbove:
        return previousPrice != null && 
               previousPrice <= triggerPrice && 
               currentPrice > triggerPrice;
      case AlertCondition.crossesBelow:
        return previousPrice != null && 
               previousPrice >= triggerPrice && 
               currentPrice < triggerPrice;
      default:
        return false;
    }
  }
  
  Future<void> _triggerAlert(
    Alert alert,
    double currentPrice,
    Function(Alert) onAlertTriggered,
  ) async {
    // Show notification
    await _showNotification(alert, currentPrice);
    
    // Play sound if enabled
    if (alert.soundEnabled) {
      await _playAlertSound();
    }
    
    // Execute associated order if exists
    if (alert.associatedOrder != null && alert.action != AlertAction.notification) {
      await _executeOrder(alert.associatedOrder!);
    }
    
    // Callback for UI update
    onAlertTriggered(alert);
    
    // Log alert trigger
    debugPrint('Alert triggered: ${alert.symbol} at ${currentPrice.toStringAsFixed(2)}');
  }
  
  Future<void> _showNotification(Alert alert, double currentPrice) async {
    final androidDetails = AndroidNotificationDetails(
      'trading_alerts',
      'Trading Alerts',
      channelDescription: 'Price alerts and order notifications',
      importance: Importance.high,
      priority: Priority.high,
      sound: alert.soundEnabled ? RawResourceAndroidNotificationSound('alert_sound') : null,
    );
    
    final iosDetails = DarwinNotificationDetails(
      sound: alert.soundEnabled ? 'alert_sound.caf' : null,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final title = 'Price Alert - ${alert.symbol}';
    final body = 'Price ${alert.condition == AlertCondition.above ? 'above' : 'below'} '
                 '\$${alert.triggerPrice.toStringAsFixed(2)} '
                 'Current: \$${currentPrice.toStringAsFixed(2)}';
    
    await _notifications.show(
      alert.id.hashCode,
      title,
      body,
      details,
    );
  }
  
  Future<void> _playAlertSound() async {
    // Platform-specific sound playback
    // This would integrate with platform channels for sound
    debugPrint('Playing alert sound');
  }
  
  Future<void> _executeOrder(Order order) async {
    try {
      final orderProvider = OrderProvider();
      await orderProvider.placeOrder(order);
      
      // Send confirmation notification
      await _notifications.show(
        order.id.hashCode,
        'Order Executed',
        '${order.side == OrderSide.buy ? 'Bought' : 'Sold'} ${order.quantity} ${order.symbol}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_executions',
            'Order Executions',
            importance: Importance.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to execute alert order: $e');
      
      // Send error notification
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.hashCode,
        'Order Execution Failed',
        'Failed to execute order for ${order.symbol}: $e',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_errors',
            'Order Errors',
            importance: Importance.high,
          ),
        ),
      );
    }
  }
  
  Future<void> scheduleAlertCheck(
    List<Alert> alerts,
    MarketDataProvider marketData,
    Function(Alert) onAlertTriggered,
  ) {
    return Timer.periodic(const Duration(seconds: 1), (timer) async {
      final currentPrices = <String, double>{};
      
      for (var alert in alerts) {
        if (!alert.isActive) continue;
        
        final symbolData = marketData.getSymbol(alert.symbol);
        if (symbolData != null) {
          currentPrices[alert.symbol] = symbolData.lastPrice;
          // Store previous price for cross detection
          currentPrices['${alert.symbol}_prev'] = symbolData.previousPrice ?? symbolData.lastPrice;
        }
      }
      
      await checkAndTriggerAlerts(alerts, currentPrices, onAlertTriggered);
    });
  }
  
  void dispose() {
    for (var timer in _alertTimers.values) {
      timer.cancel();
    }
    _alertTimers.clear();
    _lastTriggerTime.clear();
  }
}
