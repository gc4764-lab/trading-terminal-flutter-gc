// lib/widgets/create_alert_from_chart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../providers/alert_provider.dart';

class CreateAlertFromChartDialog extends StatefulWidget {
  final String symbol;
  final double price;
  final double currentPrice;
  
  const CreateAlertFromChartDialog({
    Key? key,
    required this.symbol,
    required this.price,
    required this.currentPrice,
  }) : super(key: key);

  @override
  _CreateAlertFromChartDialogState createState() => _CreateAlertFromChartDialogState();
}

class _CreateAlertFromChartDialogState extends State<CreateAlertFromChartDialog> {
  AlertCondition _condition = AlertCondition.above;
  String _notes = '';
  bool _soundEnabled = true;
  bool _pushNotification = true;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Price Alert'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Current: \$${widget.currentPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<AlertCondition>(
                          value: _condition,
                          items: const [
                            DropdownMenuItem(value: AlertCondition.above, child: Text('Alert when price goes above')),
                            DropdownMenuItem(value: AlertCondition.below, child: Text('Alert when price goes below')),
                            DropdownMenuItem(value: AlertCondition.crossesAbove, child: Text('Alert when price crosses above')),
                            DropdownMenuItem(value: AlertCondition.crossesBelow, child: Text('Alert when price crosses below')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _condition = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('\$${widget.price.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Alert notes
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Add a note for this alert...',
              ),
              onChanged: (value) => _notes = value,
            ),
            
            const SizedBox(height: 16),
            
            // Notification settings
            const Text(
              'Notification Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Sound Alert'),
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Push Notification'),
              value: _pushNotification,
              onChanged: (value) {
                setState(() {
                  _pushNotification = value;
                });
              },
              dense: true,
            ),
            
            const SizedBox(height: 8),
            
            // Price difference info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getPriceDifferenceColor(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(_getPriceDifferenceIcon(), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getPriceDifferenceText(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
          onPressed: _createAlert,
          child: const Text('Create Alert'),
        ),
      ],
    );
  }
  
  Color _getPriceDifferenceColor() {
    final difference = widget.price - widget.currentPrice;
    final percentChange = (difference / widget.currentPrice) * 100;
    
    if (percentChange > 0) return Colors.green.withOpacity(0.2);
    if (percentChange < 0) return Colors.red.withOpacity(0.2);
    return Colors.grey.withOpacity(0.2);
  }
  
  IconData _getPriceDifferenceIcon() {
    final difference = widget.price - widget.currentPrice;
    if (difference > 0) return Icons.trending_up;
    if (difference < 0) return Icons.trending_down;
    return Icons.remove;
  }
  
  String _getPriceDifferenceText() {
    final difference = widget.price - widget.currentPrice;
    final percentChange = (difference / widget.currentPrice) * 100;
    
    if (difference > 0) {
      return 'Alert will trigger when price increases by \$${difference.toStringAsFixed(2)} (${percentChange.toStringAsFixed(2)}%)';
    } else if (difference < 0) {
      return 'Alert will trigger when price decreases by \$${difference.abs().toStringAsFixed(2)} (${percentChange.abs().toStringAsFixed(2)}%)';
    } else {
      return 'Alert will trigger at current price';
    }
  }
  
  void _createAlert() {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: widget.symbol,
      condition: _condition,
      triggerPrice: widget.price,
      action: AlertAction.notification,
      notes: _notes,
      soundEnabled: _soundEnabled,
      pushNotification: _pushNotification,
      isActive: true,
      createdAt: DateTime.now(),
    );
    
    Provider.of<AlertProvider>(context, listen: false).addAlert(alert);
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert created for ${widget.symbol} at \$${widget.price.toStringAsFixed(2)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
