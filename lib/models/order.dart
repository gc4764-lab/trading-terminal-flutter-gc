import 'package:hive/hive.dart';

part 'order.g.dart';

enum OrderType { market, limit, stop, stopLimit }
enum OrderSide { buy, sell }
enum OrderStatus { pending, filled, cancelled, rejected, partiallyFilled }
enum TimeInForce { day, gtc, ioc, fok }

@HiveType(typeId: 1)
class Order {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String symbol;
  
  @HiveField(2)
  final OrderType type;
  
  @HiveField(3)
  final OrderSide side;
  
  @HiveField(4)
  final double quantity;
  
  @HiveField(5)
  double? price;
  
  @HiveField(6)
  double? stopPrice;
  
  @HiveField(7)
  final String brokerId;
  
  @HiveField(8)
  OrderStatus status;
  
  @HiveField(9)
  double filledQuantity;
  
  @HiveField(10)
  double averagePrice;
  
  @HiveField(11)
  final TimeInForce timeInForce;
  
  @HiveField(12)
  final DateTime createdAt;
  
  @HiveField(13)
  DateTime? updatedAt;
  
  @HiveField(14)
  String? notes;

  Order({
    required this.id,
    required this.symbol,
    required this.type,
    required this.side,
    required this.quantity,
    this.price,
    this.stopPrice,
    required this.brokerId,
    this.status = OrderStatus.pending,
    this.filledQuantity = 0.0,
    this.averagePrice = 0.0,
    this.timeInForce = TimeInForce.day,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  double get remainingQuantity => quantity - filledQuantity;
  
  bool get isFilled => status == OrderStatus.filled;
  
  bool get isActive => status == OrderStatus.pending || status == OrderStatus.partiallyFilled;
  
  String get sideText => side == OrderSide.buy ? 'BUY' : 'SELL';
  
  Color get sideColor => side == OrderSide.buy ? Colors.green : Colors.red;
}
