// lib/indicators/volume_profile.dart
import 'dart:math';
import '../models/chart_data.dart';

class VolumeProfile {
  final List<ChartData> data;
  final int numberOfRows;
  
  VolumeProfile(this.data, {this.numberOfRows = 20});
  
  List<VolumeProfileRow> calculate() {
    if (data.isEmpty) return [];
    
    // Find price range
    final maxPrice = data.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final minPrice = data.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;
    final rowHeight = priceRange / numberOfRows;
    
    // Initialize rows
    final rows = <VolumeProfileRow>[];
    for (var i = 0; i < numberOfRows; i++) {
      final rowLow = minPrice + (i * rowHeight);
      final rowHigh = rowLow + rowHeight;
      rows.add(VolumeProfileRow(
        priceLevel: (rowLow + rowHigh) / 2,
        low: rowLow,
        high: rowHigh,
        volume: 0,
      ));
    }
    
    // Calculate volume for each candle
    for (var candle in data) {
      final candleVolume = candle.volume;
      final candleLow = candle.low;
      final candleHigh = candle.high;
      
      for (var row in rows) {
        // Check overlap between candle and price row
        if (candleHigh >= row.low && candleLow <= row.high) {
          // Calculate overlap percentage
          final overlapStart = max(candleLow, row.low);
          final overlapEnd = min(candleHigh, row.high);
          final overlapLength = overlapEnd - overlapStart;
          final candleLength = candleHigh - candleLow;
          
          final volumePortion = candleVolume * (overlapLength / candleLength);
          row.volume += volumePortion;
        }
      }
    }
    
    // Find POC (Point of Control) - highest volume row
    final maxVolume = rows.map((r) => r.volume).reduce((a, b) => a > b ? a : b);
    for (var row in rows) {
      row.isPOC = row.volume == maxVolume;
    }
    
    return rows;
  }
  
  // Calculate Value Area (70% of volume)
  static List<VolumeProfileRow> calculateValueArea(List<VolumeProfileRow> rows) {
    final sortedRows = List<VolumeProfileRow>.from(rows);
    sortedRows.sort((a, b) => b.volume.compareTo(a.volume));
    
    final totalVolume = rows.fold(0.0, (sum, row) => sum + row.volume);
    final targetVolume = totalVolume * 0.7;
    
    var accumulatedVolume = 0.0;
    final valueAreaRows = <VolumeProfileRow>[];
    
    for (var row in sortedRows) {
      valueAreaRows.add(row);
      accumulatedVolume += row.volume;
      if (accumulatedVolume >= targetVolume) break;
    }
    
    return valueAreaRows;
  }
}

class VolumeProfileRow {
  final double priceLevel;
  final double low;
  final double high;
  double volume;
  bool isPOC;
  
  VolumeProfileRow({
    required this.priceLevel,
    required this.low,
    required this.high,
    required this.volume,
    this.isPOC = false,
  });
}
