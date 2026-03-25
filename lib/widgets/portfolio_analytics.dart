// lib/widgets/portfolio_analytics.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/position.dart';

class PortfolioAnalytics extends StatefulWidget {
  const PortfolioAnalytics({Key? key}) : super(key: key);

  @override
  _PortfolioAnalyticsState createState() => _PortfolioAnalyticsState();
}

class _PortfolioAnalyticsState extends State<PortfolioAnalytics> {
  int _selectedTimeframe = 7; // days
  String _selectedMetric = 'pnl';
  
  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Overview Cards
              _buildPerformanceCards(provider),
              
              const SizedBox(height: 24),
              
              // P&L Chart
              _buildPnLChart(provider),
              
              const SizedBox(height: 24),
              
              // Risk Metrics
              _buildRiskMetrics(provider),
              
              const SizedBox(height: 24),
              
              // Position Allocation
              _buildPositionAllocation(provider),
              
              const SizedBox(height: 24),
              
              // Performance by Symbol
              _buildSymbolPerformance(provider),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPerformanceCards(PortfolioProvider provider) {
    final totalPnL = provider.totalPnL;
    final totalPnLPercent = provider.totalPnLPercent;
    final sharpeRatio = provider.sharpeRatio;
    final winRate = provider.winRate;
    
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total P&L',
          '\$${totalPnL.toStringAsFixed(2)}',
          totalPnL >= 0 ? Colors.green : Colors.red,
          subtitle: '${totalPnLPercent >= 0 ? '+' : ''}${totalPnLPercent.toStringAsFixed(2)}%',
        ),
        _buildMetricCard(
          'Sharpe Ratio',
          sharpeRatio.toStringAsFixed(2),
          sharpeRatio >= 1 ? Colors.green : Colors.orange,
        ),
        _buildMetricCard(
          'Win Rate',
          '${winRate.toStringAsFixed(1)}%',
          winRate >= 50 ? Colors.green : Colors.red,
        ),
        _buildMetricCard(
          'Max Drawdown',
          '${provider.maxDrawdown.toStringAsFixed(1)}%',
          Colors.red,
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, Color color, {String? subtitle}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPnLChart(PortfolioProvider provider) {
    final pnlHistory = provider.pnlHistory;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'P&L History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: _selectedTimeframe,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 Days')),
                    DropdownMenuItem(value: 30, child: Text('30 Days')),
                    DropdownMenuItem(value: 90, child: Text('90 Days')),
                    DropdownMenuItem(value: 365, child: Text('1 Year')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeframe = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                _buildPnLChartData(pnlHistory),
                swapAnimationDuration: const Duration(milliseconds: 500),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  LineChartData _buildPnLChartData(List<double> pnlHistory) {
    return LineChartData(
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
              return Text('Day ${value.toInt()}');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: pnlHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRiskMetrics(PortfolioProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskMetric(
                    'VaR (95%)',
                    '\$${provider.valueAtRisk.toStringAsFixed(2)}',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildRiskMetric(
                    'CVaR',
                    '\$${provider.conditionalVaR.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskMetric(
                    'Beta',
                    provider.beta.toStringAsFixed(2),
                    provider.beta > 1 ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildRiskMetric(
                    'Alpha',
                    '${provider.alpha >= 0 ? '+' : ''}${provider.alpha.toStringAsFixed(2)}%',
                    provider.alpha >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: provider.riskScore / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(
                provider.riskScore < 30 ? Colors.green :
                provider.riskScore < 70 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Risk Score'),
                Text('${provider.riskScore.toStringAsFixed(0)}/100'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRiskMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
  
  Widget _buildPositionAllocation(PortfolioProvider provider) {
    final positions = provider.openPositions;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Position Allocation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                _buildPieChartData(positions),
              ),
            ),
            const SizedBox(height: 16),
            ...positions.map((position) => _buildPositionRow(position)),
          ],
        ),
      ),
    );
  }
  
  PieChartData _buildPieChartData(List<Position> positions) {
    final totalValue = positions.fold(0.0, (sum, p) => sum + p.currentValue);
    
    return PieChartData(
      sections: positions.map((position) {
        final percentage = (position.currentValue / totalValue) * 100;
        return PieChartSectionData(
          value: percentage,
          title: position.symbol,
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          color: _getColorForSymbol(position.symbol),
        );
      }).toList(),
      sectionsSpace: 2,
      centerSpaceRadius: 40,
    );
  }
  
  Widget _buildPositionRow(Position position) {
    final allocation = (position.currentValue / 
        Provider.of<PortfolioProvider>(context, listen: false).totalValue) * 100;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getColorForSymbol(position.symbol),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(position.symbol),
          ),
          Text(
            '${allocation.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${position.currentValue.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSymbolPerformance(PortfolioProvider provider) {
    final performance = provider.symbolPerformance;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance by Symbol',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                _buildBarChartData(performance),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  BarChartData _buildBarChartData(Map<String, double> performance) {
    final entries = performance.entries.toList();
    
    return BarChartData(
      barGroups: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final symbol = entry.value.key;
        final pnl = entry.value.value;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: pnl,
              color: pnl >= 0 ? Colors.green : Colors.red,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() < entries.length) {
                return Text(entries[value.toInt()].key);
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text('\$${value.toStringAsFixed(0)}');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
    );
  }
  
  Color _getColorForSymbol(String symbol) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[symbol.hashCode.abs() % colors.length];
  }
}
