import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/alert.dart';
import '../services/alert_service.dart';

class AlertProvider extends ChangeNotifier {
  List<Alert> _alerts = [];
  
  List<Alert> get alerts => _alerts;
  List<Alert> get activeAlerts => _alerts.where((a) => a.isActive && !a.isTriggered).toList();
  List<Alert> get alertHistory => _alerts.where((a) => a.isTriggered || !a.isActive).toList();
  
  AlertProvider() {
    loadAlerts();
  }
  
  Future<void> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getStringList('alerts');
    
    if (alertsJson != null) {
      _alerts = alertsJson
          .map((json) => Alert.fromJson(jsonDecode(json)))
          .toList();
    }
    
    // Register alerts with service
    for (var alert in _alerts) {
      if (alert.isActive && !alert.isTriggered) {
        AlertService.addAlert(alert);
      }
    }
    
    notifyListeners();
  }
  
  Future<void> saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = _alerts
        .map((alert) => jsonEncode(alert.toJson()))
        .toList();
    await prefs.setStringList('alerts', alertsJson);
  }
  
  void addAlert(Alert alert) {
    _alerts.add(alert);
    AlertService.addAlert(alert);
    saveAlerts();
    notifyListeners();
  }
  
  void updateAlert(Alert alert) {
    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      _alerts[index] = alert;
      saveAlerts();
      notifyListeners();
    }
  }
  
  void removeAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
    AlertService.removeAlert(alertId);
    saveAlerts();
    notifyListeners();
  }
  
  void toggleAlert(String alertId, bool isActive) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].isActive = isActive;
      
      if (isActive && !_alerts[index].isTriggered) {
        AlertService.addAlert(_alerts[index]);
      } else {
        AlertService.removeAlert(alertId);
      }
      
      saveAlerts();
      notifyListeners();
    }
  }
}
