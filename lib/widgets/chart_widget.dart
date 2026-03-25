import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/symbol.dart';
import '../providers/chart_provider.dart';

class ChartWidget extends StatefulWidget {
  final Symbol symbol;
  final String timeFrame;
  final bool isDarkTheme;
  
  const ChartWidget({
    Key? key,
    required this.symbol,
    required this.timeFrame,
    this.isDarkTheme = true,
  }) : super(key: key);

  @override
  _ChartWidgetState createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  List<CandleData> _candleData = [];
  List<IndicatorData> _indicators = [];
  bool _showVolume = true;
  String _chartType = 'candle'; // candle, line, bar, area
  
  @override
  void initState() {
    super.initState();
    loadChartData();
  }

  Future<void> loadChartData() async {
    // Load historical data for the symbol
    // This is a placeholder - implement actual data loading
    _candleData = [
      CandleData(DateTime.now().subtract(const Duration(days: 10)), 100, 105, 99, 102),
      CandleData(DateTime.now().subtract(const Duration(days: 9)), 102, 108, 101, 107),
      CandleData(DateTime.now().subtract(const Duration(days: 8)), 107, 110, 106, 109),
      // Add more data points
    ];
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkTheme ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Chart Controls
          _buildChartControls(),
          
          // Price Chart
          Expanded(
            flex: 3,
            child: _buildPriceChart(),
          ),
          
          // Volume Chart
          if (_showVolume)
            Expanded(
              flex: 1,
              child: _buildVolumeChart(),
            ),
        ],
      ),
    );
  }

  Widget _buildChartControls() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Chart type selector
          DropdownButton<String>(
            value: _chartType,
            items: const [
              DropdownMenuItem(value: 'candle', child: Text('Candlestick')),
              DropdownMenuItem(value: 'line', child: Text('Line')),
              DropdownMenuItem(value: 'bar', child: Text('Bar')),
              DropdownMenuItem(value: 'area', child: Text('Area')),
            ],
            onChanged: (value) {
              setState(() {
                _chartType = value!;
              });
            },
          ),
          const SizedBox(width: 16),
          
          // Timeframe selector
          _buildTimeframeButtons(),
          const Spacer(),
          
          // Indicator button
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: _showIndicatorsDialog,
            tooltip: 'Add Indicator',
          ),
          
          // Drawing tools button
          IconButton(
            icon: const Icon(Icons.draw),
            onPressed: _showDrawingTools,
            tooltip: 'Drawing Tools',
          ),
          
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showChartSettings,
            tooltip: 'Chart Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeButtons() {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d', '1w'];
    
    return Row(
      children: timeframes.map((tf) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(tf),
            selected: widget.timeFrame == tf,
            onSelected: (selected) {
              if (selected) {
                // Change timeframe and reload data
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceChart() {
    switch (_chartType) {
      case 'candle':
        return SfCartesianChart(
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(
            labelFormat: '\${value}',
            title: AxisTitle(text: 'Price'),
          ),
          series: <CandleSeries<CandleData, DateTime>>[
            CandleSeries<CandleData, DateTime>(
              dataSource: _candleData,
              xValueMapper: (CandleData data, _) => data.date,
              highValueMapper: (CandleData data, _) => data.high,
              lowValueMapper: (CandleData data, _) => data.low,
              openValueMapper: (CandleData data, _) => data.open,
              closeValueMapper: (CandleData data, _) => data.close,
              enableSolidCandles: true,
              bullColor: Colors.green,
              bearColor: Colors.red,
            ),
          ],
        );
        
      case 'line':
        return SfCartesianChart(
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(),
          series: <LineSeries<CandleData, DateTime>>[
            LineSeries<CandleData, DateTime>(
              dataSource: _candleData,
              xValueMapper: (CandleData data, _) => data.date,
              yValueMapper: (CandleData data, _) => data.close,
              color: Colors.blue,
              markerSettings: const MarkerSettings(isVisible: false),
            ),
          ],
        );
        
      default:
        return const Center(child: Text('Chart type not implemented'));
    }
  }

  Widget _buildVolumeChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Volume'),
      ),
      series: <ColumnSeries<CandleData, DateTime>>[
        ColumnSeries<CandleData, DateTime>(
          dataSource: _candleData,
          xValueMapper: (CandleData data, _) => data.date,
          yValueMapper: (CandleData data, _) => data.volume,
          color: Colors.grey,
        ),
      ],
    );
  }

  void _showIndicatorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Indicator'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Moving Average'),
                onTap: () => _addIndicator('SMA'),
              ),
              ListTile(
                title: const Text('EMA'),
                onTap: () => _addIndicator('EMA'),
              ),
              ListTile(
                title: const Text('RSI'),
                onTap: () => _addIndicator('RSI'),
              ),
              ListTile(
                title: const Text('MACD'),
                onTap: () => _addIndicator('MACD'),
              ),
              ListTile(
                title: const Text('Bollinger Bands'),
                onTap: () => _addIndicator('BB'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addIndicator(String indicator) {
    // Add technical indicator to chart
    Navigator.pop(context);
    // Implement indicator calculation and display
  }

  void _showDrawingTools() {
    // Show drawing tools panel
  }

  void _showChartSettings() {
    // Show chart settings dialog
  }
}

class CandleData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  
  CandleData(this.date, this.open, this.high, this.low, this.close, [this.volume = 0]);
}
