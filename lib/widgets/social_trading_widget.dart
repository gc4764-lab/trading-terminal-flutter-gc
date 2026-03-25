// lib/widgets/social_trading_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/social_trader.dart';
import '../services/copy_trading_service.dart';

class SocialTradingWidget extends StatefulWidget {
  const SocialTradingWidget({Key? key}) : super(key: key);

  @override
  _SocialTradingWidgetState createState() => _SocialTradingWidgetState();
}

class _SocialTradingWidgetState extends State<SocialTradingWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SocialTrader> _topTraders = [];
  final CopyTradingService _copyService = CopyTradingService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTopTraders();
  }
  
  Future<void> _loadTopTraders() async {
    // Load from server
    _topTraders.addAll(_getMockTraders());
    setState(() {});
  }
  
  List<SocialTrader> _getMockTraders() {
    return [
      SocialTrader(
        id: '1',
        username: '@crypto_king',
        displayName: 'Crypto King',
        totalPnL: 245000,
        winRate: 68.5,
        totalTrades: 342,
        averageReturn: 12.3,
        joinedAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      SocialTrader(
        id: '2',
        username: '@forex_master',
        displayName: 'Forex Master',
        totalPnL: 187000,
        winRate: 72.3,
        totalTrades: 521,
        averageReturn: 9.8,
        joinedAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      SocialTrader(
        id: '3',
        username: '@stock_guru',
        displayName: 'Stock Guru',
        totalPnL: 312000,
        winRate: 65.2,
        totalTrades: 287,
        averageReturn: 15.6,
        joinedAt: DateTime.now().subtract(const Duration(days: 240)),
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTopTradersList(),
              _buildFollowingList(),
              _buildCopySettings(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Social Trading',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Copy Top Traders',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Top Traders', icon: Icon(Icons.leaderboard)),
          Tab(text: 'Following', icon: Icon(Icons.person_add)),
          Tab(text: 'Copy Settings', icon: Icon(Icons.settings)),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }
  
  Widget _buildTopTradersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _topTraders.length,
      itemBuilder: (context, index) {
        final trader = _topTraders[index];
        return _buildTraderCard(trader);
      },
    );
  }
  
  Widget _buildTraderCard(SocialTrader trader) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTraderDetails(trader),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(
                      trader.displayName[0],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Trader info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trader.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trader.username,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildBadge(
                              'Grade ${trader.performanceGrade}',
                              Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            _buildBadge(
                              '${trader.totalTrades} trades',
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${trader.totalPnL.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: trader.totalPnL >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trader.winRate.toStringAsFixed(1)}% win rate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Performance bar
              LinearProgressIndicator(
                value: trader.winRate / 100,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewTraderTrades(trader),
                      child: const Text('View Trades'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCopyDialog(trader),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Copy Trader'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildFollowingList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No traders followed yet',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text('Discover Top Traders'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCopySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copy Trading Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Auto-copy new trades'),
                    subtitle: const Text('Automatically copy new trades from followed traders'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    title: const Text('Max copy amount per trade'),
                    subtitle: const Text('Limit the maximum amount to copy'),
                    trailing: const Text('\$1,000'),
                    onTap: () {},
                  ),
                  
                  ListTile(
                    title: const Text('Copy allocation'),
                    subtitle: const Text('How to allocate copy amounts'),
                    trailing: const Text('Proportional'),
                    onTap: () {},
                  ),
                  
                  ListTile(
                    title: const Text('Risk management'),
                    subtitle: const Text('Stop copying if drawdown exceeds'),
                    trailing: const Text('20%'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copy Performance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildCopyPerformanceMetric('Total Copy P&L', '\$12,450', Colors.green),
                  _buildCopyPerformanceMetric('Best Copy', '+45.2%', Colors.green),
                  _buildCopyPerformanceMetric('Worst Copy', '-12.3%', Colors.red),
                  _buildCopyPerformanceMetric('Copy Success Rate', '82.5%', Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCopyPerformanceMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
  
  void _showTraderDetails(SocialTrader trader) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trader.displayName),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              _buildTraderStats(trader),
              const SizedBox(height: 16),
              Expanded(
                child: _buildRecentTrades(trader),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCopyDialog(trader);
            },
            child: const Text('Copy Trader'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTraderStats(SocialTrader trader) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStat('Total P&L', '\$${trader.totalPnL.toStringAsFixed(0)}'),
        _buildStat('Win Rate', '${trader.winRate.toStringAsFixed(1)}%'),
        _buildStat('Total Trades', trader.totalTrades.toString()),
        _buildStat('Avg Return', '${trader.averageReturn.toStringAsFixed(1)}%'),
        _buildStat('Risk Score', trader.riskScore.toStringAsFixed(1)),
        _buildStat('Grade', trader.performanceGrade),
      ],
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentTrades(SocialTrader trader) {
    return ListView.builder(
      itemCount: trader.trades.length,
      itemBuilder: (context, index) {
        final trade = trader.trades[index];
        return ListTile(
          dense: true,
          leading: Icon(
            trade.side == OrderSide.buy ? Icons.trending_up : Icons.trending_down,
            color: trade.side == OrderSide.buy ? Colors.green : Colors.red,
          ),
          title: Text(trade.symbol),
          subtitle: Text(trade.entryTime.toString().substring(0, 16)),
          trailing: Text(
            '\$${trade.quantity.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
  
  void _viewTraderTrades(SocialTrader trader) {
    _showTraderDetails(trader);
  }
  
  void _showCopyDialog(SocialTrader trader) {
    final amountController = TextEditingController(text: '1000');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy ${trader.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to allocate for copying:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Warning: Copy trading involves risk. Past performance does not guarantee future results.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 1000;
              _copyService.startCopying('current_user', trader.id, amount);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Now copying ${trader.displayName} with \$${amount.toStringAsFixed(0)}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Start Copying'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _copyService.dispose();
    super.dispose();
  }
}
