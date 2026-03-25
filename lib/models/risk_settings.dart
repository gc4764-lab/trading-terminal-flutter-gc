class RiskSettings {
  final double maxPositionSizePercent;
  final double maxRiskPerTradePercent;
  final double maxDailyLossPercent;
  final double defaultStopLossPercent;
  final double defaultTakeProfitPercent;
  final bool trailingStopEnabled;
  final double trailingStopDistance;
  final bool restrictTradingHours;
  final TimeOfDay tradingStartTime;
  final TimeOfDay tradingEndTime;
  final List<String> restrictedSymbols;
  final List<String> allowedSymbols;
  final double? maxOrderValue;
  final double? maxOrderQuantity;
  final double maxLeverage;
  final int maxOpenPositions;
  
  RiskSettings({
    required this.maxPositionSizePercent,
    required this.maxRiskPerTradePercent,
    required this.maxDailyLossPercent,
    required this.defaultStopLossPercent,
    required this.defaultTakeProfitPercent,
    required this.trailingStopEnabled,
    required this.trailingStopDistance,
    required this.restrictTradingHours,
    required this.tradingStartTime,
    required this.tradingEndTime,
    required this.restrictedSymbols,
    required this.allowedSymbols,
    this.maxOrderValue,
    this.maxOrderQuantity,
    required this.maxLeverage,
    required this.maxOpenPositions,
  });
  
  factory RiskSettings.defaultSettings() {
    return RiskSettings(
      maxPositionSizePercent: 20,
      maxRiskPerTradePercent: 2,
      maxDailyLossPercent: 5,
      defaultStopLossPercent: 2,
      defaultTakeProfitPercent: 5,
      trailingStopEnabled: false,
      trailingStopDistance: 1,
      restrictTradingHours: false,
      tradingStartTime: const TimeOfDay(hour: 9, minute: 30),
      tradingEndTime: const TimeOfDay(hour: 16, minute: 0),
      restrictedSymbols: [],
      allowedSymbols: [],
      maxOrderValue: null,
      maxOrderQuantity: null,
      maxLeverage: 10,
      maxOpenPositions: 20,
    );
  }
  
  RiskSettings copyWith({
    double? maxPositionSizePercent,
    double? maxRiskPerTradePercent,
    double? maxDailyLossPercent,
    double? defaultStopLossPercent,
    double? defaultTakeProfitPercent,
    bool? trailingStopEnabled,
    double? trailingStopDistance,
    bool? restrictTradingHours,
    TimeOfDay? tradingStartTime,
    TimeOfDay? tradingEndTime,
    List<String>? restrictedSymbols,
    List<String>? allowedSymbols,
    double? maxOrderValue,
    double? maxOrderQuantity,
    double? maxLeverage,
    int? maxOpenPositions,
  }) {
    return RiskSettings(
      maxPositionSizePercent: maxPositionSizePercent ?? this.maxPositionSizePercent,
      maxRiskPerTradePercent: maxRiskPerTradePercent ?? this.maxRiskPerTradePercent,
      maxDailyLossPercent: maxDailyLossPercent ?? this.maxDailyLossPercent,
      defaultStopLossPercent: defaultStopLossPercent ?? this.defaultStopLossPercent,
      defaultTakeProfitPercent: defaultTakeProfitPercent ?? this.defaultTakeProfitPercent,
      trailingStopEnabled: trailingStopEnabled ?? this.trailingStopEnabled,
      trailingStopDistance: trailingStopDistance ?? this.trailingStopDistance,
      restrictTradingHours: restrictTradingHours ?? this.restrictTradingHours,
      tradingStartTime: tradingStartTime ?? this.tradingStartTime,
      tradingEndTime: tradingEndTime ?? this.tradingEndTime,
      restrictedSymbols: restrictedSymbols ?? this.restrictedSymbols,
      allowedSymbols: allowedSymbols ?? this.allowedSymbols,
      maxOrderValue: maxOrderValue ?? this.maxOrderValue,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      maxLeverage: maxLeverage ?? this.maxLeverage,
      maxOpenPositions: maxOpenPositions ?? this.maxOpenPositions,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'maxPositionSizePercent': maxPositionSizePercent,
      'maxRiskPerTradePercent': maxRiskPerTradePercent,
      'maxDailyLossPercent': maxDailyLossPercent,
      'defaultStopLossPercent': defaultStopLossPercent,
      'defaultTakeProfitPercent': defaultTakeProfitPercent,
      'trailingStopEnabled': trailingStopEnabled,
      'trailingStopDistance': trailingStopDistance,
      'restrictTradingHours': restrictTradingHours,
      'tradingStartHour': tradingStartTime.hour,
      'tradingStartMinute': tradingStartTime.minute,
      'tradingEndHour': tradingEndTime.hour,
      'tradingEndMinute': tradingEndTime.minute,
      'restrictedSymbols': restrictedSymbols,
      'allowedSymbols': allowedSymbols,
      'maxOrderValue': maxOrderValue,
      'maxOrderQuantity': maxOrderQuantity,
      'maxLeverage': maxLeverage,
      'maxOpenPositions': maxOpenPositions,
    };
  }
  
  factory RiskSettings.fromJson(Map<String, dynamic> json) {
    return RiskSettings(
      maxPositionSizePercent: json['maxPositionSizePercent'],
      maxRiskPerTradePercent: json['maxRiskPerTradePercent'],
      maxDailyLossPercent: json['maxDailyLossPercent'],
      defaultStopLossPercent: json['defaultStopLossPercent'],
      defaultTakeProfitPercent: json['defaultTakeProfitPercent'],
      trailingStopEnabled: json['trailingStopEnabled'],
      trailingStopDistance: json['trailingStopDistance'],
      restrictTradingHours: json['restrictTradingHours'],
      tradingStartTime: TimeOfDay(
        hour: json['tradingStartHour'],
        minute: json['tradingStartMinute'],
      ),
      tradingEndTime: TimeOfDay(
        hour: json['tradingEndHour'],
        minute: json['tradingEndMinute'],
      ),
      restrictedSymbols: List<String>.from(json['restrictedSymbols']),
      allowedSymbols: List<String>.from(json['allowedSymbols']),
      maxOrderValue: json['maxOrderValue'],
      maxOrderQuantity: json['maxOrderQuantity'],
      maxLeverage: json['maxLeverage'],
      maxOpenPositions: json['maxOpenPositions'],
    );
  }
}
