// lib/models/social_trader.dart
import 'package:hive/hive.dart';

part 'social_trader.g.dart';

@HiveType(typeId: 8)
class SocialTrader {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String displayName;
  
  @HiveField(3)
  final String? avatarUrl;
  
  @HiveField(4)
  final double totalPnL;
  
  @HiveField(5)
  final double winRate;
  
  @HiveField(6)
  final int totalTrades;
  
  @HiveField(7)
  final double averageReturn;
  
  @HiveField(8)
  final List<String> followers;
  
  @HiveField(9)
  final List<String> following;
  
  @HiveField(10)
  final List<TradeCopy> trades;
  
  @HiveField(11)
  final DateTime joinedAt;
  
  SocialTrader({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.totalPnL,
    required this.winRate,
    required this.totalTrades,
    required this.averageReturn,
    this.followers = const [],
    this.following = const [],
    this.trades = const [],
    required this.joinedAt,
  });
  
  double get riskScore => (1 - winRate / 100) * (totalTrades / 100).clamp(0, 1);
  
  String get performanceGrade {
    if (totalPnL > 100000 && winRate > 60) return 'A+';
    if (totalPnL > 50000 && winRate > 55) return 'A';
    if (totalPnL > 10000 && winRate > 50) return 'B';
    if (totalPnL > 0) return 'C';
    return 'D';
  }
}

@HiveType(typeId: 9)
class TradeCopy {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String traderId;
  
  @HiveField(2)
  final String symbol;
  
  @HiveField(3)
  final OrderSide side;
  
  @HiveField(4)
  final double entryPrice;
  
  @HiveField(5)
  final double? exitPrice;
  
  @HiveField(6)
  final double quantity;
  
  @HiveField(7)
  final DateTime entryTime;
  
  @HiveField(8)
  final DateTime? exitTime;
  
  @HiveField(9)
  final double? pnl;
  
  @HiveField(10)
  final double? pnlPercent;
  
  TradeCopy({
    required this.id,
    required this.traderId,
    required this.symbol,
    required this.side,
    required this.entryPrice,
    this.exitPrice,
    required this.quantity,
    required this.entryTime,
    this.exitTime,
    this.pnl,
    this.pnlPercent,
  });
  
  bool get isOpen => exitPrice == null;
  
  double get currentPnL {
    // This would be calculated from current market price
    return 0;
  }
}
