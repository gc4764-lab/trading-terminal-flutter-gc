// lib/widgets/enhanced_order_book.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order_book.dart';

class EnhancedOrderBook extends StatefulWidget {
  final String symbol;
  final OrderBookData orderBook;
  
  const EnhancedOrderBook({
    Key? key,
    required this.symbol,
    required this.orderBook,
  }) : super(key: key);

  @override
  _EnhancedOrderBookState createState() => _EnhancedOrderBookState();
}

class _EnhancedOrderBookState extends State<EnhancedOrderBook> {
  bool _showDepthChart = false;
  int _selectedLevel = 10;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Toggle buttons
          _buildToggleButtons(),
          
          // Order Book Content
          Expanded(
            child: _showDepthChart 
                ? _buildDepthChart()
                : _buildOrderBookTable(),
          ),
          
          // Spread indicator
          _buildSpreadIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.symbol,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, size: 18),
            onPressed: _showSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleButtons() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Order Book')),
                ButtonSegment(value: true, label: Text('Depth Chart')),
              ],
              selected: {_showDepthChart},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _showDepthChart = selection.first;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          if (!_showDepthChart)
            DropdownButton<int>(
              value: _selectedLevel,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 Levels')),
                DropdownMenuItem(value: 10, child: Text('10 Levels')),
                DropdownMenuItem(value: 20, child: Text('20 Levels')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildOrderBookTable() {
    final asks = widget.orderBook.asks.take(_selectedLevel).toList();
    final bids = widget.orderBook.bids.take(_selectedLevel).toList();
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Ask side (Sell orders)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _buildTableHeader('Sell Orders', Colors.red),
              ...asks.reversed.map((level) => _buildOrderBookRow(
                price: level.price,
                quantity: level.quantity,
                total: level.total,
                type: 'ask',
              )),
            ],
          ),
        ),
        
        // Spread
        _buildSpreadDisplay(),
        
        // Bid side (Buy orders)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _buildTableHeader('Buy Orders', Colors.green),
              ...bids.map((level) => _buildOrderBookRow(
                price: level.price,
                quantity: level.quantity,
                total: level.total,
                type: 'bid',
              )),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTableHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Qty',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Total',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderBookRow({
    required double price,
    required double quantity,
    required double total,
    required String type,
  }) {
    final isBid = type == 'bid';
    final color = isBid ? Colors.green : Colors.red;
    
    return Container(
      height: 32,
      child: Stack(
        children: [
          // Volume background bar
          Positioned.fill(
            child: Align(
              alignment: isBid ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width * 
                    (quantity / widget.orderBook.maxVolume) * 0.8,
                color: color.withOpacity(0.2),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(color: color),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    quantity.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    total.toStringAsFixed(0),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpreadDisplay() {
    final spread = widget.orderBook.askPrice - widget.orderBook.bidPrice;
    final spreadPercent = (spread / widget.orderBook.midPrice) * 100;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spread', style: TextStyle(fontSize: 12)),
              Text(
                '\$${spread.toStringAsFixed(2)} (${spreadPercent.toStringAsFixed(2)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: spreadPercent / 1, // Assuming max spread 1%
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation(Colors.orange),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpreadIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bid', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                '\$${widget.orderBook.bidPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text('Spread', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                '\$${(widget.orderBook.askPrice - widget.orderBook.bidPrice).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Ask', style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                '\$${widget.orderBook.askPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDepthChart() {
    final bids = widget.orderBook.bids;
    final asks = widget.orderBook.asks;
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text(
            'Market Depth',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              _buildDepthChartData(bids, asks),
              swapAnimationDuration: const Duration(milliseconds: 500),
            ),
          ),
        ],
      ),
    );
  }
  
  LineChartData _buildDepthChartData(List<OrderBookLevel> bids, List<OrderBookLevel> asks) {
    final bidSpots = <FlSpot>[];
    final askSpots = <FlSpot>[];
    
    var cumulativeBid = 0.0;
    for (var i = 0; i < bids.length; i++) {
      cumulativeBid += bids[i].quantity;
      bidSpots.add(FlSpot(bids[i].price, cumulativeBid));
    }
    
    var cumulativeAsk = 0.0;
    for (var i = 0; i < asks.length; i++) {
      cumulativeAsk += asks[i].quantity;
      askSpots.add(FlSpot(asks[i].price, cumulativeAsk));
    }
    
    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}K');
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('\$${value.toStringAsFixed(0)}');
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: bidSpots,
          color: Colors.green,
          barWidth: 2,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.2),
          ),
        ),
        LineChartBarData(
          spots: askSpots,
          color: Colors.red,
          barWidth: 2,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
  
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Book Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Number of levels to display:'),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _selectedLevel,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 Levels')),
                DropdownMenuItem(value: 10, child: Text('10 Levels')),
                DropdownMenuItem(value: 20, child: Text('20 Levels')),
                DropdownMenuItem(value: 50, child: Text('50 Levels')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

