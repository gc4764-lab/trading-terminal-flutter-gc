// lib/services/data_compression_service.dart
import 'dart:math';
import '../models/chart_data.dart';

class DataCompressionService {
  static final DataCompressionService _instance = DataCompressionService._internal();
  factory DataCompressionService() => _instance;
  DataCompressionService._internal();
  
  // Adaptive downsampling using Largest Triangle Three Buckets (LTTB) algorithm
  List<ChartData> downsampleLTTB(List<ChartData> data, int targetPoints) {
    if (data.length <= targetPoints) return data;
    
    final result = <ChartData>[];
    final bucketSize = (data.length - 2) / (targetPoints - 2);
    
    result.add(data.first);
    
    var a = 0;
    var nextA = 0;
    
    for (var i = 0; i < targetPoints - 2; i++) {
      final avgRangeStart = ((i + 1) * bucketSize).floor() + 1;
      final avgRangeEnd = (((i + 2) * bucketSize).floor() + 1).clamp(avgRangeStart + 1, data.length - 1);
      
      var avgX = 0.0;
      var avgY = 0.0;
      var avgRangeLength = 0;
      
      for (var j = avgRangeStart; j < avgRangeEnd; j++) {
        avgX += j.toDouble();
        avgY += data[j].close;
        avgRangeLength++;
      }
      
      avgX /= avgRangeLength;
      avgY /= avgRangeLength;
      
      var rangeOffs = (avgRangeStart + avgRangeEnd) / 2;
      var maxArea = -1.0;
      var maxAreaPoint = data[avgRangeStart];
      
      for (var j = avgRangeStart; j < avgRangeEnd; j++) {
        final area = ((data[a].date.millisecondsSinceEpoch - avgX) * 
                     (data[j].close - avgY) - 
                     (data[a].close - avgY) * 
                     (data[j].date.millisecondsSinceEpoch - avgX))
                     .abs();
        
        if (area > maxArea) {
          maxArea = area;
          maxAreaPoint = data[j];
          nextA = j;
        }
      }
      
      result.add(maxAreaPoint);
      a = nextA;
    }
    
    result.add(data.last);
    return result;
  }
  
  // Douglas-Peucker algorithm for line simplification
  List<ChartData> simplifyDouglasPeucker(List<ChartData> data, double epsilon) {
    if (data.length < 3) return data;
    
    var maxDistance = 0.0;
    var index = 0;
    final end = data.length - 1;
    
    for (var i = 1; i < end; i++) {
      final distance = _perpendicularDistance(data[i], data[0], data[end]);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }
    
    final result = <ChartData>[];
    
    if (maxDistance > epsilon) {
      final leftResults = simplifyDouglasPeucker(data.sublist(0, index + 1), epsilon);
      final rightResults = simplifyDouglasPeucker(data.sublist(index, data.length), epsilon);
      
      result.addAll(leftResults.sublist(0, leftResults.length - 1));
      result.addAll(rightResults);
    } else {
      result.add(data[0]);
      result.add(data[end]);
    }
    
    return result;
  }
  
  double _perpendicularDistance(ChartData point, ChartData lineStart, ChartData lineEnd) {
    final x0 = point.date.millisecondsSinceEpoch.toDouble();
    final y0 = point.close;
    final x1 = lineStart.date.millisecondsSinceEpoch.toDouble();
    final y1 = lineStart.close;
    final x2 = lineEnd.date.millisecondsSinceEpoch.toDouble();
    final y2 = lineEnd.close;
    
    final numerator = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    final denominator = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2));
    
    return denominator == 0 ? 0 : numerator / denominator;
  }
  
  // Smart data compression based on market volatility
  List<ChartData> smartCompress(List<ChartData> data, int maxPoints) {
    if (data.length <= maxPoints) return data;
    
    // Calculate volatility to determine compression ratio
    final volatilities = <double>[];
    for (var i = 1; i < data.length; i++) {
      final change = (data[i].close - data[i - 1].close).abs() / data[i - 1].close;
      volatilities.add(change);
    }
    
    final avgVolatility = volatilities.reduce((a, b) => a + b) / volatilities.length;
    final compressionRatio = data.length / maxPoints;
    
    // Adjust compression based on volatility (less compression for volatile periods)
    final dynamicRatio = compressionRatio / (1 + avgVolatility * 10);
    
    final result = <ChartData>[];
    result.add(data.first);
    
    var lastIndex = 0;
    for (var i = 1; i < data.length - 1; i++) {
      final shouldKeep = _shouldKeepPoint(data, i, lastIndex, dynamicRatio);
      if (shouldKeep) {
        result.add(data[i]);
        lastIndex = i;
      }
    }
    
    result.add(data.last);
    return result;
  }
  
  bool _shouldKeepPoint(List<ChartData> data, int index, int lastIndex, double ratio) {
    // Keep significant price movements and volume spikes
    final priceChange = (data[index].close - data[lastIndex].close).abs() / data[lastIndex].close;
    final volumeSpike = data[index].volume > (data[lastIndex].volume * 1.5);
    final timeGap = index - lastIndex;
    
    return priceChange > 0.001 || volumeSpike || timeGap > ratio;
  }
  
  // OHLC to Heikin-Ashi conversion
  List<ChartData> convertToHeikinAshi(List<ChartData> data) {
    final heikinAshi = <ChartData>[];
    double prevClose = 0;
    
    for (var i = 0; i < data.length; i++) {
      final haClose = (data[i].open + data[i].high + data[i].low + data[i].close) / 4;
      final haOpen = i == 0 ? data[i].open : (prevClose + heikinAshi.last.close) / 2;
      final haHigh = max(data[i].high, max(haOpen, haClose));
      final haLow = min(data[i].low, min(haOpen, haClose));
      
      heikinAshi.add(ChartData(
        date: data[i].date,
        open: haOpen,
        high: haHigh,
        low: haLow,
        close: haClose,
        volume: data[i].volume,
      ));
      
      prevClose = haClose;
    }
    
    return heikinAshi;
  }
  
  // Renko brick calculation
  List<RenkoBrick> convertToRenko(List<ChartData> data, double brickSize) {
    final bricks = <RenkoBrick>[];
    if (data.isEmpty) return bricks;
    
    var currentPrice = data.first.close;
    var currentDirection = 0; // 0: none, 1: up, -1: down
    
    for (var i = 1; i < data.length; i++) {
      final price = data[i].close;
      final change = price - currentPrice;
      
      if (change.abs() >= brickSize) {
        final numBricks = (change.abs() / brickSize).floor();
        final direction = change > 0 ? 1 : -1;
        
        if (currentDirection == 0) {
          currentDirection = direction;
        }
        
        for (var j = 0; j < numBricks; j++) {
          final brickHigh = currentPrice + (direction * brickSize);
          final brickLow = currentPrice;
          
          bricks.add(RenkoBrick(
            date: data[i].date,
            open: currentPrice,
            close: brickHigh,
            high: max(brickHigh, brickLow),
            low: min(brickHigh, brickLow),
            direction: direction,
          ));
          
          currentPrice = brickHigh;
        }
        
        currentDirection = direction;
      }
    }
    
    return bricks;
  }
}

class RenkoBrick {
  final DateTime date;
  final double open;
  final double close;
  final double high;
  final double low;
  final int direction; // 1: up, -1: down
  
  RenkoBrick({
    required this.date,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.direction,
  });
  
  bool get isBullish => direction == 1;
  Color get color => isBullish ? Colors.green : Colors.red;
}
