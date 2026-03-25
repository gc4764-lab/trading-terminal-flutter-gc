// lib/indicators/order_flow.dart
import '../models/chart_data.dart';
import '../models/trade.dart';

class OrderFlowAnalyzer {
  final List<Trade> trades;
  final List<ChartData> candles;
  
  OrderFlowAnalyzer({required this.trades, required this.candles});
  
  OrderFlowData analyze() {
    final delta = <DeltaData>[];
    var cumulativeDelta = 0.0;
    var buyVolume = 0.0;
    var sellVolume = 0.0;
    
    // Calculate delta for each trade
    for (var trade in trades) {
      final tradeDelta = trade.side == OrderSide.buy ? trade.volume : -trade.volume;
      cumulativeDelta += tradeDelta;
      
      if (trade.side == OrderSide.buy) {
        buyVolume += trade.volume;
      } else {
        sellVolume += trade.volume;
      }
      
      delta.add(DeltaData(
        timestamp: trade.timestamp,
        delta: tradeDelta,
        cumulativeDelta: cumulativeDelta,
      ));
    }
    
    // Identify absorption and exhaustion patterns
    final patterns = <OrderFlowPattern>[];
    
    for (var i = 1; i < candles.length; i++) {
      final candle = candles[i];
      final previousCandle = candles[i - 1];
      
      // Check for absorption (large volume with small price movement)
      if (candle.volume > previousCandle.volume * 2) {
        final priceRange = (candle.high - candle.low).abs();
        if (priceRange < previousCandle.high - previousCandle.low) {
          patterns.add(OrderFlowPattern(
            timestamp: candle.date,
            type: PatternType.absorption,
            strength: candle.volume / previousCandle.volume,
          ));
        }
      }
      
      // Check for exhaustion (large volume with reversal)
      if (candle.volume > previousCandle.volume * 1.5) {
        final isBullishExhaustion = candle.close < candle.open && 
                                    previousCandle.close > previousCandle.open;
        final isBearishExhaustion = candle.close > candle.open && 
                                    previousCandle.close < previousCandle.open;
        
        if (isBullishExhaustion || isBearishExhaustion) {
          patterns.add(OrderFlowPattern(
            timestamp: candle.date,
            type: PatternType.exhaustion,
            strength: candle.volume / previousCandle.volume,
          ));
        }
      }
    }
    
    return OrderFlowData(
      totalBuyVolume: buyVolume,
      totalSellVolume: sellVolume,
      netDelta: cumulativeDelta,
      deltaData: delta,
      patterns: patterns,
    );
  }
  
  // Calculate Volume Weighted Average Price (VWAP)
  List<VWAPPoint> calculateVWAP() {
    final vwapPoints = <VWAPPoint>[];
    var cumulativePV = 0.0;
    var cumulativeVolume = 0.0;
    
    for (var candle in candles) {
      final typicalPrice = (candle.high + candle.low + candle.close) / 3;
      cumulativePV += typicalPrice * candle.volume;
      cumulativeVolume += candle.volume;
      
      vwapPoints.add(VWAPPoint(
        timestamp: candle.date,
        vwap: cumulativePV / cumulativeVolume,
      ));
    }
    
    return vwapPoints;
  }
  
  // Identify large traders (whale) activity
  List<WhaleTrade> detectWhaleTrades(double threshold) {
    final whaleTrades = <WhaleTrade>[];
    
    for (var trade in trades) {
      if (trade.volume >= threshold) {
        whaleTrades.add(WhaleTrade(
          timestamp: trade.timestamp,
          volume: trade.volume,
          side: trade.side,
          price: trade.price,
        ));
      }
    }
    
    return whaleTrades;
  }
}

class OrderFlowData {
  final double totalBuyVolume;
  final double totalSellVolume;
  final double netDelta;
  final List<DeltaData> deltaData;
  final List<OrderFlowPattern> patterns;
  
  OrderFlowData({
    required this.totalBuyVolume,
    required this.totalSellVolume,
    required this.netDelta,
    required this.deltaData,
    required this.patterns,
  });
  
  double get buySellRatio => totalSellVolume > 0 ? totalBuyVolume / totalSellVolume : 0;
}

class DeltaData {
  final DateTime timestamp;
  final double delta;
  final double cumulativeDelta;
  
  DeltaData({
    required this.timestamp,
    required this.delta,
    required this.cumulativeDelta,
  });
}

class OrderFlowPattern {
  final DateTime timestamp;
  final PatternType type;
  final double strength;
  
  OrderFlowPattern({
    required this.timestamp,
    required this.type,
    required this.strength,
  });
}

enum PatternType {
  absorption,
  exhaustion,
  iceberg,
  spoofing,
}

class WhaleTrade {
  final DateTime timestamp;
  final double volume;
  final OrderSide side;
  final double price;
  
  WhaleTrade({
    required this.timestamp,
    required this.volume,
    required this.side,
    required this.price,
  });
}

class VWAPPoint {
  final DateTime timestamp;
  final double vwap;
  
  VWAPPoint({
    required this.timestamp,
    required this.vwap,
  });
}
