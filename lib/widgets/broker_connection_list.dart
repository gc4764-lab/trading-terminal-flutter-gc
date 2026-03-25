// lib/widgets/broker_connection_list.dart
import 'package:flutter/material.dart';
import '../services/broker_manager.dart';

class BrokerConnectionList extends StatelessWidget {
  final List<String> connectedBrokers;
  final Function(String) onConnect;
  final Function(String) onDisconnect;
  
  const BrokerConnectionList({
    Key? key,
    required this.connectedBrokers,
    required this.onConnect,
    required this.onDisconnect,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final brokerManager = BrokerManager();
    final allBrokers = brokerManager.getAllBrokers();
    
    if (connectedBrokers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No brokers connected'),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: connectedBrokers.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final brokerId = connectedBrokers[index];
        final broker = allBrokers.firstWhere(
          (b) => b.brokerId == brokerId,
          orElse: () => throw Exception('Broker not found'),
        );
        
        return ListTile(
          leading: CircleAvatar(
            child: Icon(_getBrokerIcon(broker.brokerId)),
          ),
          title: Text(broker.brokerName),
          subtitle: Text('Connected'),
          trailing: IconButton(
            icon: const Icon(Icons.disconnect, color: Colors.red),
            onPressed: () => onDisconnect(brokerId),
            tooltip: 'Disconnect',
          ),
        );
      },
    );
  }
  
  IconData _getBrokerIcon(String brokerId) {
    switch (brokerId) {
      case 'fyers':
        return Icons.trending_up;
      case 'angel_one':
        return Icons.angel;
      case 'sharekhan':
        return Icons.share;
      case 'binance':
        return Icons.currency_bitcoin;
      default:
        return Icons.account_balance;
    }
  }
}
