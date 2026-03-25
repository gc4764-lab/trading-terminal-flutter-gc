// lib/widgets/broker_auth_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/broker_manager.dart';
import '../services/secure_storage_service.dart';

class BrokerAuthDialog extends StatefulWidget {
  final String brokerId;
  
  const BrokerAuthDialog({Key? key, required this.brokerId}) : super(key: key);

  @override
  _BrokerAuthDialogState createState() => _BrokerAuthDialogState();
}

class _BrokerAuthDialogState extends State<BrokerAuthDialog> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadStoredCredentials();
  }
  
  Future<void> _loadStoredCredentials() async {
    final broker = BrokerManager().getBroker(widget.brokerId);
    if (broker != null && await broker.hasStoredCredentials()) {
      final creds = await broker.loadCredentials();
      for (var entry in creds.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]!.text = entry.value;
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final credentials = _getCredentialsForBroker(widget.brokerId);
    
    return AlertDialog(
      title: Text('Connect to ${widget.brokerId.toUpperCase()}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...credentials.map((cred) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers.putIfAbsent(cred['key'], () => TextEditingController()),
                obscureText: cred['secure'] ?? false,
                decoration: InputDecoration(
                  labelText: cred['label'],
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
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
          onPressed: _authenticate,
          child: const Text('Connect'),
        ),
      ],
    );
  }
  
  List<Map<String, dynamic>> _getCredentialsForBroker(String brokerId) {
    // Return the list of credential fields for the specific broker
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
      // Add other brokers...
      default:
        return [];
    }
  }
  
  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final credentials = <String, dynamic>{};
    for (var entry in _controllers.entries) {
      credentials[entry.key] = entry.value.text;
    }
    
    final broker = BrokerManager().getBroker(widget.brokerId);
    if (broker == null) {
      setState(() {
        _error = 'Broker not found';
        _isLoading = false;
      });
      return;
    }
    
    final response = await broker.login(credentials);
    
    setState(() {
      _isLoading = false;
    });
    
    if (response.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${widget.brokerId} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _error = response.error ?? 'Authentication failed';
      });
    }
  }
}