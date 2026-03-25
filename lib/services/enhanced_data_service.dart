// lib/services/enhanced_data_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/ohlcv_database.dart';
import 'ohlcv_service.dart';
import 'performance_monitor.dart';

class EnhancedDataService {
  static final EnhancedDataService _instance = EnhancedDataService._internal();
  final OHLCVDatabase _db = OHLCVDatabase();
  final OHLCVService _ohlcvService = OHLCVService();
  
  // Multi-level cache
  final Map<String, _CacheEntry> _l1Cache = {}; // Memory cache
  final Map<String, _CacheEntry> _l2Cache = {}; // Compressed memory cache
  final Map<String, DateTime> _l3CacheMetadata = {}; // Database cache metadata
  
  factory EnhancedDataService() => _instance;
  EnhancedDataService._internal();
  
  // Get data with intelligent caching strategy
  Future<List<ChartData>> getData({
    required String symbol,
    required String timeframe,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool forceRefresh = false,
    CacheLevel minCacheLevel = CacheLevel.l1,
  }) async {
    final cacheKey = _getCacheKey(symbol, timeframe, startDate, endDate, limit);
    
    // Check L1 cache (fastest)
    if (!forceRefresh && minCacheLevel <= CacheLevel.l1) {
      final l1Entry = _l1Cache[cacheKey];
      if (l1Entry != null && !_isExpired(l1Entry, timeframe)) {
        PerformanceMonitor().recordMetric('cache_hit_l1', 1);
        return l1Entry.data;
      }
    }
    
    // Check L2 cache (compressed)
    if (!forceRefresh && minCacheLevel <= CacheLevel.l2) {
      final l2Entry = _l2Cache[cacheKey];
      if (l2Entry != null && !_isExpired(l2Entry, timeframe)) {
        PerformanceMonitor().recordMetric('cache_hit_l2', 1);
        return l2Entry.data;
      }
    }
    
    // Check L3 cache (database)
    final dbStartTime = DateTime.now();
    final dbData = await _db.getOHLCVData(
      symbol,
      timeframe,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
    final dbLoadTime = DateTime.now().difference(dbStartTime).inMilliseconds;
    PerformanceMonitor().recordMetric('db_load_time', dbLoadTime.toDouble());
    
    if (dbData.isNotEmpty && !forceRefresh) {
      final metadata = await _db.getCacheMetadata(symbol, timeframe);
      final needsUpdate = _needsUpdate(metadata, timeframe);
      
      if (!needsUpdate) {
        // Store in L1 and L2 caches
        _updateCaches(cacheKey, dbData, timeframe);
        PerformanceMonitor().recordMetric('cache_hit_db', 1);
        return dbData;
      }
    }
    
    // Fetch from broker (slowest)
    final brokerStartTime = DateTime.now();
    final brokerData = await _fetchWithRetry(symbol, timeframe, startDate, endDate, limit);
    final brokerLoadTime = DateTime.now().difference(brokerStartTime).inMilliseconds;
    PerformanceMonitor().recordMetric('broker_load_time', brokerLoadTime.toDouble());
    
    if (brokerData.isNotEmpty) {
      // Save to database
      await _db.saveOHLCVDataBatch(symbol, timeframe, brokerData);
      
      // Update caches
      _updateCaches(cacheKey, brokerData, timeframe);
      
      // Trigger prefetch for adjacent timeframes
      _prefetchAdjacent(symbol, timeframe);
    }
    
    return brokerData;
  }
  
  // Intelligent prefetching based on user behavior
  Future<void> prefetchIntelligent(String symbol, String currentTimeframe) async {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d', '1w'];
    final currentIndex = timeframes.indexOf(currentTimeframe);
    
    // Prefetch higher timeframe (for context)
    if (currentIndex > 0) {
      unawaited(getData(
        symbol: symbol,
        timeframe: timeframes[currentIndex - 1],
        limit: 100,
      ));
    }
    
    // Prefetch lower timeframe (for detail)
    if (currentIndex < timeframes.length - 1) {
      unawaited(getData(
        symbol: symbol,
        timeframe: timeframes[currentIndex + 1],
        limit: 200,
      ));
    }
    
    // Prefetch correlated symbols (based on historical correlation)
    final correlatedSymbols = await _getCorrelatedSymbols(symbol);
    for (var corrSymbol in correlatedSymbols.take(3)) {
      unawaited(getData(
        symbol: corrSymbol,
        timeframe: currentTimeframe,
        limit: 100,
      ));
    }
  }
  
  Future<List<String>> _getCorrelatedSymbols(String symbol) async {
    // Placeholder - implement correlation analysis
    return [];
  }
  
  Future<List<ChartData>> _fetchWithRetry(
    String symbol,
    String timeframe,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    {int retries = 3}
  ) async {
    for (var i = 0; i < retries; i++) {
      try {
        return await _ohlcvService.getOHLCVData(
          symbol,
          timeframe,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
          forceRefresh: true,
        );
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    return [];
  }
  
  void _updateCaches(String key, List<ChartData> data, String timeframe) {
    // L1 cache - full data
    _l1Cache[key] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: _getTTL(timeframe),
    );
    
    // L2 cache - compressed data (for older periods)
    if (data.length > 200) {
      final compressed = _compressData(data, 200);
      _l2Cache[key] = _CacheEntry(
        data: compressed,
        timestamp: DateTime.now(),
        ttl: _getTTL(timeframe) * 2,
      );
    }
    
    // Clean old cache entries
    _cleanExpiredCache();
  }
  
  List<ChartData> _compressData(List<ChartData> data, int targetPoints) {
    if (data.length <= targetPoints) return data;
    
    final step = data.length / targetPoints;
    final compressed = <ChartData>[];
    
    for (var i = 0; i < targetPoints; i++) {
      final start = (i * step).floor();
      final end = ((i + 1) * step).ceil();
      final segment = data.sublist(start, end.clamp(0, data.length));
      
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
  
  Duration _getTTL(String timeframe) {
    switch (timeframe) {
      case '1m': return const Duration(minutes: 1);
      case '5m': return const Duration(minutes: 5);
      case '15m': return const Duration(minutes: 15);
      case '1h': return const Duration(hours: 1);
      case '4h': return const Duration(hours: 4);
      case '1d': return const Duration(days: 1);
      default: return const Duration(hours: 1);
    }
  }
  
  bool _isExpired(_CacheEntry entry, String timeframe) {
    final ttl = _getTTL(timeframe);
    return DateTime.now().difference(entry.timestamp) > ttl;
  }
  
  void _cleanExpiredCache() {
    final now = DateTime.now();
    
    _l1Cache.removeWhere((key, entry) => 
        now.difference(entry.timestamp) > entry.ttl);
    _l2Cache.removeWhere((key, entry) => 
        now.difference(entry.timestamp) > entry.ttl);
  }
  
  bool _needsUpdate(Map<String, dynamic>? metadata, String timeframe) {
    if (metadata == null) return true;
    
    final lastUpdated = DateTime.fromMillisecondsSinceEpoch(metadata['last_updated'] as int);
    final now = DateTime.now();
    final maxAge = _getMaxAge(timeframe);
    
    return now.difference(lastUpdated) > maxAge;
  }
  
  Duration _getMaxAge(String timeframe) {
    switch (timeframe) {
      case '1m': return const Duration(minutes: 5);
      case '5m': return const Duration(minutes: 15);
      case '15m': return const Duration(minutes: 30);
      case '1h': return const Duration(hours: 2);
      case '4h': return const Duration(hours: 8);
      case '1d': return const Duration(days: 1);
      default: return const Duration(hours: 2);
    }
  }
  
  void _prefetchAdjacent(String symbol, String timeframe) {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d', '1w'];
    final currentIndex = timeframes.indexOf(timeframe);
    
    if (currentIndex > 0) {
      unawaited(getData(
        symbol: symbol,
        timeframe: timeframes[currentIndex - 1],
        limit: 100,
      ));
    }
    
    if (currentIndex < timeframes.length - 1) {
      unawaited(getData(
        symbol: symbol,
        timeframe: timeframes[currentIndex + 1],
        limit: 100,
      ));
    }
  }
  
  String _getCacheKey(String symbol, String timeframe, DateTime? startDate, DateTime? endDate, int? limit) {
    return '$symbol:$timeframe:${startDate?.millisecondsSinceEpoch}:${endDate?.millisecondsSinceEpoch}:$limit';
  }
  
  void clearCache() {
    _l1Cache.clear();
    _l2Cache.clear();
    _l3CacheMetadata.clear();
  }
}

enum CacheLevel {
  l1, // Memory cache (fastest)
  l2, // Compressed memory cache
  l3, // Database cache
  broker, // Live broker data (slowest)
}

class _CacheEntry {
  final List<ChartData> data;
  final DateTime timestamp;
  final Duration ttl;
  
  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
}

