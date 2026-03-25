import 'package:hive/hive.dart';

part 'alert.g.dart';

enum AlertCondition { above, below, crossesAbove, crossesBelow }
enum AlertAction { notification, order, both }

@HiveType(typeId: 2)
class Alert {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String symbol;
  
  @HiveField(2)
  final AlertCondition condition;
  
  @HiveField(3)
  final double triggerPrice;
  
  @HiveField(4)
  AlertAction action;
  
  @HiveField(5)
  Order? associatedOrder;
  
  @HiveField(6)
  bool isActive;
  
  @HiveField(7)
  bool isTriggered;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  DateTime? triggeredAt;

  Alert({
    required this.id,
    required this.symbol,
    required this.condition,
    required this.triggerPrice,
    this.action = AlertAction.notification,
    this.associatedOrder,
    this.isActive = true,
    this.isTriggered = false,
    required this.createdAt,
    this.triggeredAt,
  });

  String get conditionText {
    switch (condition) {
      case AlertCondition.above:
        return 'Above';
      case AlertCondition.below:
        return 'Below';
      case AlertCondition.crossesAbove:
        return 'Crosses Above';
      case AlertCondition.crossesBelow:
        return 'Crosses Below';
    }
  }

  bool checkCondition(double currentPrice) {
    switch (condition) {
      case AlertCondition.above:
        return currentPrice > triggerPrice;
      case AlertCondition.below:
        return currentPrice < triggerPrice;
      case AlertCondition.crossesAbove:
        // This requires previous price for proper cross detection
        return false;
      case AlertCondition.crossesBelow:
        return false;
    }
  }
}




// lib/models/alert.dart (Updated)
import 'package:hive/hive.dart';
import 'order.dart';

part 'alert.g.dart';

enum AlertCondition { 
  above, 
  below, 
  crossesAbove, 
  crossesBelow,
  touches,
  withinRange,
}

enum AlertAction { 
  notification, 
  order, 
  both,
  soundOnly,
  email,
}

@HiveType(typeId: 2)
class Alert {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String symbol;
  
  @HiveField(2)
  final AlertCondition condition;
  
  @HiveField(3)
  final double triggerPrice;
  
  @HiveField(4)
  double? secondaryPrice; // For range conditions
  
  @HiveField(5)
  AlertAction action;
  
  @HiveField(6)
  Order? associatedOrder;
  
  @HiveField(7)
  bool isActive;
  
  @HiveField(8)
  bool isTriggered;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  DateTime? triggeredAt;
  
  @HiveField(11)
  String? notes;
  
  @HiveField(12)
  bool soundEnabled;
  
  @HiveField(13)
  bool pushNotification;
  
  @HiveField(14)
  bool recurring;
  
  @HiveField(15)
  int? cooldownMinutes;
  
  @HiveField(16)
  DateTime? expiresAt;
  
  @HiveField(17)
  int? triggerCount;
  
  @HiveField(18)
  int? maxTriggers;

  Alert({
    required this.id,
    required this.symbol,
    required this.condition,
    required this.triggerPrice,
    this.secondaryPrice,
    this.action = AlertAction.notification,
    this.associatedOrder,
    this.isActive = true,
    this.isTriggered = false,
    required this.createdAt,
    this.triggeredAt,
    this.notes,
    this.soundEnabled = true,
    this.pushNotification = true,
    this.recurring = false,
    this.cooldownMinutes,
    this.expiresAt,
    this.triggerCount,
    this.maxTriggers,
  });

  String get conditionText {
    switch (condition) {
      case AlertCondition.above:
        return 'Above';
      case AlertCondition.below:
        return 'Below';
      case AlertCondition.crossesAbove:
        return 'Crosses Above';
      case AlertCondition.crossesBelow:
        return 'Crosses Below';
      case AlertCondition.touches:
        return 'Touches';
      case AlertCondition.withinRange:
        return 'Within Range';
    }
  }
  
