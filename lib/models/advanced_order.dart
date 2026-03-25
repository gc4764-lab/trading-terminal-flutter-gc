// lib/models/advanced_order.dart
import 'package:hive/hive.dart';
import 'order.dart';

part 'advanced_order.g.dart';

enum AdvancedOrderType {
  bracket,
  trailingStop,
  oco, // One Cancels Other
  iceBerg,
  timeWeighted,
  volumeWeighted,
}

@HiveType(typeId: 3)
class BracketOrder {
  @HiveField(0)
  final Order entryOrder;
  
  @HiveField(1)
  final Order? stopLoss;
  
  @HiveField(2)
  final Order? takeProfit;
  
  @HiveField(3)
  final double? trailingDistance;
  
  BracketOrder({
    required this.entryOrder,
    this.stopLoss,
    this.takeProfit,
    this.trailingDistance,
  });
  
  bool get hasTrailingStop => trailingDistance != null;
  
  void updateTrailingStop(double currentPrice) {
    if (hasTrailingStop && stopLoss != null) {
      final newStopPrice = currentPrice - (entryOrder.side == OrderSide.buy 
          ? trailingDistance! 
          : -trailingDistance!);
      
      if ((entryOrder.side == OrderSide.buy && newStopPrice > stopLoss!.price!) ||
          (entryOrder.side == OrderSide.sell && newStopPrice < stopLoss!.price!)) {
        stopLoss!.price = newStopPrice;
      }
    }
  }
}

@HiveType(typeId: 4)
class OCOOrder {
  @HiveField(0)
  final Order order1;
  
  @HiveField(1)
  final Order order2;
  
  @HiveField(2)
  bool isExecuted = false;
  
  OCOOrder({
    required this.order1,
    required this.order2,
  });
  
  void execute(String orderId) {
    if (!isExecuted) {
      isExecuted = true;
      // Cancel the other order
    }
  }
}

@HiveType(typeId: 5)
class IcebergOrder {
  @HiveField(0)
  final Order parentOrder;
  
  @HiveField(1)
  final double visibleQuantity;
  
  @HiveField(2)
  final double totalQuantity;
  
  @HiveField(3)
  final int numPieces;
  
  @HiveField(4)
  final List<Order> childOrders;
  
  IcebergOrder({
    required this.parentOrder,
    required this.visibleQuantity,
    required this.totalQuantity,
    required this.numPieces,
    required this.childOrders,
  });
  
  double get remainingQuantity => totalQuantity - 
      childOrders.fold(0.0, (sum, order) => sum + order.filledQuantity);
  
  bool get isComplete => remainingQuantity <= 0;
}

@HiveType(typeId: 6)
class TWAPOrder {
  @HiveField(0)
  final Order order;
  
  @HiveField(1)
  final DateTime startTime;
  
  @HiveField(2)
  final DateTime endTime;
  
  @HiveField(3)
  final List<Order> slices;
  
  TWAPOrder({
    required this.order,
    required this.startTime,
    required this.endTime,
    required this.slices,
  });
  
  Duration get duration => endTime.difference(startTime);
  
  int get totalSlices => slices.length;
  
  double get sliceQuantity => order.quantity / totalSlices;
}

class AdvancedOrderManager {
  final Map<String, BracketOrder> _bracketOrders = {};
  final Map<String, OCOOrder> _ocoOrders = {};
  final Map<String, IcebergOrder> _icebergOrders = {};
  final Map<String, TWAPOrder> _twapOrders = {};
  
  void addBracketOrder(BracketOrder bracketOrder) {
    _bracketOrders[bracketOrder.entryOrder.id] = bracketOrder;
  }
  
  void addOCOOrder(OCOOrder ocoOrder) {
    _ocoOrders[ocoOrder.order1.id] = ocoOrder;
    _ocoOrders[ocoOrder.order2.id] = ocoOrder;
  }
  
  void addIcebergOrder(IcebergOrder icebergOrder) {
    _icebergOrders[icebergOrder.parentOrder.id] = icebergOrder;
  }
  
  void addTWAPOrder(TWAPOrder twapOrder) {
    _twapOrders[twapOrder.order.id] = twapOrder;
  }
  
  void updateTrailingStops(double currentPrice) {
    for (var bracket in _bracketOrders.values) {
      if (bracket.hasTrailingStop) {
        bracket.updateTrailingStop(currentPrice);
      }
    }
  }
  
  void processIcebergOrders() {
    for (var iceberg in _icebergOrders.values) {
      if (!iceberg.isComplete) {
        // Send next child order
      }
    }
  }
  
  void processTWAPOrders(DateTime currentTime) {
    for (var twap in _twapOrders.values) {
      if (currentTime.isAfter(twap.startTime) && 
          currentTime.isBefore(twap.endTime)) {
        // Calculate and send next slice
      }
    }
  }
}
