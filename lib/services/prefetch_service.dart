// lib/services/prefetch_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'ohlcv_service.dart';
import '../providers/watchlist_provider.dart';

class PrefetchService {
  static final PrefetchService _instance = PrefetchService._internal();
  final OHLCVService _ohlcvService = OHLCVService();
  Timer? _prefetchTimer;
  final Set<String> _prefetchedSymbols = {};
  final Map<String, DateTime> _lastPrefetch = {};
  
  factory PrefetchService() => _instance;
  PrefetchService._internal();
  
  // Start background prefetching
  void startPrefetching(WatchlistProvider watchlistProvider) {
    _prefetchTimer?.cancel();
    
    _prefetchTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _prefetchWatchlistData(watchlistProvider);
    });
  }
  
  Future<void> _prefetchWatchlistData(WatchlistProvider watchlistProvider) async {
    final watchlist = watchlistProvider.activeWatchlist;
    final symbols = watchlist.symbols;
    
    // Prefetch common timeframes
    const timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];
    
    for (var symbol in symbols) {
      final now = DateTime.now();
      final lastPrefetch = _lastPrefetch[symbol];
      
      // Only prefetch if not done recently (within last 10 minutes)
      if (lastPrefetch == null || now.difference(lastPrefetch).inMinutes > 10) {
        _lastPrefetch[symbol] = now;
        
        for (var timeframe in timeframes) {
          await _prefetchData(symbol, timeframe);
        }
      }
    }
  }
  
  Future<void> _prefetchData(String symbol, String timeframe) async {
    try {
      await _ohlcvService.getOHLCVData(
        symbol,
        timeframe,
        limit: 500,
      );
      
      _prefetchedSymbols.add('$symbol:$timeframe');
    } catch (e) {
      debugPrint('Prefetch error for $symbol $timeframe: $e');
    }
  }
  
  // Prefetch on app launch
  Future<void> prefetchOnLaunch(List<String> symbols) async {
    final timeframes = ['1d', '4h', '1h']; // Most common timeframes
    
    for (var symbol in symbols) {
      for (var timeframe in timeframes) {
        unawaited(_prefetchData(symbol, timeframe));
      }
    }
  }
  
  // Get prefetch status
  bool isPrefetched(String symbol, String timeframe) {
    return _prefetchedSymbols.contains('$symbol:$timeframe');
  }
  
  // Stop prefetching
  void stopPrefetching() {
    _prefetchTimer?.cancel();
    _prefetchTimer = null;
  }
  
  // Dispose
  void dispose() {
    stopPrefetching();
  }
}
