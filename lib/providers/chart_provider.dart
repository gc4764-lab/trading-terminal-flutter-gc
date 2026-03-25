// lib/providers/chart_provider.dart
import 'package:flutter/material.dart';
import '../models/chart_data.dart';
import '../services/ohlcv_service.dart';

class ChartProvider extends ChangeNotifier {
  final OHLCVService _ohlcvService = OHLCVService();
  
  List<ChartData> _data = [];
  String _currentSymbol = '';
  String _currentTimeframe = '1h';
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _cacheStats = {};
  
  List<ChartData> get data => _data;
  String get currentSymbol => _currentSymbol;
  String get currentTimeframe => _currentTimeframe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get cacheStats => _cacheStats;
  
  Future<void> loadChartData({
    required String symbol,
    required String timeframe,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool forceRefresh = false,
  }) async {
    if (_currentSymbol == symbol && 
        _currentTimeframe == timeframe && 
        !forceRefresh && 
        _data.isNotEmpty) {
      return;
    }
    
    _isLoading = true;
    _currentSymbol = symbol;
    _currentTimeframe = timeframe;
    _error = null;
    notifyListeners();
    
    try {
      _data = await _ohlcvService.getOHLCVData(
        symbol,
        timeframe,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        forceRefresh: forceRefresh,
      );
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _data = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMoreData(int count) async {
    if (_data.isEmpty) return;
    
    final oldestDate = _data.first.date;
    final newData = await _ohlcvService.getOHLCVData(
      _currentSymbol,
      _currentTimeframe,
      endDate: oldestDate.subtract(const Duration(milliseconds: 1)),
      limit: count,
    );
    
    if (newData.isNotEmpty) {
      _data.insertAll(0, newData);
      notifyListeners();
    }
  }
  
  Future<void> refreshData() async {
    await loadChartData(
      symbol: _currentSymbol,
      timeframe: _currentTimeframe,
      forceRefresh: true,
    );
  }
  
  Future<void> updateWithRealTimeData(ChartData newCandle) async {
    if (_data.isEmpty) return;
    
    final lastCandle = _data.last;
    
    if (lastCandle.date.isAtSameMomentAs(newCandle.date)) {
      // Update existing candle
      _data[_data.length - 1] = newCandle;
    } else if (newCandle.date.isAfter(lastCandle.date)) {
      // Add new candle
      _data.add(newCandle);
      
      // Remove oldest if we exceed limit
      if (_data.length > 1000) {
        _data.removeAt(0);
      }
    }
    
    notifyListeners();
  }
  
  Future<Map<String, dynamic>> getStorageStats() async {
    _cacheStats = await _ohlcvService.getStorageStats();
    notifyListeners();
    return _cacheStats;
  }
  
  Future<void> clearOldData(int daysOld) async {
    await _ohlcvService.clearOldData(daysOld);
    await getStorageStats();
  }
  
  Future<void> optimizeStorage() async {
    await _ohlcvService.optimizeStorage();
    await getStorageStats();
  }
  
  void updateData(List<ChartData> newData) {
    _data = newData;
    notifyListeners();
  }
}
