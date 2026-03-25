// lib/widgets/analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = '1M';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTimeframeSelector(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPerformanceTab(),
              _buildRiskTab(),
              _buildCorrelationTab(),
              _buildForecastTab(),
            ],
          ),
        ),
        _buildTabBar(),
      ],
    );
  }
  
  Widget _buildTimeframeSelector() {
    final timeframes = ['1W', '1M', '3M', '6M', '1Y', 'ALL'];
    
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
  
  Widget _buildPerformanceTab() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
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
                        height: 200,
                        child: LineChart(_buildEquityCurve(provider.equityHistory)),
                      ),
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
                        'Monthly Returns',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildMonthlyHeatmap(provider.monthlyReturns),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Performance Metrics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Metrics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildPerformanceMetrics(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildRiskTab() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // VaR Chart
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
                        child: BarChart(_buildVaRChart(provider.varData)),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Risk Metrics Grid
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
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildRiskMetric(
                            'Sharpe Ratio',
                            provider.sharpeRatio.toStringAsFixed(2),
                            provider.sharpeRatio > 1 ? Colors.green : Colors.orange,
                          ),
                          _buildRiskMetric(
                            'Sortino Ratio',
                            provider.sortinoRatio.toStringAsFixed(2),
                            provider.sortinoRatio > 1 ? Colors.green : Colors.orange,
                          ),
                          _buildRiskMetric(
                            'Max Drawdown',
                            '${provider.maxDrawdown.toStringAsFixed(1)}%',
                            Colors.red,
                          ),
                          _buildRiskMetric(
                            'Calmar Ratio',
                            provider.calmarRatio.toStringAsFixed(2),
                            provider.calmarRatio > 1 ? Colors.green : Colors.orange,
                          ),
                          _buildRiskMetric(
                            'Beta',
                            provider.beta.toStringAsFixed(2),
                            provider.beta > 1 ? Colors.red : Colors.green,
                          ),
                          _buildRiskMetric(
                            'Alpha',
                            '${provider.alpha >= 0 ? '+' : ''}${provider.alpha.toStringAsFixed(2)}%',
                            provider.alpha >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
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
                        'Stress Test Results',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildStressTestResults(provider.stressTestResults),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCorrelationTab() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Correlation Matrix
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asset Correlation Matrix',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildCorrelationMatrix(provider.correlationMatrix),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Portfolio Diversification
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portfolio Diversification',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(_buildDiversificationChart(provider.assetAllocation)),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sector Exposure
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sector Exposure',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...provider.sectorExposure.entries.map((entry) {
                        return _buildExposureBar(entry.key, entry.value);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildForecastTab() {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Monte Carlo Simulation
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monte Carlo Simulation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '10,000 simulations',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(_buildMonteCarloChart(provider.monteCarloResults)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildForecastMetric(
                              '5th Percentile',
                              '\$${provider.monteCarloPercentile5.toStringAsFixed(0)}',
                              Colors.red,
                            ),
                          ),
                          Expanded(
                            child: _buildForecastMetric(
                              'Median',
                              '\$${provider.monteCarloMedian.toStringAsFixed(0)}',
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildForecastMetric(
                              '95th Percentile',
                              '\$${provider.monteCarloPercentile95.toStringAsFixed(0)}',
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Expected Returns
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expected Returns by Asset',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...provider.expectedReturns.entries.map((entry) {
                        return _buildReturnBar(entry.key, entry.value);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
          Tab(text: 'Risk', icon: Icon(Icons.security)),
          Tab(text: 'Correlation', icon: Icon(Icons.show_chart)),
          Tab(text: 'Forecast', icon: Icon(Icons.timeline)),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }
  
  Widget _buildPerformanceMetrics(PortfolioProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetric('Total Return', '${provider.totalReturnPercent.toStringAsFixed(1)}%', provider.totalReturnPercent >= 0 ? Colors.green : Colors.red),
        _buildMetric('Annualized Return', '${provider.annualizedReturn.toStringAsFixed(1)}%', Colors.blue),
        _buildMetric('Volatility', '${provider.volatility.toStringAsFixed(1)}%', Colors.orange),
        _buildMetric('Win Rate', '${provider.winRate.toStringAsFixed(1)}%', provider.winRate >= 50 ? Colors.green : Colors.red),
        _buildMetric('Average Win', '\$${provider.averageWin.toStringAsFixed(0)}', Colors.green),
        _buildMetric('Average Loss', '\$${provider.averageLoss.toStringAsFixed(0)}', Colors.red),
        _buildMetric('Profit Factor', provider.profitFactor.toStringAsFixed(2), provider.profitFactor > 1 ? Colors.green : Colors.red),
        _buildMetric('Recovery Factor', provider.recoveryFactor.toStringAsFixed(2), Colors.blue),
      ],
    );
  }
  
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
  
  Widget _buildRiskMetric(String label, String value, Color color) {
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
  
  Widget _buildForecastMetric(String label, String value, Color color) {
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExposureBar(String sector, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sector, style: const TextStyle(fontSize: 12)),
              Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation(_getSectorColor(sector)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReturnBar(String asset, double expectedReturn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
 
 