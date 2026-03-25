// lib/indicators/market_profile.dart
import 'dart:math';
import '../models/chart_data.dart';

class MarketProfile {
  final List<ChartData> data;
  final int timePeriods; // Number of 30-minute periods in a day
  
  MarketProfile(this.data, {this.timePeriods = 13}); // 6.5 hours trading day
  
  List<MarketProfileDay> calculate() {
    final days = <MarketProfileDay>[];
    var currentDay = <ChartData>[];
    DateTime? currentDate;
    
    // Group data by day
    for (var candle in data) {
      final candleDate = DateTime(candle.date.year, candle.date.month, candle.date.day);
      
      if (currentDate == null) {
        currentDate = candleDate;
      }
      
      if (candleDate.isAfter(currentDate)) {
        // Process previous day
        if (currentDay.isNotEmpty) {
          days.add(_processDay(currentDay, currentDate));
        }
        currentDay = [];
        currentDate = candleDate;
      }
      
      currentDay.add(candle);
    }
    
    // Process last day
    if (currentDay.isNotEmpty) {
      days.add(_processDay(currentDay, currentDate!));
    }
    
    return days;
  }
  
  MarketProfileDay _processDay(List<ChartData> dayData, DateTime date) {
    // Find price range for the day
    final high = dayData.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final low = dayData.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    
    // Create price buckets (usually 0.25 or 0.5 point increments)
    final bucketSize = _calculateBucketSize(high, low);
    final buckets = <PriceBucket>[];
    
    var currentPrice = low;
    while (currentPrice <= high) {
      buckets.add(PriceBucket(
        price: currentPrice,
        timePeriods: List.generate(timePeriods, (_) => false),
      ));
      currentPrice += bucketSize;
    }
    
    // Assign time periods to price buckets
    for (var candle in dayData) {
      final timePeriod = _getTimePeriod(candle.date);
      final price = candle.close;
      
      // Find bucket for this price
      for (var bucket in buckets) {
        if (price >= bucket.price && price < bucket.price + bucketSize) {
          bucket.timePeriods[timePeriod] = true;
          break;
        }
      }
    }
    
    // Calculate TPO (Time Price Opportunity) counts
    for (var bucket in buckets) {
      bucket.tpoCount = bucket.timePeriods.where((t) => t).length;
    }
    
    // Find POC (Point of Control)
    final maxTPO = buckets.map((b) => b.tpoCount).reduce((a, b) => a > b ? a : b);
    for (var bucket in buckets) {
      bucket.isPOC = bucket.tpoCount == maxTPO;
    }
    
    return MarketProfileDay(
      date: date,
      high: high,
      low: low,
      buckets: buckets,
      poc: buckets.firstWhere((b) => b.isPOC).price,
    );
  }
  
  double _calculateBucketSize(double high, double low) {
    final range = high - low;
    
    if (range < 10) return 0.25;
    if (range < 20) return 0.5;
    if (range < 50) return 1;
    return 2;
  }
  
  int _getTimePeriod(DateTime time) {
    // Assuming market hours 9:30 AM to 4:00 PM
    final minutesSinceOpen = time.hour * 60 + time.minute - (9 * 60 + 30);
    final periodIndex = (minutesSinceOpen / 30).floor();
    return periodIndex.clamp(0, timePeriods - 1);
  }
}

class MarketProfileDay {
  final DateTime date;
  final double high;
  final double low;
  final List<PriceBucket> buckets;
  final double poc;
  
  MarketProfileDay({
    required this.date,
    required this.high,
    required this.low,
    required this.buckets,
    required this.poc,
  });
  
  double get valueAreaHigh {
    // Value Area is where 70% of volume traded
    final totalTPO = buckets.fold(0, (sum, b) => sum + b.tpoCount);
    final targetTPO = totalTPO * 0.7;
    
    var accumulated = 0;
    var pocIndex = buckets.indexWhere((b) => b.isPOC);
    
    // Expand outward from POC
    var upper = pocIndex;
    var lower = pocIndex;
    
    while (accumulated < targetTPO) {
      if (upper + 1 < buckets.length) upper++;
      if (lower - 1 >= 0) lower--;
      
      for (var i = lower; i <= upper; i++) {
        accumulated += buckets[i].tpoCount;
      }
    }
    
    return buckets[upper].price;
  }
  
  double get valueAreaLow => buckets.firstWhere((b) => b.tpoCount > 0).price;
}

class PriceBucket {
  final double price;
  final List<bool> timePeriods;
  int tpoCount = 0;
  bool isPOC = false;
  
  PriceBucket({
    required this.price,
    required this.timePeriods,
  });
}
