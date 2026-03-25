import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:draggable_home/draggable_home.dart';
import '../providers/multi_window_provider.dart';
import '../widgets/market_watch_widget.dart';
import '../widgets/chart_widget.dart';
import '../widgets/order_book_widget.dart';
import 'order_entry_screen.dart';
import 'alerts_screen.dart';
import 'risk_settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const TradingWorkspace(),
    const OrderEntryScreen(),
    const AlertsScreen(),
    const RiskSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Trading Terminal'),
      actions: [
        // New Window Button
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: _openNewWindow,
          tooltip: 'Open in new window',
        ),
        
        // Broker Connection Status
        Consumer<MultiWindowProvider>(
          builder: (context, provider, _) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.account_balance),
              onSelected: (value) {
                if (value == 'connect') {
                  _showBrokerDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'connect',
                  child: Text('Connect Broker'),
                ),
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Text('Disconnect'),
                ),
              ],
            );
          },
        ),
        
        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Show settings
          },
        ),
        
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Trading',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_shopping_cart),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.security),
          label: 'Risk',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showQuickOrderDialog();
      },
      child: const Icon(Icons.add),
      tooltip: 'Quick Order',
    );
  }

  void _openNewWindow() {
    final provider = Provider.of<MultiWindowProvider>(context, listen: false);
    provider.openNewWindow('Trading Window');
  }

  void _showBrokerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect Broker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select broker to connect:'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Connect to broker
                Navigator.pop(context);
              },
              child: const Text('Demo Broker'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => const QuickOrderDialog(),
    );
  }
}

class TradingWorkspace extends StatefulWidget {
  const TradingWorkspace({Key? key}) : super(key: key);

  @override
  _TradingWorkspaceState createState() => _TradingWorkspaceState();
}

class _TradingWorkspaceState extends State<TradingWorkspace> {
  String _selectedSymbol = 'AAPL';
  String _timeFrame = '1h';
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          // Desktop/Tablet layout - multiple columns
          return Row(
            children: [
              // Market Watch (Left Panel)
              SizedBox(
                width: 300,
                child: MarketWatchWidget(
                  onSymbolSelected: (symbol) {
                    setState(() {
                      _selectedSymbol = symbol;
                    });
                  },
                ),
              ),
              
              // Charts (Center)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Symbol Selector
                    _buildSymbolSelector(),
                    
                    // Chart
                    Expanded(
                      child: ChartWidget(
                        symbol: _selectedSymbol,
                        timeFrame: _timeFrame,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Order Book (Right Panel)
              SizedBox(
                width: 320,
                child: OrderBookWidget(symbol: _selectedSymbol),
              ),
            ],
          );
        } else {
          // Mobile layout - tabs
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.list), text: 'Market'),
                    Tab(icon: Icon(Icons.show_chart), text: 'Chart'),
                    Tab(icon: Icon(Icons.book), text: 'Orders'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      MarketWatchWidget(
                        onSymbolSelected: (symbol) {
                          setState(() {
                            _selectedSymbol = symbol;
                          });
                        },
                      ),
                      Column(
                        children: [
                          _buildSymbolSelector(),
                          Expanded(
                            child: ChartWidget(
                              symbol: _selectedSymbol,
                              timeFrame: _timeFrame,
                            ),
                          ),
                        ],
                      ),
                      OrderBookWidget(symbol: _selectedSymbol),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSymbolSelector() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search symbol...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                setState(() {
                  _selectedSymbol = value.toUpperCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _timeFrame,
            items: const [
              DropdownMenuItem(value: '1m', child: Text('1m')),
              DropdownMenuItem(value: '5m', child: Text('5m')),
              DropdownMenuItem(value: '15m', child: Text('15m')),
              DropdownMenuItem(value: '1h', child: Text('1h')),
              DropdownMenuItem(value: '4h', child: Text('4h')),
              DropdownMenuItem(value: '1d', child: Text('1d')),
            ],
            onChanged: (value) {
              setState(() {
                _timeFrame = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}

class QuickOrderDialog extends StatefulWidget {
  const QuickOrderDialog({Key? key}) : super(key: key);

  @override
  _QuickOrderDialogState createState() => _QuickOrderDialogState();
}

class _QuickOrderDialogState extends State<QuickOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  String _symbol = '';
  String _side = 'BUY';
  String _orderType = 'MARKET';
  double _quantity = 0;
  double? _price;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Order'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _side,
                      items: const [
                        DropdownMenuItem(value: 'BUY', child: Text('BUY', style: TextStyle(color: Colors.green))),
                        DropdownMenuItem(value: 'SELL', child: Text('SELL', style: TextStyle(color: Colors.red))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _side = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Side',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _orderType,
                      items: const [
                        DropdownMenuItem(value: 'MARKET', child: Text('Market')),
                        DropdownMenuItem(value: 'LIMIT', child: Text('Limit')),
                        DropdownMenuItem(value: 'STOP', child: Text('Stop')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _orderType = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
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
              if (_orderType != 'MARKET') ...[
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: _orderType == 'LIMIT' ? 'Limit Price' : 'Stop Price',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _price = double.tryParse(value),
                ),
              ],
            ],
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
            backgroundColor: _side == 'BUY' ? Colors.green : Colors.red,
          ),
          child: Text(_side == 'BUY' ? 'Buy' : 'Sell'),
        ),
      ],
    );
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      // Submit order through provider
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed: $_side $_quantity $_symbol'),
          backgroundColor: _side == 'BUY' ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
