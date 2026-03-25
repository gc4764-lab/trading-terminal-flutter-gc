// lib/models/user_account.dart
import 'package:hive/hive.dart';

part 'user_account.g.dart';

@HiveType(typeId: 10)
class UserAccount {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String username;
  
  @HiveField(2)
  final String email;
  
  @HiveField(3)
  final String? displayName;
  
  @HiveField(4)
  final String? avatarUrl;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime lastLogin;
  
  @HiveField(7)
  final List<String> connectedBrokers;
  
  @HiveField(8)
  final Map<String, dynamic> settings;
  
  UserAccount({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLogin,
    this.connectedBrokers = const [],
    this.settings = const {},
  });
  
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: DateTime.parse(json['lastLogin']),
      connectedBrokers: List<String>.from(json['connectedBrokers'] ?? []),
      settings: json['settings'] ?? {},
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'connectedBrokers': connectedBrokers,
      'settings': settings,
    };
  }
  
  UserAccount copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? connectedBrokers,
    Map<String, dynamic>? settings,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      connectedBrokers: connectedBrokers ?? this.connectedBrokers,
      settings: settings ?? this.settings,
    );
  }
}
