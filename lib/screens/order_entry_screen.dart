import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';

class OrderEntryScreen extends StatefulWidget {
  const OrderEntryScreen({Key? key}) : super(key: key);

  @override
  _OrderEntryScreenState createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _symbol = '';
  OrderSide _side = OrderSide.buy;
  OrderType _type = OrderType.market;
  double _quantity = 0;
  double? _price;
  double? _stopPrice;
  TimeInForce _timeInForce = TimeInForce.day;
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Entry'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Place Order'),
              Tab(text: 'Active Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderForm(),
            _buildActiveOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Symbol Input
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Symbol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
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
            
            // Side and Type
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<OrderSide>(
                    segments: const [
                      ButtonSegment(value: OrderSide.buy, label: Text('BUY'), icon: Icon(Icons.trending_up)),
                      ButtonSegment(value: OrderSide.sell, label: Text('SELL'), icon: Icon(Icons.trending_down)),
                    ],
                    selected: {_side},
                    onSelectionChanged: (Set<OrderSide> selection) {
                      setState(() {
                        _side = selection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<OrderType>(
                    value: _type,
                    items: OrderType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _type = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Order Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
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
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Price Fields (for limit/stop orders)
            if (_type != OrderType.market) ...[
              if (_type == OrderType.limit)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Limit Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _price = double.tryParse(value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter limit price';
                    }
                    return null;
                  },
                ),
                
              if (_type == OrderType.stop || _type == OrderType.stopLimit)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Stop Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.stop),
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
                
              if (_type == OrderType.stopLimit)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Limit Price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _price = double.tryParse(value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter limit price';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
            ],
            
            // Time in Force
            DropdownButtonFormField<TimeInForce>(
              value: _timeInForce,
              items: const [
                DropdownMenuItem(value: TimeInForce.day, child: Text('Day')),
                DropdownMenuItem(value: TimeInForce.gtc, child: Text('GTC')),
                DropdownMenuItem(value: TimeInForce.ioc, child: Text('IOC')),
                DropdownMenuItem(value: TimeInForce.fok, child: Text('FOK')),
              ],
              onChanged: (value) {
                setState(() {
                  _timeInForce = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Time in Force',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _side == OrderSide.buy ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _side == OrderSide.buy ? 'BUY $_symbol' : 'SELL $_symbol',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrders() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final activeOrders = provider.activeOrders;
        
        if (activeOrders.isEmpty) {
          return const Center(
            child: Text('No active orders'),
          );
        }
        
        return ListView.builder(
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  '${order.sideText} ${order.quantity} ${order.symbol} @ ${order.price?.toStringAsFixed(2) ?? 'Market'}',
                  style: TextStyle(
                    color: order.sideColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Type: ${order.type.toString().split('.').last} | Status: ${order.status}'),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => provider.cancelOrder(order.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        symbol: _symbol,
        type: _type,
        side: _side,
        quantity: _quantity,
        price: _price,
        stopPrice: _stopPrice,
        brokerId: 'default',
        timeInForce: _timeInForce,
        createdAt: DateTime.now(),
      );
      
      Provider.of<OrderProvider>(context, listen: false).placeOrder(order);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed: ${order.sideText} ${order.quantity} ${order.symbol}'),
          backgroundColor: order.sideColor,
        ),
      );
      
      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        _quantity = 0;
        _price = null;
        _stopPrice = null;
      });
    }
  }
}
