// lib/widgets/broker_management_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/broker_manager.dart';
import '../providers/broker_provider.dart';

class BrokerManagementWidget extends StatefulWidget {
  const BrokerManagementWidget({Key? key}) : super(key: key);

  @override
  _BrokerManagementWidgetState createState() => _BrokerManagementWidgetState();
}

class _BrokerManagementWidgetState extends State<BrokerManagementWidget> {
  final BrokerManager _brokerManager = BrokerManager();
  
  @override
  void initState() {
    super.initState();
    _brokerManager.initializeBrokers();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerProvider>(
      builder: (context, provider, _) {
        final connectedBrokers = provider.connectedBrokers;
        final availableBrokers = _brokerManager.getAllBrokers();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connected Brokers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (connectedBrokers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No brokers connected'),
                  ),
                )
              else
                ...connectedBrokers.map((brokerId) => 
                  _buildBrokerCard(brokerId, provider)
                ),
              
              const Divider(height: 32),
              
              const Text(
                'Available Brokers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableBrokers.map((broker) {
                  final isConnected = connectedBrokers.contains(broker.brokerId);
                  return _buildBrokerButton(broker, isConnected, provider);
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildBrokerCard(String brokerId, BrokerProvider provider) {
    final broker = _brokerManager.getBroker(brokerId);
    if (broker == null) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: Icon(
            _getBrokerIcon(brokerId),
            color: Colors.green,
          ),
        ),
        title: Text(broker.brokerName),
        subtitle: Text('Connected • ${broker.brokerId.toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: () => _showAccountDetails(brokerId),
              tooltip: 'Account Details',
            ),
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _refreshBrokerData(brokerId),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.disconnect, color: Colors.red),
              onPressed: () => _disconnectBroker(brokerId, provider),
              tooltip: 'Disconnect',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBrokerButton(BaseBroker broker, bool isConnected, BrokerProvider provider) {
    return ElevatedButton.icon(
      onPressed: isConnected ? null : () => _connectBroker(broker.brokerId, provider),
      icon: Icon(_getBrokerIcon(broker.brokerId)),
      label: Text(broker.brokerName),
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected ? Colors.green : null,
      ),
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
      case 'dhan':
        return Icons.account_balance;
      case 'mt4_demo':
      case 'mt5_demo':
        return Icons.show_chart;
      case 'fxcm':
      case 'oanda':
        return Icons.currency_exchange;
      default:
        return Icons.broken_image;
    }
  }
  
  Future<void> _connectBroker(String brokerId, BrokerProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BrokerConnectionDialog(brokerId: brokerId),
    );
    
    if (result == true) {
      await provider.loadConnectedBrokers();
    }
  }
  
  Future<void> _disconnectBroker(String brokerId, BrokerProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Broker'),
        content: Text('Are you sure you want to disconnect from ${brokerId.toUpperCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await provider.disconnectBroker(brokerId);
    }
  }
  
  void _showAccountDetails(String brokerId) {
    // Show account details dialog
    showDialog(
      context: context,
      builder: (context) => BrokerAccountDialog(brokerId: brokerId),
    );
  }
  
  void _refreshBrokerData(String brokerId) {
    // Refresh broker data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing data for $brokerId...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class BrokerConnectionDialog extends StatefulWidget {
  final String brokerId;
  
  const BrokerConnectionDialog({Key? key, required this.brokerId}) : super(key: key);

  @override
  _BrokerConnectionDialogState createState() => _BrokerConnectionDialogState();
}

class _BrokerConnectionDialogState extends State<BrokerConnectionDialog> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isConnecting = false;
  
  @override
  void initState() {
    super.initState();
    _initControllers();
  }
  
  void _initControllers() {
    final credentials = _getCredentialsForBroker(widget.brokerId);
    for (var cred in credentials) {
      _controllers[cred['key']] = TextEditingController();
    }
  }
  
  List<Map<String, dynamic>> _getCredentialsForBroker(String brokerId) {
    switch (brokerId) {
      case 'fyers':
        return [
          {'key': 'apiKey', 'label': 'App ID', 'secure': false},
          {'key': 'apiSecret', 'label': 'Secret Key', 'secure': true},
          {'key': 'authCode', 'label': 'Authorization Code', 'secure': true},
        ];
      case 'angel_one':
        return [
          {'key': 'apiKey', 'label': 'API Key', 'secure': false},
          {'key': 'clientId', 'label': 'Client ID', 'secure': false},
          {'key': 'password', 'label': 'Password', 'secure': true},
          {'key': 'totp', 'label': 'TOTP (if enabled)', 'secure': true},
        ];
      case 'sharekhan':
        return [
          {'key': 'userId', 'label': 'User ID', 'secure': false},
          {'key': 'password', 'label': 'Password', 'secure': true},
          {'key': 'apiKey', 'label': 'API Key', 'secure': false},
        ];
      case 'binance':
        return [
          {'key': 'apiKey', 'label': 'API Key', 'secure': false},
          {'key': 'apiSecret', 'label': 'API Secret', 'secure': true},
        ];
      case 'dhan':
        return [
          {'key': 'clientId', 'label': 'Client ID', 'secure': false},
          {'key': 'password', 'label': 'Password', 'secure': true},
          {'key': 'twofa', 'label': '2FA Code', 'secure': true},
        ];
      case 'mt4_demo':
      case 'mt5_demo':
        return [
          {'key': 'login', 'label': 'Login', 'secure': false},
          {'key': 'password', 'label': 'Password', 'secure': true},
          {'key': 'server', 'label': 'Server', 'secure': false},
        ];
      default:
        return [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Connect to ${widget.brokerId.toUpperCase()}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._controllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: entry.value,
                obscureText: _isSecureField(entry.key),
                decoration: InputDecoration(
                  labelText: _getFieldLabel(entry.key),
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            if (_isConnecting)
              const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _connect,
          child: const Text('Connect'),
        ),
      ],
    );
  }
  
  bool _isSecureField(String key) {
    return key.contains('secret') || key.contains('password') || key == 'authCode';
  }
  
  String _getFieldLabel(String key) {
    switch (key) {
      case 'apiKey': return 'API Key';
      case 'apiSecret': return 'API Secret';
      case 'authCode': return 'Authorization Code';
      case 'clientId': return 'Client ID';
      case 'password': return 'Password';
      case 'totp': return 'TOTP Code';
      case 'userId': return 'User ID';
      case 'login': return 'Login';
      case 'server': return 'Server';
      default: return key;
    }
  }
  
  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    
    final credentials = <String, dynamic>{};
    for (var entry in _controllers.entries) {
      credentials[entry.key] = entry.value.text;
    }
    
    final brokerManager = BrokerManager();
    final success = await brokerManager.connectBroker(widget.brokerId, credentials);
    
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${widget.brokerId} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to broker'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
