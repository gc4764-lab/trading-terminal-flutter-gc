import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alert.dart';
import '../models/order.dart';
import '../providers/market_data_provider.dart';
import '../providers/order_provider.dart';

class AlertService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static List<Alert> _alerts = [];
  static Timer? _checkTimer;
  
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notifications.initialize(initializationSettings);
    
    // Start checking alerts every second
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      checkAlerts();
    });
  }
  
  static void addAlert(Alert alert) {
    _alerts.add(alert);
  }
  
  static void removeAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
  }
  
  static List<Alert> getActiveAlerts() {
    return _alerts.where((a) => a.isActive && !a.isTriggered).toList();
  }
  
  static void checkAlerts() {
    final marketData = MarketDataProvider();
    
    for (var alert in _alerts) {
      if (!alert.isActive || alert.isTriggered) continue;
      
      final symbol = marketData.getSymbol(alert.symbol);
      if (symbol == null) continue;
      
      if (alert.checkCondition(symbol.lastPrice)) {
        triggerAlert(alert);
      }
    }
  }
  
  static Future<void> triggerAlert(Alert alert) async {
    alert.isTriggered = true;
    alert.triggeredAt = DateTime.now();
    
    // Show notification
    await showNotification(alert);
    
    // Execute associated order if any
    if (alert.action != AlertAction.notification && alert.associatedOrder != null) {
      final orderProvider = OrderProvider();
      orderProvider.placeOrder(alert.associatedOrder!);
    }
  }
  
  static Future<void> showNotification(Alert alert) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'trading_alerts',
      'Trading Alerts',
      channelDescription: 'Notifications for price alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      alert.id.hashCode,
      'Price Alert',
      '${alert.symbol} ${alert.conditionText} ${alert.triggerPrice}',
      details,
    );
  }
  
  static void dispose() {
    _checkTimer?.cancel();
  }
}
