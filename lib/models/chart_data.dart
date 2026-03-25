// lib/models/chart_data.dart
class ChartData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  
  ChartData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
  
  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      date: DateTime.parse(json['date']),
      open: json['open'].toDouble(),
      high: json['high'].toDouble(),
      low: json['low'].toDouble(),
      close: json['close'].toDouble(),
      volume: json['volume'].toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}

enum IndicatorType {
  sma,
  ema,
  rsi,
  macd,
  bollingerBands,
  stochastic,
  ichimoku,
}

class TechnicalIndicator {
  final IndicatorType type;
  final int period;
  final Map<String, dynamic>? parameters;
  
  TechnicalIndicator({
    required this.type,
    required this.period,
    this.parameters,
  });
  
  List<CartesianSeries> getSeries(List<ChartData> data) {
    // Return appropriate series based on indicator type
    switch (type) {
      case IndicatorType.sma:
        return _getSMASeries(data);
      case IndicatorType.ema:
        return _getEMASeries(data);
      case IndicatorType.rsi:
        return _getRSISeries(data);
      case IndicatorType.macd:
        return _getMACDSeries(data);
      case IndicatorType.bollingerBands:
        return _getBollingerBandsSeries(data);
      default:
        return [];
    }
  }
  
  List<CartesianSeries> _getSMASeries(List<ChartData> data) {
    // Calculate and return SMA series
    return [];
  }
  
  List<CartesianSeries> _getEMASeries(List<ChartData> data) {
    // Calculate and return EMA series
    return [];
  }
  
  List<CartesianSeries> _getRSISeries(List<ChartData> data) {
    // Calculate and return RSI series
    return [];
  }
  
  List<CartesianSeries> _getMACDSeries(List<ChartData> data) {
    // Calculate and return MACD series
    return [];
  }
  
  List<CartesianSeries> _getBollingerBandsSeries(List<ChartData> data) {
    // Calculate and return Bollinger Bands series
    return [];
  }
}

enum DrawingToolType {
  trendLine,
  horizontalLine,
  verticalLine,
  fibonacci,
  rectangle,
  ellipse,
}

class DrawingTool {
  final String id;
  final DrawingToolType type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  
  DrawingTool({
    required this.id,
    required this.type,
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
  
  CartesianChartAnnotation getAnnotation() {
    // Return appropriate annotation based on drawing type
    return CartesianChartAnnotation(
      coordinateUnit: CoordinateUnit.point,
      x: points.first.dx,
      y: points.first.dy,
      widget: Container(),
    );
  }
}
