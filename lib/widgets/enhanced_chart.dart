// lib/widgets/enhanced_chart.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:ta/ta.dart' as ta;
import '../models/chart_data.dart';

class EnhancedChart extends StatefulWidget {
  final String symbol;
  final String timeframe;
  final List<ChartData> data;
  
  const EnhancedChart({
    Key? key,
    required this.symbol,
    required this.timeframe,
    required this.data,
  }) : super(key: key);

  @override
  _EnhancedChartState createState() => _EnhancedChartState();
}

class _EnhancedChartState extends State<EnhancedChart> {
  List<TechnicalIndicator> _indicators = [];
  List<DrawingTool> _drawings = [];
  bool _showVolume = true;
  String _chartType = 'candle';
  bool _isFullscreen = false;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Chart Controls
          _buildChartControls(),
          
          // Main Chart
          Expanded(
            flex: 3,
            child: _buildMainChart(),
          ),
          
          // Volume/Indicator Panel
          if (_showVolume || _indicators.isNotEmpty)
            Expanded(
              flex: 1,
              child: _buildSecondaryPanel(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChartControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Chart Type Selector
            _buildControlButton(
              icon: Icons.show_chart,
              tooltip: 'Chart Type',
              onPressed: _showChartTypeMenu,
            ),
            
            const VerticalDivider(),
            
            // Timeframe Selector
            ...['1m', '5m', '15m', '1h', '4h', '1d', '1w'].map((tf) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(tf),
                  selected: widget.timeframe == tf,
                  onSelected: (selected) {
                    if (selected) _changeTimeframe(tf);
                  },
                ),
              ),
            ),
            
            const VerticalDivider(),
            
            // Indicators
            _buildControlButton(
              icon: Icons.timeline,
              tooltip: 'Add Indicator',
              onPressed: _showIndicatorsMenu,
            ),
            
            // Drawing Tools
            _buildControlButton(
              icon: Icons.draw,
              tooltip: 'Drawing Tools',
              onPressed: _showDrawingTools,
            ),
            
            // Volume Toggle
            _buildControlButton(
              icon: Icons.bar_chart,
              tooltip: 'Toggle Volume',
              onPressed: () => setState(() => _showVolume = !_showVolume),
              isActive: _showVolume,
            ),
            
            // Fullscreen
            _buildControlButton(
              icon: Icons.fullscreen,
              tooltip: 'Fullscreen',
              onPressed: _toggleFullscreen,
            ),
            
