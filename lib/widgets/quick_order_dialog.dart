// lib/widgets/quick_order_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/risk_provider.dart';

class QuickOrderDialog extends StatefulWidget {
  final String symbol;
  final double defaultPrice;
  final double currentPrice;
  
  const QuickOrderDialog({
    Key? key,
    required this.symbol,
    required this.defaultPrice,
    required this.currentPrice,
  }) : super(key: key);

  @override
  _QuickOrderDialogState createState() => _QuickOrderDialogState();
}

class _QuickOrderDialogState extends State<QuickOrderDialog> {
  OrderSide _side = OrderSide.buy;
  OrderType _type = OrderType.market;
  double _quantity = 0;
  double? _limitPrice;
  double? _stopPrice;
  double? _takeProfit;
  double? _stopLoss;
  bool _useRiskManagement = true;
  
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text('Place Order - ${widget.symbol}'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Current: \$${widget.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order Side Toggle
                SegmentedButton<OrderSide>(
                  segments: const [
                    ButtonSegment(
                      value: OrderSide.buy,
                      label: Text('BUY'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment(
                      value: OrderSide.sell,
                      label: Text('SELL'),
                      icon: Icon(Icons.trending_down),
                    ),
                  ],
                  selected: {_side},
                  onSelectionChanged: (Set<OrderSide> selection) {
                    setState(() {
                      _side = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Order Type
                DropdownButtonFormField<OrderType>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: OrderType.market, child: Text('Market Order')),
                    DropdownMenuItem(value: OrderType.limit, child: Text('Limit Order')),
                    DropdownMenuItem(value: OrderType.stop, child: Text('Stop Order')),
                    DropdownMenuItem(value: OrderType.stopLimit, child: Text('Stop-Limit Order')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                      if (_type == OrderType.market) {
                        _limitPrice = null;
                        _stopPrice = null;
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Order Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quantity
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _quantity = double.tryParse(value) ?? 0,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Price fields based on order type
                if (_type != OrderType.market) ...[
                  if (_type == OrderType.limit || _type == OrderType.stopLimit)
                    TextFormField(
                      initialValue: widget.defaultPrice.toString(),
                      decoration: InputDecoration(
                        labelText: _type == OrderType.limit ? 'Limit Price' : 'Limit Price',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: _type == OrderType.limit ? 'Click on chart to set' : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _limitPrice = double.tryParse(value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter limit price';
                        }
                        return null;
                      },
                    ),
                  
                  if (_type == OrderType.stop || _type == OrderType.stopLimit)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Stop Price',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.stop),
                        suffixText: 'Click on chart to set',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _stopPrice = double.tryParse(value),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stop price';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                ],
                
                // Risk Management Section
                if (_useRiskManagement) ...[
                  const Divider(),
                  const Text(
                    'Risk Management',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Stop Loss',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pause_circle_outline),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _stopLoss = double.tryParse(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Take Profit',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.play_circle_outline),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _takeProfit = double.tryParse(value),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Risk info
                Consumer<RiskProvider>(
                  builder: (context, riskProvider, _) {
                    final settings = riskProvider.settings;
                    final maxRisk = riskProvider.settings.maxRiskPerTradePercent;
                    
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.security, size: 16),
                              const SizedBox(width: 4),
                              Text('Risk: ${maxRisk.toStringAsFixed(1)}% of account'),
                              const Spacer(),
                              Text('Max Position: ${settings.maxPositionSizePercent}%'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimated Risk: \$${_calculateRisk().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
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
          onPressed: _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: _side == OrderSide.buy ? Colors.green : Colors.red,
          ),
          child: Text(
            _side == OrderSide.buy ? 'BUY' : 'SELL',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
  
  double _calculateRisk() {
    if (_type == OrderType.market && _stopLoss != null) {
      final riskPerShare = (_stopLoss! - widget.defaultPrice).abs();
      return riskPerShare * _quantity;
    }
    return 0;
  }
  
  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: widget.symbol,
        type: _type,
        side: _side,
        quantity: _quantity,
        price: _limitPrice ?? (_type == OrderType.market ? widget.currentPrice : null),
        stopPrice: _stopPrice,
        brokerId: 'default',
        createdAt: DateTime.now(),
        stopLoss: _stopLoss,
        takeProfit: _takeProfit,
      );
      
      Provider.of<OrderProvider>(context, listen: false).placeOrder(order);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed: ${_side == OrderSide.buy ? 'BUY' : 'SELL'} $_quantity ${widget.symbol}'),
          backgroundColor: _side == OrderSide.buy ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
