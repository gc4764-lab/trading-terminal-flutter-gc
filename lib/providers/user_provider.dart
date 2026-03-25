// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_account.dart';
import '../services/secure_storage_service.dart';
import '../services/broker_manager.dart';

class UserProvider extends ChangeNotifier {
  UserAccount? _currentUser;
  List<UserAccount> _accounts = [];
  bool _isLoading = false;
  final SecureStorageService _secureStorage = SecureStorageService();
  
  UserAccount? get currentUser => _currentUser;
  List<UserAccount> get accounts => _accounts;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  
  UserProvider() {
    loadCurrentUser();
  }
  
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final userJson = await _secureStorage.getToken('current_user');
      if (userJson != null) {
        _currentUser = UserAccount.fromJson(jsonDecode(userJson));
      }
      
      // Load all accounts
      final accountsJson = await _secureStorage.getToken('user_accounts');
      if (accountsJson != null) {
        final List<dynamic> list = jsonDecode(accountsJson);
        _accounts = list.map((item) => UserAccount.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real app, you would call your authentication API
      // For demo, create a mock user
      final user = UserAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        email: '$username@example.com',
        displayName: username,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      
      _currentUser = user;
      _accounts.add(user);
      
      // Save to secure storage
      await _secureStorage.saveToken('current_user', jsonEncode(user.toJson()));
      await _secureStorage.saveToken('user_accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Disconnect all brokers
      final brokerManager = BrokerManager();
      await brokerManager.disconnectAllBrokers();
      
      // Clear current user
      _currentUser = null;
      await _secureStorage.deleteToken('current_user');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> switchAccount(String userId) async {
    final user = _accounts.firstWhere((a) => a.id == userId);
    if (user != null) {
      _currentUser = user;
      await _secureStorage.saveToken('current_user', jsonEncode(user.toJson()));
      notifyListeners();
    }
  }
  
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;
    
    _currentUser = _currentUser!.copyWith(
      displayName: updates['displayName'] ?? _currentUser!.displayName,
      avatarUrl: updates['avatarUrl'] ?? _currentUser!.avatarUrl,
    );
    
    // Update in accounts list
    final index = _accounts.indexWhere((a) => a.id == _currentUser!.id);
    if (index != -1) {
      _accounts[index] = _currentUser!;
    }
    
    await _secureStorage.saveToken('current_user', jsonEncode(_currentUser!.toJson()));
    await _secureStorage.saveToken('user_accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
    
    notifyListeners();
  }
}
