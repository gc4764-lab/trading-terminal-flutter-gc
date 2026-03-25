// lib/widgets/alert_order_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../models/order.dart';
import '../providers/alert_provider.dart';
import '../providers/order_provider.dart';

class AlertOrderDialog extends StatefulWidget {
  final String symbol;
  final double triggerPrice;
  final double currentPrice;
  
  const AlertOrderDialog({
    Key? key,
    required this.symbol,
    required this.triggerPrice,
    required this.currentPrice,
  }) : super(key: key);

  @override
  _AlertOrderDialogState createState() => _AlertOrderDialogState();
}

class _AlertOrderDialogState extends State<AlertOrderDialog> {
  AlertCondition _condition = AlertCondition.above;
  AlertAction _action = AlertAction.order;
  OrderType _orderType = OrderType.market;
  OrderSide _orderSide = OrderSide.buy;
  double _orderQuantity = 0;
  double? _orderLimitPrice;
  double? _orderStopPrice;
  bool _recurring = false;
  
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alert-Based Order'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert trigger section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alert Trigger',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<AlertCondition>(
                              value: _condition,
                              items: const [
                                DropdownMenuItem(value: AlertCondition.above, child: Text('Above')),
                                DropdownMenuItem(value: AlertCondition.below, child: Text('Below')),
                                DropdownMenuItem(value: AlertCondition.crossesAbove, child: Text('Crosses Above')),
                                DropdownMenuItem(value: AlertCondition.crossesBelow, child: Text('Crosses Below')),
                              ],
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
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: widget.triggerPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Trigger Price',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _recurring,
                            onChanged: (value) {
                              setState(() {
                                _recurring = value!;
                              });
                            },
                          ),
                          const Text('Recurring Alert (trigger multiple times)'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Order section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order to Execute',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      // Order side
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<OrderSide>(
                              segments: const [
                                ButtonSegment(value: OrderSide.buy, label: Text('BUY')),
                                ButtonSegment(value: OrderSide.sell, label: Text('SELL')),
                              ],
                              selected: {_orderSide},
                              onSelectionChanged: (Set<OrderSide> selection) {
                                setState(() {
                                  _orderSide = selection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Order type
                      DropdownButtonFormField<OrderType>(
                        value: _orderType,
                        items: const [
                          DropdownMenuItem(value: OrderType.market, child: Text('Market Order')),
                          DropdownMenuItem(value: OrderType.limit, child: Text('Limit Order')),
                          DropdownMenuItem(value: OrderType.stop, child: Text('Stop Order')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _orderType = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Order Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Quantity
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.format_list_numbered),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _orderQuantity = double.tryParse(value) ?? 0,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Price fields
                      if (_orderType != OrderType.market) ...[
                        if (_orderType == OrderType.limit)
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Limit Price',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _orderLimitPrice = double.tryParse(value),
                          ),
                        if (_orderType == OrderType.stop)
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Stop Price',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.stop),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _orderStopPrice = double.tryParse(value),
                          ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alert Summary',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('When ${widget.symbol} ${_getConditionText()} \$${_getTriggerPrice()}'),
                      Text('Execute ${_orderSide == OrderSide.buy ? 'BUY' : 'SELL'} $_orderQuantity ${widget.symbol}'),
                      if (_orderType != OrderType.market)
                        Text('at ${_orderType == OrderType.limit ? 'Limit' : 'Stop'} price: \$${_getOrderPrice()}'),
                      if (_recurring)
                        const Text('⚠️ Recurring: Will trigger multiple times'),
                    ],
                  ),
                ),
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
          onPressed: _createAlertOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Create Alert Order'),
        ),
      ],
    );
  }
  
  String _getConditionText() {
    switch (_condition) {
      case AlertCondition.above:
        return 'goes above';
      case AlertCondition.below:
        return 'goes below';
      case AlertCondition.crossesAbove:
        return 'crosses above';
      case AlertCondition.crossesBelow:
        return 'crosses below';
      default:
        return 'reaches';
    }
  }
  
  double _getTriggerPrice() {
    return widget.triggerPrice;
  }
  
  double _getOrderPrice() {
    return _orderLimitPrice ?? _orderStopPrice ?? 0;
  }
  
  void _createAlertOrder() {
    if (_formKey.currentState!.validate()) {
      // Create the order that will be executed when alert triggers
      final order = Order(
        id: 'alert_order_${DateTime.now().millisecondsSinceEpoch}',
        symbol: widget.symbol,
        type: _orderType,
        side: _orderSide,
        quantity: _orderQuantity,
        price: _orderLimitPrice,
        stopPrice: _orderStopPrice,
        brokerId: 'default',
        createdAt: DateTime.now(),
      );
      
      // Create the alert
      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: widget.symbol,
        condition: _condition,
        triggerPrice: widget.triggerPrice,
        action: AlertAction.order,
        associatedOrder: order,
        isActive: true,
        recurring: _recurring,
        createdAt: DateTime.now(),
      );
      
      // Save alert
      Provider.of<AlertProvider>(context, listen: false).addAlert(alert);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert-based order created successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

