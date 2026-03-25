import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/broker_manager.dart';

class BrokerConnectionDialog extends StatefulWidget {
  const BrokerConnectionDialog({Key? key}) : super(key: key);

  @override
  _BrokerConnectionDialogState createState() => _BrokerConnectionDialogState();
}

class _BrokerConnectionDialogState extends State<BrokerConnectionDialog> {
  String? _selectedBrokerId;
  final Map<String, TextEditingController> _controllers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeBrokers();
  }
  
  void _initializeBrokers() {
    final brokerManager = BrokerManager();
    brokerManager.initializeBrokers();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect Broker'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            _buildBrokerList(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCredentialsForm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _connectBroker,
          child: const Text('Connect'),
        ),
      ],
    );
  }
  
  Widget _buildBrokerList() {
    final brokerManager = BrokerManager();
    final brokers = brokerManager.getAllBrokers();
    
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brokers.length,
        itemBuilder: (context, index) {
          final broker = brokers[index];
          final isSelected = _selectedBrokerId == broker.brokerId;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBrokerId = broker.brokerId;
              });
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getBrokerIcon(broker.brokerId),
                    size: 32,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    broker.brokerName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  
  Widget _buildCredentialsForm() {
    if (_selectedBrokerId == null) {
      return const Center(
        child: Text('Select a broker to continue'),
      );
    }
    
    final credentials = _getCredentialsForBroker(_selectedBrokerId!);
    
    return ListView.builder(
      itemCount: credentials.length,
      itemBuilder: (context, index) {
        final cred = credentials[index];
        final controller = TextEditingController();
        _controllers[cred['key']] = controller;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextField(
            controller: controller,
            obscureText: cred['secure'] ?? false,
            decoration: InputDecoration(
              labelText: cred['label'],
              border: const OutlineInputBorder(),
            ),
          ),
        );
      },
    );
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
          {'key': 'server_url', 'label': 'Server URL', 'secure': false},
        ];
      case 'fxcm':
        return [
          {'key': 'username', 'label': 'Username', 'secure': false},
          {'key': 'password', 'label': 'Password', 'secure': true},
        ];
      case 'oanda':
        return [
          {'key': 'api_key', 'label': 'API Key', 'secure': true},
          {'key': 'practice', 'label': 'Practice Account', 'secure': false},
        ];
      default:
        return [];
    }
  }
  
  void _connectBroker() async {
    final credentials = <String, dynamic>{};
    
    for (var entry in _controllers.entries) {
      credentials[entry.key] = entry.value.text;
    }
    
    final brokerManager = BrokerManager();
    final success = await brokerManager.connectBroker(_selectedBrokerId!, credentials);
    
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${_selectedBrokerId} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to broker'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