            // Settings
            _buildControlButton(
              icon: Icons.settings,
              tooltip: 'Chart Settings',
              onPressed: _showChartSettings,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? Colors.blue : null,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
  
  Widget _buildMainChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        labelFormat: widget.timeframe == '1d' ? 'dd MMM' : 'HH:mm',
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelFormat: '\${value}',
        opposedPosition: true,
        title: AxisTitle(text: 'Price'),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: _getChartSeries(),
      annotations: _getAnnotations(),
    );
  }
  
  List<CartesianSeries> _getChartSeries() {
    final series = <CartesianSeries>[];
    
    // Price Series
    switch (_chartType) {
      case 'candle':
        series.add(CandleSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          highValueMapper: (ChartData data, _) => data.high,
          lowValueMapper: (ChartData data, _) => data.low,
          openValueMapper: (ChartData data, _) => data.open,
          closeValueMapper: (ChartData data, _) => data.close,
          bullColor: Colors.green,
          bearColor: Colors.red,
          enableSolidCandles: true,
        ));
        break;
        
      case 'line':
        series.add(LineSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.close,
          color: Colors.blue,
          markerSettings: const MarkerSettings(isVisible: false),
        ));
        break;
        
      case 'area':
        series.add(AreaSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.close,
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
        ));
        break;
        
      case 'bar':
        series.add(BarSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.close,
          color: Colors.blue,
        ));
        break;
    }
    
    // Add indicator series
    for (var indicator in _indicators) {
      series.addAll(indicator.getSeries(widget.data));
    }
    
    return series;
  }
  
  Widget _buildSecondaryPanel() {
    if (_indicators.isNotEmpty && _indicators.first.type == IndicatorType.rsi) {
      return _buildRSIPanel();
    } else if (_indicators.isNotEmpty && _indicators.first.type == IndicatorType.macd) {
      return _buildMACDPanel();
    } else {
      return _buildVolumePanel();
    }
  }
  
  Widget _buildVolumePanel() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(isVisible: false),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Volume'),
      ),
      series: <ColumnSeries<ChartData, DateTime>>[
        ColumnSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.volume,
          color: (ChartData data, _) {
            return data.close >= data.open ? Colors.green : Colors.red;
          },
        ),
      ],
    );
  }
  
  Widget _buildRSIPanel() {
    final rsiValues = ta.rsi(widget.data.map((d) => d.close).toList(), 14);
    
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(isVisible: false),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 100,
        title: AxisTitle(text: 'RSI'),
      ),
      series: <LineSeries<ChartData, DateTime>>[
        LineSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, int index) => rsiValues[index],
          color: Colors.orange,
        ),
      ],
      annotations: [
        CartesianChartAnnotation(
          coordinateUnit: CoordinateUnit.point,
          x: 0,
          y: 70,
          widget: Container(
            height: 1,
            width: double.infinity,
            color: Colors.red.withOpacity(0.5),
          ),
        ),
        CartesianChartAnnotation(
          coordinateUnit: CoordinateUnit.point,
          x: 0,
          y: 30,
          widget: Container(
            height: 1,
            width: double.infinity,
            color: Colors.green.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMACDPanel() {
    final closePrices = widget.data.map((d) => d.close).toList();
    final macd = ta.macd(closePrices);
    
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(isVisible: false),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'MACD'),
      ),
      series: <CartesianSeries>[
        LineSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, int index) => macd['macd']![index],
          color: Colors.blue,
          name: 'MACD',
        ),
        LineSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, int index) => macd['signal']![index],
          color: Colors.red,
          name: 'Signal',
        ),
        ColumnSeries<ChartData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, int index) => macd['histogram']![index],
          color: (ChartData data, int index) {
            return macd['histogram']![index] >= 0 ? Colors.green : Colors.red;
          },
          name: 'Histogram',
        ),
      ],
    );
  }
  
  List<CartesianChartAnnotation> _getAnnotations() {
    final annotations = <CartesianChartAnnotation>[];
    
    // Add drawing annotations
    for (var drawing in _drawings) {
      annotations.add(drawing.getAnnotation());
    }
    
    return annotations;
  }
  
  void _showChartTypeMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(value: 'candle', child: Text('Candlestick')),
        const PopupMenuItem(value: 'line', child: Text('Line')),
        const PopupMenuItem(value: 'bar', child: Text('Bar')),
        const PopupMenuItem(value: 'area', child: Text('Area')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() => _chartType = value);
      }
    });
  }
  
  void _showIndicatorsMenu() {
    showDialog(
      context: context,
      builder: (context) => IndicatorDialog(
        onAdd: (indicator) {
          setState(() {
            _indicators.add(indicator);
          });
        },
      ),
    );
  }
  
  void _showDrawingTools() {
    showDialog(
      context: context,
      builder: (context) => DrawingToolsDialog(
        onAdd: (drawing) {
          setState(() {
            _drawings.add(drawing);
          });
        },
      ),
    );
  }
  
  void _changeTimeframe(String timeframe) {
    // Implement timeframe change
  }
  
  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    // Implement fullscreen mode
  }
  
  void _showChartSettings() {
    showDialog(
      context: context,
      builder: (context) => ChartSettingsDialog(),
    );
  }
}

class IndicatorDialog extends StatefulWidget {
  final Function(TechnicalIndicator) onAdd;
  
  const IndicatorDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  _IndicatorDialogState createState() => _IndicatorDialogState();
}

class _IndicatorDialogState extends State<IndicatorDialog> {
  IndicatorType _selectedType = IndicatorType.sma;
  int _period = 14;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Indicator'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<IndicatorType>(
              value: _selectedType,
              items: IndicatorType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Indicator Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _period.toString(),
              decoration: const InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _period = int.tryParse(value) ?? 14;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(TechnicalIndicator(
              type: _selectedType,
              period: _period,
            ));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
