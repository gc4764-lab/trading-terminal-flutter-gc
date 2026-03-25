// lib/widgets/multi_timeframe_chart.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chart_provider.dart';
import '../services/ohlcv_service.dart';
import '../services/data_compression_service.dart';

class MultiTimeframeChart extends StatefulWidget {
  final String symbol;
  final List<String> timeframes;
  
  const MultiTimeframeChart({
    Key? key,
    required this.symbol,
    this.timeframes = const ['1h', '4h', '1d'],
  }) : super(key: key);

  @override
  _MultiTimeframeChartState createState() => _MultiTimeframeChartState();
}

class _MultiTimeframeChartState extends State<MultiTimeframeChart> {
  final Map<String, List<ChartData>> _data = {};
  final Map<String, bool> _loading = {};
  String _selectedTimeframe = '1h';
  int _selectedSubChart = 0;
  bool _showHeikinAshi = false;
  bool _showRenko = false;
  double _renkoBrickSize = 0.5;
  
  final OHLCVService _ohlcvService = OHLCVService();
  final DataCompressionService _compression = DataCompressionService();
  
  @override
  void initState() {
    super.initState();
    _loadAllTimeframes();
  }
  
  Future<void> _loadAllTimeframes() async {
    for (var timeframe in widget.timeframes) {
      setState(() {
        _loading[timeframe] = true;
      });
      
      final data = await _ohlcvService.getOHLCVData(
        widget.symbol,
        timeframe,
        limit: 300,
      );
      
      setState(() {
        _data[timeframe] = data;
        _loading[timeframe] = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timeframe selector tabs
        _buildTimeframeTabs(),
        
        // Chart type selectors
        _buildChartTypeControls(),
        
        // Main chart area
        Expanded(
          flex: 3,
          child: _buildMainChart(),
        ),
        
        // Sub charts (lower timeframes)
        if (_selectedSubChart > 0)
          Expanded(
            flex: 1,
            child: _buildSubChart(),
          ),
      ],
    );
  }
  
  Widget _buildTimeframeTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.timeframes.length,
        itemBuilder: (context, index) {
          final timeframe = widget.timeframes[index];
          final isSelected = _selectedTimeframe == timeframe;
          final isLoading = _loading[timeframe] ?? false;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeframe = timeframe),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        timeframe,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildChartTypeControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Chart type dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: _selectedSubChart == 1 ? 'heikin_ashi' : 
                     _selectedSubChart == 2 ? 'renko' : 'standard',
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('Standard')),
                DropdownMenuItem(value: 'heikin_ashi', child: Text('Heikin Ashi')),
                DropdownMenuItem(value: 'renko', child: Text('Renko')),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'standard') {
                    _selectedSubChart = 0;
                    _showHeikinAshi = false;
                    _showRenko = false;
                  } else if (value == 'heikin_ashi') {
                    _selectedSubChart = 1;
                    _showHeikinAshi = true;
                    _showRenko = false;
                  } else if (value == 'renko') {
                    _selectedSubChart = 2;
                    _showHeikinAshi = false;
                    _showRenko = true;
                  }
                });
              },
              underline: const SizedBox(),
            ),
          ),
          
          const Spacer(),
          
          // Renko brick size slider (only when Renko is selected)
          if (_showRenko)
            Expanded(
              child: Row(
                children: [
                  const Text('Brick Size: '),
                  Expanded(
                    child: Slider(
                      value: _renkoBrickSize,
                      min: 0.1,
                      max: 5,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() => _renkoBrickSize = value);
                      },
                    ),
                  ),
                  Text(_renkoBrickSize.toStringAsFixed(1)),
                ],
              ),
            ),
          
          // Comparison mode toggle
          IconButton(
            icon: Icon(
              _selectedSubChart > 0 ? Icons.compare_arrows : Icons.compare_arrows_outlined,
              color: _selectedSubChart > 0 ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                _selectedSubChart = _selectedSubChart == 0 ? 1 : 0;
              });
            },
            tooltip: 'Compare Timeframes',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainChart() {
    final data = _data[_selectedTimeframe];
    if (data == null || data.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    
    List<ChartData> displayData = data;
    
    // Apply Heikin Ashi conversion if enabled
    if (_showHeikinAshi) {
      displayData = _compression.convertToHeikinAshi(data);
    }
    
    // Apply compression for performance
    if (displayData.length > 500) {
      displayData = _compression.downsampleLTTB(displayData, 500);
    }
    
    return _buildPriceChart(displayData, _selectedTimeframe);
  }
  
  Widget _buildSubChart() {
    // Find lower timeframe for comparison
    final timeframes = widget.timeframes;
    final currentIndex = timeframes.indexOf(_selectedTimeframe);
    final lowerTimeframe = currentIndex > 0 ? timeframes[currentIndex - 1] : null;
    
    if (lowerTimeframe == null) return const SizedBox.shrink();
    
    final data = _data[lowerTimeframe];
    if (data == null || data.isEmpty) {
      return const Center(child: Text('Loading comparison data...'));
    }
    
    List<ChartData> displayData = data;
    
    // Apply Renko if selected
    if (_showRenko) {
      final renkoBricks = _compression.convertToRenko(data, _renkoBrickSize);
      return _buildRenkoChart(renkoBricks);
    }
    
    // Compress for performance
    if (displayData.length > 200) {
      displayData = _compression.downsampleLTTB(displayData, 200);
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: _buildPriceChart(displayData, lowerTimeframe, isSubChart: true),
    );
  }
  
  Widget _buildPriceChart(List<ChartData> data, String timeframe, {bool isSubChart = false}) {
    // This would integrate with your actual chart rendering library
    // Placeholder implementation
    return Container(
      color: Colors.black87,
      child: CustomPaint(
        painter: ChartPainter(
          data: data,
          timeframe: timeframe,
          isSubChart: isSubChart,
        ),
      ),
    );
  }
  
  Widget _buildRenkoChart(List<RenkoBrick> bricks) {
    // Renko chart rendering
    return Container(
      color: Colors.black87,
      child: CustomPaint(
        painter: RenkoChartPainter(bricks: bricks),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<ChartData> data;
  final String timeframe;
  final bool isSubChart;
  
  ChartPainter({
    required this.data,
    required this.timeframe,
    this.isSubChart = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Calculate scaling
    final maxPrice = data.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final minPrice = data.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;
    
    final width = size.width;
    final height = size.height;
    final xStep = width / (data.length - 1);
    
    // Draw candles
    for (var i = 0; i < data.length; i++) {
      final candle = data[i];
      final x = i * xStep;
      
      final highY = height - ((candle.high - minPrice) / priceRange) * height;
      final lowY = height - ((candle.low - minPrice) / priceRange) * height;
      final openY = height - ((candle.open - minPrice) / priceRange) * height;
      final closeY = height - ((candle.close - minPrice) / priceRange) * height;
      
      final isBullish = candle.close >= candle.open;
      paint.color = isBullish ? Colors.green : Colors.red;
      paint.style = PaintingStyle.fill;
      
      // Draw candle body
      final bodyTop = isBullish ? openY : closeY;
      final bodyBottom = isBullish ? closeY : openY;
      final bodyRect = Rect.fromLTRB(
        x - xStep * 0.3,
        bodyTop,
        x + xStep * 0.3,
        bodyBottom,
      );
      canvas.drawRect(bodyRect, paint);
      
      // Draw wick
      paint.style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RenkoChartPainter extends CustomPainter {
  final List<RenkoBrick> bricks;
  
  RenkoChartPainter({required this.bricks});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (bricks.isEmpty) return;
    
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final maxPrice = bricks.map((b) => b.high).reduce((a, b) => a > b ? a : b);
    final minPrice = bricks.map((b) => b.low).reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;
    
    final width = size.width;
    final height = size.height;
    final brickWidth = width / bricks.length;
    
    for (var i = 0; i < bricks.length; i++) {
      final brick = bricks[i];
      final x = i * brickWidth;
      
      final topY = height - ((brick.high - minPrice) / priceRange) * height;
      final bottomY = height - ((brick.low - minPrice) / priceRange) * height;
      
      paint.color = brick.color;
      
      canvas.drawRect(
        Rect.fromLTRB(x, topY, x + brickWidth - 1, bottomY),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
