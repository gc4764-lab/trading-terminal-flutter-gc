import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../models/order.dart';
import '../providers/alert_provider.dart';
import '../services/alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    AlertService.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Alerts'),
              Tab(text: 'Alert History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateAlertDialog,
              tooltip: 'Create Alert',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildActiveAlerts(),
            _buildAlertHistory(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActiveAlerts() {
    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        final alerts = provider.activeAlerts;
        
        if (alerts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active alerts',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to create a new alert',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alert.isActive ? Colors.green : Colors.grey,
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${alert.symbol} ${alert.conditionText} ${alert.triggerPrice}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action: ${alert.action.toString().split('.').last}'),
                    if (alert.associatedOrder != null)
                      Text('Order: ${alert.associatedOrder!.sideText} ${alert.associatedOrder!.quantity}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: alert.isActive,
                      onChanged: (value) {
                        provider.toggleAlert(alert.id, value);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        provider.removeAlert(alert.id);
                      },
                    ),
                  ],
                ),
                onTap: () => _showEditAlertDialog(alert),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildAlertHistory() {
    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        final history = provider.alertHistory;
        
        if (history.isEmpty) {
          return const Center(
            child: Text('No alert history'),
          );
        }
        
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final alert = history[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alert.isTriggered ? Colors.orange : Colors.grey,
                  child: Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${alert.symbol} ${alert.conditionText} ${alert.triggerPrice}',
                ),
                subtitle: Text(
                  'Triggered: ${alert.triggeredAt?.toString() ?? 'Not triggered'}',
                ),
                trailing: Text(
                  alert.isTriggered ? 'Triggered' : 'Expired',
                  style: TextStyle(
                    color: alert.isTriggered ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _showCreateAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateAlertDialog(),
    );
  }
  
  void _showEditAlertDialog(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => EditAlertDialog(alert: alert),
    );
  }
}

class CreateAlertDialog extends StatefulWidget {
  const CreateAlertDialog({Key? key}) : super(key: key);

  @override
  _CreateAlertDialogState createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<CreateAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  String _symbol = '';
  AlertCondition _condition = AlertCondition.above;
  double _triggerPrice = 0;
  AlertAction _action = AlertAction.notification;
  Order? _associatedOrder;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Alert'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _symbol = value.toUpperCase(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter symbol';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AlertCondition>(
                  value: _condition,
                  items: AlertCondition.values.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(condition.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _condition = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Trigger Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _triggerPrice = double.tryParse(value) ?? 0,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter trigger price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AlertAction>(
                  value: _action,
                  items: AlertAction.values.map((action) {
                    return DropdownMenuItem(
                      value: action,
                      child: Text(action.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _action = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_action != AlertAction.notification) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createAssociatedOrder,
                    child: Text(
                      _associatedOrder == null 
                          ? 'Create Order' 
                          : 'Edit Order: ${_associatedOrder!.sideText} ${_associatedOrder!.quantity}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createAlert,
          child: const Text('Create'),
        ),
      ],
    );
  }
  
  void _createAssociatedOrder() {
    // Show order creation dialog
    // For simplicity, we'll use a placeholder
    setState(() {
      _associatedOrder = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: _symbol,
        type: OrderType.market,
        side: OrderSide.buy,
        quantity: 100,
        brokerId: 'demo',
        createdAt: DateTime.now(),
      );
    });
  }
  
  void _createAlert() {
    if (_formKey.currentState!.validate()) {
      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: _symbol,
        condition: _condition,
        triggerPrice: _triggerPrice,
        action: _action,
        associatedOrder: _associatedOrder,
        createdAt: DateTime.now(),
      );
      
      Provider.of<AlertProvider>(context, listen: false).addAlert(alert);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class EditAlertDialog extends StatefulWidget {
  final Alert alert;
  
  const EditAlertDialog({Key? key, required this.alert}) : super(key: key);

  @override
  _EditAlertDialogState createState() => _EditAlertDialogState();
}

class _EditAlertDialogState extends State<EditAlertDialog> {
  late TextEditingController _priceController;
  
  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.alert.triggerPrice.toString());
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Alert'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Symbol: ${widget.alert.symbol}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Trigger Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateAlert,
          child: const Text('Update'),
        ),
      ],
    );
  }
  
  void _updateAlert() {
    final newPrice = double.tryParse(_priceController.text);
    if (newPrice != null) {
      final updatedAlert = Alert(
        id: widget.alert.id,
        symbol: widget.alert.symbol,
        condition: widget.alert.condition,
        triggerPrice: newPrice,
        action: widget.alert.action,
        associatedOrder: widget.alert.associatedOrder,
        isActive: widget.alert.isActive,
        createdAt: widget.alert.createdAt,
      );
      
      Provider.of<AlertProvider>(context, listen: false).updateAlert(updatedAlert);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
