// lib/providers/broker_provider.dart
import 'package:flutter/material.dart';
import '../services/broker_manager.dart';

class BrokerProvider extends ChangeNotifier {
  final BrokerManager _brokerManager = BrokerManager();
  List<String> _connectedBrokers = [];
  
  List<String> get connectedBrokers => _connectedBrokers;
  
  BrokerProvider() {
    loadConnectedBrokers();
  }
  
  Future<void> loadConnectedBrokers() async {
    final allBrokers = _brokerManager.getAllBrokers();
    _connectedBrokers = allBrokers
        .where((b) => _brokerManager.isBrokerConnected(b.brokerId))
        .map((b) => b.brokerId)
        .toList();
    notifyListeners();
  }
  
  Future<void> connectBroker(String brokerId, Map<String, dynamic> credentials) async {
    final success = await _brokerManager.connectBroker(brokerId, credentials);
    if (success) {
      await loadConnectedBrokers();
    }
  }
  
  Future<void> disconnectBroker(String brokerId) async {
    await _brokerManager.disconnectBroker(brokerId);
    await loadConnectedBrokers();
  }
}
