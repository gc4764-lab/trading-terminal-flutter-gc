// lib/models/order_book.dart
class OrderBookLevel {
  final double price;
  final double quantity;
  final double total;
  final int orderCount;
  
  OrderBookLevel({
    required this.price,
    required this.quantity,
    required this.total,
    this.orderCount = 0,
  });
  
  factory OrderBookLevel.fromJson(Map<String, dynamic> json) {
    return OrderBookLevel(
      price: json['price'].toDouble(),
      quantity: json['quantity'].toDouble(),
      total: json['total'].toDouble(),
      orderCount: json['orderCount'] ?? 0,
    );
  }
}

class OrderBookData {
  final String symbol;
  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;
  final DateTime timestamp;
  
  OrderBookData({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.timestamp,
  });
  
  double get bidPrice => bids.isNotEmpty ? bids.first.price : 0;
  double get askPrice => asks.isNotEmpty ? asks.first.price : 0;
  double get midPrice => (bidPrice + askPrice) / 2;
  double get spread => askPrice - bidPrice;
  double get maxVolume {
    final maxBid = bids.map((b) => b.quantity).reduce((a, b) => a > b ? a : b);
    final maxAsk = asks.map((a) => a.quantity).reduce((a, b) => a > b ? a : b);
    return maxBid > maxAsk ? maxBid : maxAsk;
  }
  
  factory OrderBookData.fromJson(Map<String, dynamic> json) {
    return OrderBookData(
      symbol: json['symbol'],
      bids: (json['bids'] as List)
          .map((b) => OrderBookLevel.fromJson(b))
          .toList(),
      asks: (json['asks'] as List)
          .map((a) => OrderBookLevel.fromJson(a))
          .toList(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
