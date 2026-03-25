// lib/widgets/portfolio_tracker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/position.dart';

class PortfolioTracker extends StatefulWidget {
  const PortfolioTracker({Key? key}) : super(key: key);

  @override
  _PortfolioTrackerState createState() => _PortfolioTrackerState();
}

class _PortfolioTrackerState extends State<PortfolioTracker> {
  int _selectedTab = 0;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portfolio Summary Cards
              _buildPortfolioSummary(provider),
              
              const SizedBox(height: 24),
              
              // Tab Bar
              _buildTabBar(),
              
              const SizedBox(height: 16),
              
              // Tab Content
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildPositionsList(provider),
                    _buildHoldingsList(provider),
                    _buildPerformanceChart(provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPortfolioSummary(PortfolioProvider provider) {
    final totalValue = provider.totalValue;
    final totalPnL = provider.totalPnL;
    final totalPnLPercent = provider.totalPnLPercent;
    final availableMargin = provider.availableMargin;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Value',
                    '\$${totalValue.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total P&L',
                    '\$${totalPnL.toStringAsFixed(2)}',
                    Icons.trending_up,
                    totalPnL >= 0 ? Colors.green : Colors.red,
                    subtitle: '${totalPnLPercent >= 0 ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Available Margin',
                    '\$${availableMargin.toStringAsFixed(2)}',
                    Icons.money,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Open Positions',
                    provider.openPositions.length.toString(),
                    Icons.show_chart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTabButton('Positions', 0),
          _buildTabButton('Holdings', 1),
          _buildTabButton('Performance', 2),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPositionsList(PortfolioProvider provider) {
    final positions = provider.openPositions;
    
    if (positions.isEmpty) {
      return const Center(
        child: Text('No open positions'),
      );
    }
    
    return ListView.builder(
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        return _buildPositionCard(position);
      },
    );
  }
  
  Widget _buildPositionCard(Position position) {
    final pnlColor = position.unrealizedPnL >= 0 ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              position.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: position.side == OrderSide.buy 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                position.side == OrderSide.buy ? 'LONG' : 'SHORT',
                style: TextStyle(
                  fontSize: 10,
                  color: position.side == OrderSide.buy ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text('Qty: ${position.quantity} | Avg: \$${position.averagePrice.toStringAsFixed(2)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${position.currentValue.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${position.unrealizedPnL >= 0 ? '+' : ''}\$${position.unrealizedPnL.toStringAsFixed(2)}',
              style: TextStyle(
                color: pnlColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPositionDetail('Entry Price', '\$${position.entryPrice.toStringAsFixed(2)}'),
                _buildPositionDetail('Current Price', '\$${position.currentPrice.toStringAsFixed(2)}'),
                _buildPositionDetail('Quantity', position.quantity.toString()),
                _buildPositionDetail('Current Value', '\$${position.currentValue.toStringAsFixed(2)}'),
                _buildPositionDetail('Unrealized P&L', 
                  '${position.unrealizedPnL >= 0 ? '+' : ''}\$${position.unrealizedPnL.toStringAsFixed(2)}',
                  color: pnlColor,
                ),
                _buildPositionDetail('P&L %', 
                  '${position.unrealizedPnLPercent >= 0 ? '+' : ''}${position.unrealizedPnLPercent.toStringAsFixed(2)}%',
                  color: pnlColor,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setStopLoss(position),
                        child: const Text('Set Stop Loss'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setTakeProfit(position),
                        child: const Text('Set Take Profit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _closePosition(position),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Close Position'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPositionDetail(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHoldingsList(PortfolioProvider provider) {
    final holdings = provider.holdings;
    
    if (holdings.isEmpty) {
      return const Center(
        child: Text('No holdings'),
      );
    }
    
    return ListView.builder(
      itemCount: holdings.length,
      itemBuilder: (context, index) {
        final holding = holdings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(holding.symbol.substring(0, 1)),
            ),
            title: Text(holding.symbol),
            subtitle: Text('Qty: ${holding.quantity} | Avg: \$${holding.averagePrice.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${holding.currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${holding.unrealizedPnL >= 0 ? '+' : ''}\$${holding.unrealizedPnL.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: holding.unrealizedPnL >= 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPerformanceChart(PortfolioProvider provider) {
    // Placeholder for performance chart
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Performance chart coming soon'),
          const SizedBox(height: 8),
          Text(
            'Total Return: ${provider.totalPnLPercent >= 0 ? '+' : ''}${provider.totalPnLPercent.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: provider.totalPnLPercent >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  void _setStopLoss(Position position) {
    // Show stop loss dialog
    showDialog(
      context: context,
      builder: (context) => StopLossDialog(position: position),
    );
  }
  
  void _setTakeProfit(Position position) {
    // Show take profit dialog
    showDialog(
      context: context,
      builder: (context) => TakeProfitDialog(position: position),
    );
  }
  
  void _closePosition(Position position) {
    // Close position
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Position'),
        content: Text('Are you sure you want to close position for ${position.symbol}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement position closing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Closing position for ${position.symbol}'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
