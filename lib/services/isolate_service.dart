// lib/services/isolate_service.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';

class IsolateService {
  static Isolate? _isolate;
  static SendPort? _sendPort;
  static final ReceivePort _receivePort = ReceivePort();
  static final Map<String, Completer<dynamic>> _completers = {};
  
  static Future<void> initialize() async {
    if (_isolate != null) return;
    
    if (kIsWeb) {
      // Web doesn't support isolates, use compute instead
      return;
    }
    
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
    
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is Map) {
        final id = message['id'];
        final result = message['result'];
        final error = message['error'];
        
        if (_completers.containsKey(id)) {
          if (error != null) {
            _completers[id]!.completeError(error);
          } else {
            _completers[id]!.complete(result);
          }
          _completers.remove(id);
        }
      }
    });
  }
  
  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((message) async {
      final id = message['id'];
      final type = message['type'];
      final data = message['data'];
      
      try {
        dynamic result;
        
        switch (type) {
          case 'calculateIndicators':
            result = await _calculateIndicators(data);
            break;
          case 'downsampleData':
            result = await _downsampleData(data);
            break;
          case 'calculateRisk':
            result = await _calculateRisk(data);
            break;
          case 'optimizePortfolio':
            result = await _optimizePortfolio(data);
            break;
        }
        
        sendPort.send({
          'id': id,
          'result': result,
        });
      } catch (e) {
        sendPort.send({
          'id': id,
          'error': e.toString(),
        });
      }
    });
  }
  
  static Future<dynamic> sendMessage(String type, dynamic data) async {
    if (_isolate == null || _sendPort == null) {
      await initialize();
    }
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<dynamic>();
    _completers[id] = completer;
    
    _sendPort?.send({
      'id': id,
      'type': type,
      'data': data,
    });
    
    return completer.future;
  }
  
  static Future<List<double>> _calculateIndicators(Map<String, dynamic> data) async {
    final prices = data['prices'] as List<double>;
    final indicator = data['indicator'] as String;
    
    switch (indicator) {
      case 'sma':
        final period = data['period'] as int;
        return _calculateSMA(prices, period);
      case 'ema':
        final period = data['period'] as int;
        return _calculateEMA(prices, period);
      case 'rsi':
        final period = data['period'] as int;
        return _calculateRSI(prices, period);
      default:
        return [];
    }
  }
  
  static List<double> _calculateSMA(List<double> prices, int period) {
    final result = <double>[];
    for (var i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        result.add(0);
      } else {
        var sum = 0.0;
        for (var j = i - period + 1; j <= i; j++) {
          sum += prices[j];
        }
        result.add(sum / period);
      }
    }
    return result;
  }
  
  static List<double> _calculateEMA(List<double> prices, int period) {
    final result = <double>[];
    final multiplier = 2.0 / (period + 1);
    
    for (var i = 0; i < prices.length; i++) {
      if (i == 0) {
        result.add(prices[i]);
      } else {
        result.add((prices[i] - result[i - 1]) * multiplier + result[i - 1]);
      }
    }
    return result;
  }
  
  static List<double> _calculateRSI(List<double> prices, int period) {
    final result = <double>[];
    var avgGain = 0.0;
    var avgLoss = 0.0;
    
    for (var i = 1; i <= period; i++) {
      final change = prices[i] - prices[i - 1];
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss -= change;
      }
    }
    
    avgGain /= period;
    avgLoss /= period;
    
    for (var i = period; i < prices.length; i++) {
      if (i > period) {
        final change = prices[i] - prices[i - 1];
        if (change > 0) {
          avgGain = (avgGain * (period - 1) + change) / period;
          avgLoss = (avgLoss * (period - 1)) / period;
        } else {
          avgGain = (avgGain * (period - 1)) / period;
          avgLoss = (avgLoss * (period - 1) - change) / period;
        }
      }
      
      final rs = avgGain / avgLoss;
      final rsi = 100 - (100 / (1 + rs));
      result.add(rsi);
    }
    
    return result;
  }
  
  static Future<List<Map<String, dynamic>>> _downsampleData(Map<String, dynamic> data) async {
    final points = data['points'] as List<Map<String, dynamic>>;
    final targetPoints = data['targetPoints'] as int;
    
    if (points.length <= targetPoints) return points;
    
    final result = <Map<String, dynamic>>[];
    final bucketSize = (points.length - 2) / (targetPoints - 2);
    
    result.add(points.first);
    
    var a = 0;
    for (var i = 0; i < targetPoints - 2; i++) {
      final avgRangeStart = ((i + 1) * bucketSize).floor() + 1;
      final avgRangeEnd = (((i + 2) * bucketSize).floor() + 1).clamp(avgRangeStart + 1, points.length - 1);
      
      var avgX = 0.0;
      var avgY = 0.0;
      for (var j = avgRangeStart; j < avgRangeEnd; j++) {
        avgX += j.toDouble();
        avgY += points[j]['y'];
      }
      avgX /= (avgRangeEnd - avgRangeStart);
      avgY /= (avgRangeEnd - avgRangeStart);
      
      var maxArea = -1.0;
      var maxAreaPoint = points[avgRangeStart];
      var nextA = 0;
      
      for (var j = avgRangeStart; j < avgRangeEnd; j++) {
        final area = ((points[a]['x'] - avgX) * (points[j]['y'] - avgY) -
                      (points[a]['y'] - avgY) * (points[j]['x'] - avgX))
                      .abs();
        if (area > maxArea) {
          maxArea = area;
          maxAreaPoint = points[j];
          nextA = j;
        }
      }
      
      result.add(maxAreaPoint);
      a = nextA;
    }
    
    result.add(points.last);
    return result;
  }
  
  static Future<Map<String, dynamic>> _calculateRisk(Map<String, dynamic> data) async {
    final positions = data['positions'] as List<Map<String, dynamic>>;
    final portfolio = data['portfolio'] as Map<String, dynamic>;
    
    // Calculate VaR, CVaR, etc.
    final returns = positions.map((p) => p['return'] as double).toList();
    returns.sort();
    
    final var95Index = (returns.length * 0.05).floor();
    final var95 = returns[var95Index];
    
    final cvar = returns.sublist(0, var95Index).reduce((a, b) => a + b) / var95Index;
    
    return {
      'valueAtRisk': var95,
      'conditionalVaR': cvar,
      'sharpeRatio': _calculateSharpeRatio(returns),
      'maxDrawdown': _calculateMaxDrawdown(returns),
    };
  }
  
  static double _calculateSharpeRatio(List<double> returns) {
    final avg = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => (r - avg) * (r - avg)).reduce((a, b) => a + b) / returns.length;
    final stdDev = variance.sqrt();
    return stdDev > 0 ? avg / stdDev : 0;
  }
  
  static double _calculateMaxDrawdown(List<double> returns) {
    var peak = returns[0];
    var maxDrawdown = 0.0;
    
    for (var i = 1; i < returns.length; i++) {
      if (returns[i] > peak) {
        peak = returns[i];
      }
      final drawdown = (peak - returns[i]) / peak;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }
    
    return maxDrawdown * 100;
  }
  
  static Future<Map<String, dynamic>> _optimizePortfolio(Map<String, dynamic> data) async {
    // Portfolio optimization using mean-variance optimization
    final assets = data['assets'] as List<Map<String, dynamic>>;
    final returns = assets.map((a) => a['returns'] as List<double>).toList();
    
    // Simplified optimization - would use actual optimization algorithms in production
    final weights = List.filled(assets.length, 1.0 / assets.length);
    final expectedReturn = _calculatePortfolioReturn(weights, returns);
    final risk = _calculatePortfolioRisk(weights, returns);
    
    return {
      'weights': weights,
      'expectedReturn': expectedReturn,
      'risk': risk,
      'sharpeRatio': expectedReturn / risk,
    };
  }
  
  static double _calculatePortfolioReturn(List<double> weights, List<List<double>> returns) {
    var totalReturn = 0.0;
    for (var i = 0; i < weights.length; i++) {
      final assetReturn = returns[i].reduce((a, b) => a + b) / returns[i].length;
      totalReturn += weights[i] * assetReturn;
    }
    return totalReturn;
  }
  
  static double _calculatePortfolioRisk(List<double> weights, List<List<double>> returns) {
    // Simplified risk calculation - would use covariance matrix in production
    var variance = 0.0;
    for (var i = 0; i < weights.length; i++) {
      final assetVariance = returns[i]
          .map((r) => (r - (returns[i].reduce((a, b) => a + b) / returns[i].length)).abs())
          .reduce((a, b) => a + b) / returns[i].length;
      variance += weights[i] * weights[i] * assetVariance;
    }
    return variance.sqrt();
  }
}