  String get description {
    if (condition == AlertCondition.withinRange && secondaryPrice != null) {
      return 'Price between \$${triggerPrice.toStringAsFixed(2)} and \$${secondaryPrice!.toStringAsFixed(2)}';
    }
    return 'Price $conditionText \$${triggerPrice.toStringAsFixed(2)}';
  }
  
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get canTriggerAgain {
    if (!recurring) return false;
    if (maxTriggers != null && triggerCount != null && triggerCount! >= maxTriggers!) {
      return false;
    }
    return true;
  }
  
  bool checkCondition(double currentPrice, {double? previousPrice}) {
    switch (condition) {
      case AlertCondition.above:
        return currentPrice > triggerPrice;
      case AlertCondition.below:
        return currentPrice < triggerPrice;
      case AlertCondition.crossesAbove:
        return previousPrice != null && 
               previousPrice <= triggerPrice && 
               currentPrice > triggerPrice;
      case AlertCondition.crossesBelow:
        return previousPrice != null && 
               previousPrice >= triggerPrice && 
               currentPrice < triggerPrice;
      case AlertCondition.touches:
        return (currentPrice - triggerPrice).abs() <= (triggerPrice * 0.001); // 0.1% tolerance
      case AlertCondition.withinRange:
        return secondaryPrice != null && 
               currentPrice >= triggerPrice && 
               currentPrice <= secondaryPrice!;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'condition': condition.index,
      'triggerPrice': triggerPrice,
      'secondaryPrice': secondaryPrice,
      'action': action.index,
      'associatedOrder': associatedOrder?.toJson(),
      'isActive': isActive,
      'isTriggered': isTriggered,
      'createdAt': createdAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'notes': notes,
      'soundEnabled': soundEnabled,
      'pushNotification': pushNotification,
      'recurring': recurring,
      'cooldownMinutes': cooldownMinutes,
      'expiresAt': expiresAt?.toIso8601String(),
      'triggerCount': triggerCount,
      'maxTriggers': maxTriggers,
    };
  }
  
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      symbol: json['symbol'],
      condition: AlertCondition.values[json['condition']],
      triggerPrice: json['triggerPrice'],
      secondaryPrice: json['secondaryPrice'],
      action: AlertAction.values[json['action']],
      associatedOrder: json['associatedOrder'] != null 
          ? Order.fromJson(json['associatedOrder']) 
          : null,
      isActive: json['isActive'],
      isTriggered: json['isTriggered'],
      createdAt: DateTime.parse(json['createdAt']),
      triggeredAt: json['triggeredAt'] != null 
          ? DateTime.parse(json['triggeredAt']) 
          : null,
      notes: json['notes'],
      soundEnabled: json['soundEnabled'] ?? true,
      pushNotification: json['pushNotification'] ?? true,
      recurring: json['recurring'] ?? false,
      cooldownMinutes: json['cooldownMinutes'],
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      triggerCount: json['triggerCount'],
      maxTriggers: json['maxTriggers'],
    );
  }
  
  Alert copyWith({
    String? id,
    String? symbol,
    AlertCondition? condition,
    double? triggerPrice,
    double? secondaryPrice,
    AlertAction? action,
    Order? associatedOrder,
    bool? isActive,
    bool? isTriggered,
    DateTime? createdAt,
    DateTime? triggeredAt,
    String? notes,
    bool? soundEnabled,
    bool? pushNotification,
    bool? recurring,
    int? cooldownMinutes,
    DateTime? expiresAt,
    int? triggerCount,
    int? maxTriggers,
  }) {
    return Alert(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      condition: condition ?? this.condition,
      triggerPrice: triggerPrice ?? this.triggerPrice,
      secondaryPrice: secondaryPrice ?? this.secondaryPrice,
      action: action ?? this.action,
      associatedOrder: associatedOrder ?? this.associatedOrder,
      isActive: isActive ?? this.isActive,
      isTriggered: isTriggered ?? this.isTriggered,
      createdAt: createdAt ?? this.createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      notes: notes ?? this.notes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pushNotification: pushNotification ?? this.pushNotification,
      recurring: recurring ?? this.recurring,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
      expiresAt: expiresAt ?? this.expiresAt,
      triggerCount: triggerCount ?? this.triggerCount,
      maxTriggers: maxTriggers ?? this.maxTriggers,
    );
  }
}


