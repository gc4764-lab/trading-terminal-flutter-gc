// lib/services/ohlcv_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../database/ohlcv_database.dart';
import '../models/chart_data.dart';
import '../services/broker_manager.dart';

class OHLCVService {
  static final OHLCVService _instance = OHLCVService._internal();
  final OHLCVDatabase _db = OHLCVDatabase();
  final Map<String, Timer> _prefetchTimers = {};
  final Map<String, List<ChartData>> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTimestamps = {};
  static const int _memoryCacheDuration = 5; // minutes
  
  factory OHLCVService() => _instance;
  OHLCVService._internal();
  
  // Get OHLCV data with caching strategy
  Future<List<ChartData>> getOHLCVData(
    String symbol,
    String timeframe, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool forceRefresh = false,
    String? brokerId,
  }) async {
    // Check memory cache first (fastest)
    if (!forceRefresh) {
      final cacheKey = _getCacheKey(symbol, timeframe, startDate, endDate, limit);
      final cached = _getFromMemoryCache(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    
    // Check local database
    final dbData = await _db.getOHLCVData(
      symbol,
      timeframe,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
    
    // If we have sufficient data in DB, return it
    if (dbData.isNotEmpty && !forceRefresh) {
      final metadata = await _db.getCacheMetadata(symbol, timeframe);
      final needsUpdate = _needsUpdate(metadata, timeframe);
      
      if (!needsUpdate) {
        // Cache in memory
        final cacheKey = _getCacheKey(symbol, timeframe, startDate, endDate, limit);
        _addToMemoryCache(cacheKey, dbData);
        return dbData;
      }
    }
    
    // Fetch from broker
    final brokerData = await _fetchFromBroker(symbol, timeframe, startDate, endDate, limit, brokerId);
    
    if (brokerData.isNotEmpty) {
      // Save to database
      await _db.saveOHLCVDataBatch(symbol, timeframe, brokerData);
      
      // Update memory cache
      final cacheKey = _getCacheKey(symbol, timeframe, startDate, endDate, limit);
      _addToMemoryCache(cacheKey, brokerData);
      
      // Trigger prefetch for adjacent timeframes
      _prefetchAdjacentData(symbol, timeframe, brokerData);
    }
    
    return brokerData;
  }
  
  // Fetch data from broker with retry logic
  Future<List<ChartData>> _fetchFromBroker(
    String symbol,
    String timeframe,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? brokerId,
  ) async {
    final brokerManager = BrokerManager();
    final broker = brokerId != null ? brokerManager.getBroker(brokerId) : brokerManager.getDefaultBroker();
    
    if (broker == null || !broker.isConnected) {
      return [];
    }
    
    // Set default date range if not provided
    final to = endDate ?? DateTime.now();
    final from = startDate ?? _getDefaultStartDate(timeframe, limit);
    
    try {
      final response = await broker.getHistoricalData(symbol, timeframe, from, to);
      
      if (response.success && response.data != null) {
        return _parseBrokerData(response.data, timeframe);
      }
    } catch (e) {
      debugPrint('Error fetching from broker: $e');
    }
    
    return [];
  }
  
  // Parse broker-specific data format
  List<ChartData> _parseBrokerData(dynamic data, String timeframe) {
    // Different brokers return different formats
    // This is a generic parser - customize for each broker
    final List<ChartData> result = [];
    
    if (data is List) {
      for (var candle in data) {
        if (candle is List && candle.length >= 6) {
          result.add(ChartData(
            date: DateTime.fromMillisecondsSinceEpoch(candle[0]),
            open: candle[1].toDouble(),
            high: candle[2].toDouble(),
            low: candle[3].toDouble(),
            close: candle[4].toDouble(),
            volume: candle[5].toDouble(),
          ));
        }
      }
    }
    
    return result;
  }
  
  // Get default start date based on timeframe and limit
  DateTime _getDefaultStartDate(String timeframe, int? limit) {
    final now = DateTime.now();
    final limitValue = limit ?? 500;
    
    switch (timeframe) {
      case '1m':
        return now.subtract(Duration(minutes: limitValue));
      case '5m':
        return now.subtract(Duration(minutes: limitValue * 5));
      case '15m':
        return now.subtract(Duration(minutes: limitValue * 15));
      case '1h':
        return now.subtract(Duration(hours: limitValue));
      case '4h':
        return now.subtract(Duration(hours: limitValue * 4));
      case '1d':
        return now.subtract(Duration(days: limitValue));
      case '1w':
        return now.subtract(Duration(days: limitValue * 7));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }
  
  // Check if cached data needs update
  bool _needsUpdate(Map<String, dynamic>? metadata, String timeframe) {
    if (metadata == null) return true;
    
    final lastUpdated = DateTime.fromMillisecondsSinceEpoch(metadata['last_updated'] as int);
    final now = DateTime.now();
    
    switch (timeframe) {
      case '1m':
        return now.difference(lastUpdated).inMinutes > 1;
      case '5m':
        return now.difference(lastUpdated).inMinutes > 5;
      case '15m':
        return now.difference(lastUpdated).inMinutes > 15;
      case '1h':
        return now.difference(lastUpdated).inHours > 1;
      case '4h':
        return now.difference(lastUpdated).inHours > 4;
      case '1d':
        return now.difference(lastUpdated).inDays > 1;
      default:
        return now.difference(lastUpdated).inHours > 1;
    }
  }
  
  // Memory cache management
  String _getCacheKey(String symbol, String timeframe, DateTime? startDate, DateTime? endDate, int? limit) {
    return '$symbol:$timeframe:${startDate?.millisecondsSinceEpoch}:${endDate?.millisecondsSinceEpoch}:$limit';
  }
  
  void _addToMemoryCache(String key, List<ChartData> data) {
    _memoryCache[key] = data;
    _memoryCacheTimestamps[key] = DateTime.now();
    
    // Clean old cache entries
    _cleanMemoryCache();
  }
  
  List<ChartData>? _getFromMemoryCache(String key) {
    final timestamp = _memoryCacheTimestamps[key];
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age.inMinutes < _memoryCacheDuration) {
        return _memoryCache[key];
      } else {
        // Remove expired cache
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
      }
    }
    return null;
  }
  
  void _cleanMemoryCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _memoryCacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inMinutes > _memoryCacheDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (var key in keysToRemove) {
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
    }
  }
  
  // Prefetch adjacent timeframes for faster switching
  void _prefetchAdjacentData(String symbol, String timeframe, List<ChartData> data) {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d', '1w'];
    final currentIndex = timeframes.indexOf(timeframe);
    
    // Prefetch higher and lower timeframes
    if (currentIndex > 0) {
      _prefetchData(symbol, timeframes[currentIndex - 1]);
    }
    if (currentIndex < timeframes.length - 1) {
      _prefetchData(symbol, timeframes[currentIndex + 1]);
    }
  }
  
  void _prefetchData(String symbol, String timeframe) {
    // Cancel existing prefetch timer
    final timerKey = '$symbol:$timeframe';
    _prefetchTimers[timerKey]?.cancel();
    
    // Schedule prefetch with delay
    _prefetchTimers[timerKey] = Timer(const Duration(seconds: 2), () async {
      await getOHLCVData(symbol, timeframe, limit: 200);
    });
  }
  
  // Update real-time data
  Future<void> updateRealTimeData(String symbol, String timeframe, ChartData newCandle) async {
    final dbData = await _db.getOHLCVData(
      symbol,
      timeframe,
      limit: 1,
    );
    
    if (dbData.isNotEmpty && dbData.last.date.isAtSameMomentAs(newCandle.date)) {
      // Update last candle
      // Implementation depends on database update logic
    } else {
      // Add new candle
      await _db.saveOHLCVDataBatch(symbol, timeframe, [newCandle]);
    }
    
    // Invalidate memory cache for this symbol/timeframe
    final keysToRemove = _memoryCache.keys
        .where((key) => key.startsWith('$symbol:$timeframe'))
        .toList();
    
    for (var key in keysToRemove) {
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
    }
  }
  
  // Get data with compression for older periods
  Future<List<ChartData>> getCompressedData(
    String symbol,
    String timeframe,
    DateTime startDate,
    DateTime endDate,
    int maxPoints,
  ) async {
    final fullData = await getOHLCVData(
      symbol,
      timeframe,
      startDate: startDate,
      endDate: endDate,
    );
    
    if (fullData.length <= maxPoints) {
      return fullData;
    }
    
    // Compress data by averaging
    final compressionFactor = fullData.length / maxPoints;
    final compressed = <ChartData>[];
    
    for (int i = 0; i < maxPoints; i++) {
      final startIdx = (i * compressionFactor).floor();
      final endIdx = ((i + 1) * compressionFactor).ceil();
      final segment = fullData.sublist(startIdx, endIdx.clamp(0, fullData.length));
      
      if (segment.isNotEmpty) {
        compressed.add(ChartData(
          date: segment.first.date,
          open: segment.first.open,
          high: segment.map((c) => c.high).reduce((a, b) => a > b ? a : b),
          low: segment.map((c) => c.low).reduce((a, b) => a < b ? a : b),
          close: segment.last.close,
          volume: segment.map((c) => c.volume).reduce((a, b) => a + b),
        ));
      }
    }
    
    return compressed;
  }
  
  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _db.getStorageStats();
  }
  
  // Optimize storage
  Future<void> optimizeStorage() async {
    await _db.optimizeDatabase();
  }
  
  // Clear old data
  Future<int> clearOldData(int daysOld) async {
    return await _db.deleteOldData(daysOld);
  }
  
  // Dispose resources
  void dispose() {
    for (var timer in _prefetchTimers.values) {
      timer.cancel();
    }
    _prefetchTimers.clear();
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
  }
}
