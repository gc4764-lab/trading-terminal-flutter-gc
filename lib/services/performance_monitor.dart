// lib/services/performance_monitor.dart
import 'dart:developer';
import 'dart:async';
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();
  
  final Map<String, List<PerformanceMetric>> _metrics = {};
  Timer? _reportTimer;
  
  void startMonitoring({int reportIntervalSeconds = 60}) {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(Duration(seconds: reportIntervalSeconds), (timer) {
      _generateReport();
    });
  }
  
  void recordMetric(String name, double value, {Map<String, dynamic>? tags}) {
    final metric = PerformanceMetric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
      tags: tags,
    );
    
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    
    _metrics[name]!.add(metric);
    
    // Keep only last 1000 metrics per name
    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeAt(0);
    }
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Performance: $name = $value ${tags != null ? tags.toString() : ''}');
    }
  }
  
  void recordChartRenderTime(int durationMs, String symbol, String timeframe) {
    recordMetric(
      'chart_render_time',
      durationMs.toDouble(),
      tags: {
        'symbol': symbol,
        'timeframe': timeframe,
      },
    );
  }
  
  void recordDataLoadTime(int durationMs, String symbol, String timeframe, String source) {
    recordMetric(
      'data_load_time',
      durationMs.toDouble(),
      tags: {
        'symbol': symbol,
        'timeframe': timeframe,
        'source': source,
      },
    );
  }
  
  void recordMemoryUsage() {
    if (kDebugMode) {
      // Note: Actual memory usage monitoring requires platform-specific code
      // This is a placeholder
      recordMetric('memory_usage_mb', 0);
    }
  }
  
  void recordFrameRate(double fps) {
    recordMetric('frame_rate', fps);
  }
  
  void _generateReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': {},
    };
    
    for (var entry in _metrics.entries) {
      final metrics = entry.value;
      if (metrics.isEmpty) continue;
      
      final values = metrics.map((m) => m.value).toList();
      report['metrics'][entry.key] = {
        'avg': values.reduce((a, b) => a + b) / values.length,
        'max': values.reduce((a, b) => a > b ? a : b),
        'min': values.reduce((a, b) => a < b ? a : b),
        'count': values.length,
      };
    }
    
    if (kDebugMode) {
      debugPrint('Performance Report: ${report.toString()}');
    }
  }
  
  void stopMonitoring() {
    _reportTimer?.cancel();
    _reportTimer = null;
  }
  
  void dispose() {
    stopMonitoring();
    _metrics.clear();
  }
}

class PerformanceMetric {
  final String name;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? tags;
  
  PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    this.tags,
  });
}

// Extension for measuring execution time
extension MeasureTime on Future {
  static Future<T> measure<T>(Future<T> Function() callback, String name, 
      {Map<String, dynamic>? tags}) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await callback();
    } finally {
      stopwatch.stop();
      PerformanceMonitor().recordMetric(name, stopwatch.elapsedMilliseconds.toDouble(), tags: tags);
    }
  }
}

// Widget performance observer
class PerformanceObserver extends StatelessWidget {
  final Widget child;
  final String name;
  final Map<String, dynamic>? tags;
  
  const PerformanceObserver({
    Key? key,
    required this.child,
    required this.name,
    this.tags,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return PerformanceObserverWidget(
      name: name,
      tags: tags,
      child: child,
    );
  }
}

class PerformanceObserverWidget extends StatefulWidget {
  final Widget child;
  final String name;
  final Map<String, dynamic>? tags;
  
  const PerformanceObserverWidget({
    Key? key,
    required this.child,
    required this.name,
    this.tags,
  }) : super(key: key);
  
  @override
  _PerformanceObserverWidgetState createState() => _PerformanceObserverWidgetState();
}

class _PerformanceObserverWidgetState extends State<PerformanceObserverWidget> {
  DateTime? _buildStart;
  
  @override
  void initState() {
    super.initState();
    _buildStart = DateTime.now();
  }
  
  @override
  void dispose() {
    final buildTime = DateTime.now().difference(_buildStart!).inMilliseconds;
    PerformanceMonitor().recordMetric(
      'widget_build_time_${widget.name}',
      buildTime.toDouble(),
      tags: widget.tags,
    );
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
