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
                  SwitchListTile(
                    title: const Text('Risk Alert Notifications'),
                    subtitle: const Text('When risk metrics exceed thresholds'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
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
          Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
          Tab(text: 'Risk', icon: Icon(Icons.security)),
          Tab(text: 'Distribution', icon: Icon(Icons.show_chart)),
          Tab(text: 'Comparative', icon: Icon(Icons.compare)),
          Tab(text: 'Reports', icon: Icon(Icons.description)),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }
  
  // ==================== CHART BUILDERS ====================
  
  Widget _buildEquityCurve() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toStringAsFixed(0)}');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _analytics!.equityCurve.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlyHeatmap() {
    final monthly = _analytics!.monthlyReturns;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return Container(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: monthly.length,
        itemBuilder: (context, yearIndex) {
          final year = monthly.keys.elementAt(yearIndex);
          final yearData = monthly[year]!;
          
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Text(
                  year.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, monthIndex) {
                    final return_ = yearData[monthIndex + 1] ?? 0;
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getReturnColor(return_),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${return_.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: return_.abs() > 10 ? Colors.white : Colors.grey[300],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDrawdownChart() {
    // Simplified drawdown calculation
    final drawdowns = <double>[];
    var peak = _analytics!.equityCurve.first;
    
    for (var value in _analytics!.equityCurve) {
      if (value > peak) peak = value;
      drawdowns.add(((peak - value) / peak) * -100);
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(0)}%');
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: drawdowns.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            color: Colors.red,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        maxY: 0,
      ),
    );
  }
  
  Widget _buildVaRChart() {
    final varData = {
      'VaR 90%': _analytics!.valueAtRisk95 * 0.8,
      'VaR 95%': _analytics!.valueAtRisk95,
      'VaR 99%': _analytics!.valueAtRisk95 * 1.2,
      'CVaR': _analytics!.conditionalVaR95,
    };
    
    return BarChart(
      BarChartData(
        barGroups: varData.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key.hashCode,
            barRods: [
              BarChartRodData(
                toY: entry.value.abs(),
                color: Colors.red,
                width: 30,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < varData.length) {
                  return Text(varData.keys.elementAt(index));
                }
                return const Text('');
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDistributionChart() {
    final returns = _analytics!.returns;
    final bins = _createHistogramBins(returns);
    
    return BarChart(
      BarChartData(
        barGroups: bins.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Colors.blue,
                width: 20,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${(value * 2 - 10).toStringAsFixed(0)}%');
              },
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlphaBetaChart(List<double> benchmarkReturns) {
    final spots = <FlSpot>[];
    for (var i = 0; i < min(_analytics!.returns.length, benchmarkReturns.length); i++) {
      spots.add(FlSpot(benchmarkReturns[i] * 100, _analytics!.returns[i] * 100));
    }
    
    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots.map((spot) => ScatterSpot(spot.x, spot.y)).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(0)}%');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(0)}%');
              },
            ),
          ),
        ),
      ),
    );
  }
  
  // ==================== GRID BUILDERS ====================
  
  Widget _buildPerformanceGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetric('Total Return', '${_analytics!.totalReturn.toStringAsFixed(1)}%', _analytics!.totalReturn >= 0 ? Colors.green : Colors.red),
        _buildMetric('Annualized', '${_analytics!.annualizedReturn.toStringAsFixed(1)}%', Colors.blue),
        _buildMetric('Volatility', '${_analytics!.volatility.toStringAsFixed(1)}%', Colors.orange),
        _buildMetric('Sharpe Ratio', _analytics!.sharpeRatio.toStringAsFixed(2), _analytics!.sharpeRatio > 1 ? Colors.green : Colors.orange),
        _buildMetric('Max Drawdown', '${_analytics!.maxDrawdown.toStringAsFixed(1)}%', Colors.red),
        _buildMetric('Win Rate', '${_analytics!.tradeStatistics['win_rate']?.toStringAsFixed(1)}%', Colors.green),
        _buildMetric('Profit Factor', _analytics!.tradeStatistics['profit_factor']?.toStringAsFixed(2) ?? '0', Colors.blue),
        _buildMetric('Calmar Ratio', _analytics!.calmarRatio.toStringAsFixed(2), _analytics!.calmarRatio > 1 ? Colors.green : Colors.orange),
      ],
    );
  }
  
  Widget _buildRiskGrid() {
    final risk = _analytics!.riskMetrics;
    
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetric('VaR (95%)', '${risk['var_95']?.toStringAsFixed(1)}%', Colors.red),
        _buildMetric('CVaR (95%)', '${risk['cvar_95']?.toStringAsFixed(1)}%', Colors.red),
        _buildMetric('Sortino Ratio', _analytics!.sortinoRatio.toStringAsFixed(2), _analytics!.sortinoRatio > 1 ? Colors.green : Colors.orange),
        _buildMetric('Omega Ratio', _analytics!.omegaRatio.toStringAsFixed(2), Colors.blue),
        _buildMetric('Sterling Ratio', _analytics!.performanceRatios['sterling_ratio']?.toStringAsFixed(2) ?? '0', Colors.blue),
        _buildMetric('Burke Ratio', _analytics!.performanceRatios['burke_ratio']?.toStringAsFixed(2) ?? '0', Colors.blue),
        _buildMetric('Ulcer Index', _analytics!.riskMetrics['ulcer_index']?.toStringAsFixed(2) ?? '0', Colors.orange),
        _buildMetric('Recovery Factor', _analytics!.recoveryFactor.toStringAsFixed(2), Colors.blue),
      ],
    );
  }
  
  Widget _buildComparisonGrid(Map<String, double> comparison) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetric('Alpha', '${comparison['alpha']?.toStringAsFixed(2)}%', comparison['alpha']! >= 0 ? Colors.green : Colors.red),
        _buildMetric('Beta', comparison['beta']?.toStringAsFixed(2) ?? '0', comparison['beta']! > 1 ? Colors.red : Colors.green),
        _buildMetric('Information Ratio', comparison['information_ratio']?.toStringAsFixed(2) ?? '0', Colors.blue),
        _buildMetric('Tracking Error', '${comparison['tracking_error']?.toStringAsFixed(2)}%', Colors.orange),
        _buildMetric('Relative Return', '${comparison['relative_return']?.toStringAsFixed(2)}%', comparison['relative_return']! >= 0 ? Colors.green : Colors.red),
      ],
    );
  }
  
  Widget _buildDrawdownStats() {
    final drawdownPeriods = _analytics!.drawdownPeriods;
    
    return Row(
      children: [
        Expanded(
          child: _buildDrawdownStat(
            'Max Drawdown',
            '${drawdownPeriods['max_drawdown']?.toStringAsFixed(1)}%',
            Colors.red,
          ),
        ),
        Expanded(
          child: _buildDrawdownStat(
            'Recovery Days',
            '${drawdownPeriods['max_drawdown_days']?.toStringAsFixed(0)}',
            Colors.orange,
          ),
        ),
        Expanded(
          child: _buildDrawdownStat(
            'Current DD',
            '${drawdownPeriods['current_drawdown']?.toStringAsFixed(1)}%',
            drawdownPeriods['current_drawdown']! > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStressTestResults() {
    final stressResults = {
      'Market Crash (-20%)': -18.5,
      'Rate Hike (+2%)': -12.3,
      'Recession': -25.7,
      'Oil Spike': -8.2,
    };
    
    return Column(
      children: stressResults.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: entry.value >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (entry.value.abs() / 30).clamp(0, 1),
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation(
                  entry.value >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildRollingReturns() {
    final rolling = _analytics!.rollingReturns;
    
    return Column(
      children: [
        _buildRollingMetric('30-Day Avg', '${rolling['rolling_30_avg']?.toStringAsFixed(2)}%', Colors.blue),
        _buildRollingMetric('60-Day Avg', '${rolling['rolling_60_avg']?.toStringAsFixed(2)}%', Colors.blue),
        _buildRollingMetric('90-Day Avg', '${rolling['rolling_90_avg']?.toStringAsFixed(2)}%', Colors.blue),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRollingMetric('30-Day Max', '${rolling['rolling_30_max']?.toStringAsFixed(2)}%', Colors.green),
            ),
            Expanded(
              child: _buildRollingMetric('30-Day Min', '${rolling['rolling_30_min']?.toStringAsFixed(2)}%', Colors.red),
            ),
          ],
        ),
      ],
    );
  }
  
  // ==================== HELPER WIDGETS ====================
  
  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
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
  
  Widget _buildStat(String label, String value) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
  
  Widget _buildDrawdownStat(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRollingMetric(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
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
  
  Widget _buildConsecutiveCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCaptureCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExportButton(String label, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Export functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export feature coming soon')),
          );
        },
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
        ),
      ),
    );
  }
  
  // ==================== HELPER METHODS ====================
  
  Color _getReturnColor(double return_) {
    if (return_ > 5) return Colors.green[700]!;
    if (return_ > 0) return Colors.green[400]!;
    if (return_ > -5) return Colors.red[400]!;
    return Colors.red[700]!;
  }
  
  List<int> _createHistogramBins(List<double> returns, {int bins = 20}) {
    final minReturn = returns.reduce((a, b) => a < b ? a : b);
    final maxReturn = returns.reduce((a, b) => a > b ? a : b);
    final binWidth = (maxReturn - minReturn) / bins;
    
    final histogram = List.filled(bins, 0);
    
    for (var r in returns) {
      final binIndex = ((r - minReturn) / binWidth).floor();
      if (binIndex >= 0 && binIndex < bins) {
        histogram[binIndex]++;
      }
    }
    
    return histogram;
  }
  
  List<double> _generateBenchmarkReturns() {
    // Generate S&P 500 like returns for demo
    final random = Random();
    final returns = <double>[];
    for (var i = 0; i < _analytics!.returns.length; i++) {
      returns.add(random.nextDouble() * 0.03 - 0.015);
    }
    return returns;
  }
}
