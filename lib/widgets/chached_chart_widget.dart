// lib/widgets/cached_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ohlcv_service.dart';
import '../models/chart_data.dart';
import '../providers/chart_provider.dart';

class CachedChartWidget extends StatefulWidget {
  final String symbol;
  final String timeframe;
  final Function(ChartData)? onCandleTap;
  
  const CachedChartWidget({
    Key? key,
    required this.symbol,
    required this.timeframe,
    this.onCandleTap,
  }) : super(key: key);

  @override
  _CachedChartWidgetState createState() => _CachedChartWidgetState();
}

class _CachedChartWidgetState extends State<CachedChartWidget> {
  final OHLCVService _ohlcvService = OHLCVService();
  List<ChartData> _data = [];
  bool _isLoading = true;
  String? _error;
  bool _isLive = true;
  Timer? _liveUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _startLiveUpdates();
  }
  
  @override
  void didUpdateWidget(CachedChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.timeframe != widget.timeframe) {
      _loadData();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final data = await _ohlcvService.getOHLCVData(
        widget.symbol,
        widget.timeframe,
        limit: 500,
      );
      
      setState(() {
        _data = data;
        _isLoading = false;
      });
      
      // Notify provider
      Provider.of<ChartProvider>(context, listen: false).updateData(data);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _startLiveUpdates() {
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLive && mounted) {
        _checkForUpdates();
      }
    });
  }
  
  Future<void> _checkForUpdates() async {
    // Check if new data is available
    final latestData = await _ohlcvService.getOHLCVData(
      widget.symbol,
      widget.timeframe,
      limit: 1,
    );
    
    if (latestData.isNotEmpty && _data.isNotEmpty) {
      final lastCached = _data.last;
      final latest = latestData.last;
      
      if (latest.date.isAfter(lastCached.date)) {
        // New candle available
        setState(() {
          _data.add(latest);
        });
      } else if (latest.date.isAtSameMomentAs(lastCached.date) && 
                 latest.close != lastCached.close) {
        // Update last candle
        setState(() {
          _data[_data.length - 1] = latest;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chart data...'),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }
    
    return _buildChart();
  }
  
  Widget _buildChart() {
    return Column(
      children: [
        // Chart controls
        _buildChartControls(),
        
        // Chart
        Expanded(
          child: _buildPriceChart(),
        ),
        
        // Volume/Indicators
        if (_showVolume)
          _buildVolumeChart(),
      ],
    );
  }
  
  Widget _buildChartControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isLive ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLive ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isLive ? 'LIVE' : 'PAUSED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Data source indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage, size: 12),
                SizedBox(width: 4),
                Text(
                  'Cached',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
    );
  }
  
  bool _showVolume = true;
  
  Widget _buildPriceChart() {
    // Implement actual chart rendering using your preferred charting library
    return Container(
      color: Colors.black87,
      child: Center(
        child: Text('Chart will be rendered here with $_data candles'),
      ),
    );
  }
  
  Widget _buildVolumeChart() {
    return Container(
      height: 100,
      color: Colors.black54,
      child: const Center(
        child: Text('Volume chart'),
      ),
    );
  }
  
  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    super.dispose();
  }
}
