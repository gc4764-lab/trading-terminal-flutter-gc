// lib/widgets/performance_analytics_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../analytics/performance_analytics.dart';
import '../providers/portfolio_provider.dart';

class PerformanceAnalyticsWidget extends StatefulWidget {
  const PerformanceAnalyticsWidget({Key? key}) : super(key: key);

  @override
  _PerformanceAnalyticsWidgetState createState() => _PerformanceAnalyticsWidgetState();
}

class _PerformanceAnalyticsWidgetState extends State<PerformanceAnalyticsWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PerformanceAnalytics? _analytics;
  String _selectedTimeframe = '1Y';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalytics();
  }
  
  Future<void> _loadAnalytics() async {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);
    final returns = await provider.getHistoricalReturns();
    final equity = await provider.getEquityCurve();
    final dates = await provider.getEquityDates();
    
    setState(() {
      _analytics = PerformanceAnalytics(
        returns: returns,
        equityCurve: equity,
        dates: dates,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        _buildHeader(),
        _buildTimeframeSelector(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildRiskTab(),
              _buildDistributionTab(),
              _buildComparativeTab(),
              _buildReportsTab(),
            ],
          ),
        ),
        _buildTabBar(),
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
          const Icon(Icons.analytics, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Performance Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _buildMetricChip(
            'Total Return',
            '${_analytics!.totalReturn.toStringAsFixed(1)}%',
            _analytics!.totalReturn >= 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          _buildMetricChip(
            'Sharpe',
            _analytics!.sharpeRatio.toStringAsFixed(2),
            _analytics!.sharpeRatio > 1 ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeframeSelector() {
    final timeframes = ['1M', '3M', '6M', '1Y', '3Y', 'ALL'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: timeframes.map((tf) {
          final isSelected = _selectedTimeframe == tf;
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeframe = tf),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Equity Curve
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Equity Curve',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildEquityCurve(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPerformanceGrid(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Monthly Returns Heatmap
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Returns Heatmap',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlyHeatmap(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Rolling Returns
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rolling Returns',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRollingReturns(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRiskTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Risk Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risk Metrics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRiskGrid(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Drawdown Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drawdown Analysis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildDrawdownChart(),
                  ),
                  const SizedBox(height: 16),
                  _buildDrawdownStats(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // VaR Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Value at Risk (VaR) Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildVaRChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stress Test Results
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stress Test Scenarios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStressTestResults(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDistributionTab() {
    final distribution = _analytics!.returnDistribution;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Return Distribution Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Return Distribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildDistributionChart(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Distribution Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribution Statistics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStat('Mean', '${distribution['mean'].toStringAsFixed(2)}%'),
                      _buildStat('Median', '${distribution['median'].toStringAsFixed(2)}%'),
                      _buildStat('Std Dev', '${distribution['std_dev'].toStringAsFixed(2)}%'),
                      _buildStat('Skewness', distribution['skewness'].toStringAsFixed(2)),
                      _buildStat('Kurtosis', distribution['kurtosis'].toStringAsFixed(2)),
                      _buildStat('5th %ile', '${distribution['percentile_5'].toStringAsFixed(2)}%'),
                      _buildStat('95th %ile', '${distribution['percentile_95'].toStringAsFixed(2)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Consecutive Wins/Losses
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consecutive Performance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildConsecutiveCard(
                          'Max Win Streak',
                          '${_analytics!.consecutiveStats['max_win_streak']}',
                          Colors.green,
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildConsecutiveCard(
                          'Max Loss Streak',
                          '${_analytics!.consecutiveStats['max_loss_streak']}',
                          Colors.red,
                          Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComparativeTab() {
    // For demo, using S&P 500 as benchmark
    final benchmarkReturns = _generateBenchmarkReturns();
    final comparison = _analytics!.compareToBenchmark(benchmarkReturns);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Alpha/Beta Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alpha & Beta Analysis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildAlphaBetaChart(benchmarkReturns),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Benchmark Comparison
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Benchmark Comparison',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonGrid(comparison),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Capture Ratios
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capture Ratios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCaptureCard(
                          'Upside Capture',
                          '${comparison['upside_capture'].toStringAsFixed(1)}%',
                          comparison['upside_capture']! > 100 ? Colors.green : Colors.orange,
                          Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCaptureCard(
                          'Downside Capture',
                          '${comparison['downside_capture'].toStringAsFixed(1)}%',
                          comparison['downside_capture']! < 100 ? Colors.green : Colors.red,
                          Icons.arrow_downward,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Export Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Reports',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildExportButton(
                    'PDF Performance Report',
                    Icons.picture_as_pdf,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildExportButton(
                    'CSV Trade History',
                    Icons.table_chart,
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildExportButton(
                    'JSON Analytics Data',
                    Icons.data_usage,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Schedule Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Schedule Reports',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Weekly Performance Report'),
                    subtitle: const Text('Every Monday at 9:00 AM'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Monthly Analytics Summary'),
                    subtitle: const Text('First day of each month'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  Switch
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  