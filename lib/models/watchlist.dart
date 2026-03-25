class Watchlist {
  final String id;
  String name;
  List<String> symbols;
  final bool isDefault;
  
  Watchlist({
    required this.id,
    required this.name,
    required this.symbols,
    required this.isDefault,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbols': symbols,
      'isDefault': isDefault,
    };
  }
  
  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'],
      name: json['name'],
      symbols: List<String>.from(json['symbols']),
      isDefault: json['isDefault'],
    );
  }
  
  Watchlist copyWith({
    String? id,
    String? name,
    List<String>? symbols,
    bool? isDefault,
  }) {
    return Watchlist(
      id: id ?? this.id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
