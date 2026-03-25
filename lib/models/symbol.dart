import 'package:hive/hive.dart';

part 'symbol.g.dart';

@HiveType(typeId: 0)
class Symbol {
  @HiveField(0)
  final String symbol;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String exchange;
  
  @HiveField(3)
  final String type; // stock, forex, crypto, futures
  
  @HiveField(4)
  double lastPrice;
  
  @HiveField(5)
  double change;
  
  @HiveField(6)
  double changePercent;
  
  @HiveField(7)
  double high;
  
  @HiveField(8)
  double low;
  
  @HiveField(9)
  double volume;
  
  @HiveField(10)
  double bid;
  
  @HiveField(11)
  double ask;
  
  @HiveField(12)
  DateTime lastUpdate;

  Symbol({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
    this.lastPrice = 0.0,
    this.change = 0.0,
    this.changePercent = 0.0,
    this.high = 0.0,
    this.low = 0.0,
    this.volume = 0.0,
    this.bid = 0.0,
    this.ask = 0.0,
    required this.lastUpdate,
  });

  factory Symbol.fromJson(Map<String, dynamic> json) {
    return Symbol(
      symbol: json['symbol'],
      name: json['name'],
      exchange: json['exchange'],
      type: json['type'],
      lastPrice: json['lastPrice']?.toDouble() ?? 0.0,
      change: json['change']?.toDouble() ?? 0.0,
      changePercent: json['changePercent']?.toDouble() ?? 0.0,
      high: json['high']?.toDouble() ?? 0.0,
      low: json['low']?.toDouble() ?? 0.0,
      volume: json['volume']?.toDouble() ?? 0.0,
      bid: json['bid']?.toDouble() ?? 0.0,
      ask: json['ask']?.toDouble() ?? 0.0,
      lastUpdate: DateTime.parse(json['lastUpdate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'type': type,
      'lastPrice': lastPrice,
      'change': change,
      'changePercent': changePercent,
      'high': high,
      'low': low,
      'volume': volume,
      'bid': bid,
      'ask': ask,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  Color get priceColor => change >= 0 ? Colors.green : Colors.red;
  
  String get formattedChange => '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}';
  
  String get formattedChangePercent => '${change >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}
