// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  // Broker credentials
  static const String _brokerPrefix = 'broker_';
  
  Future<void> saveBrokerCredentials(String brokerId, Map<String, String> credentials) async {
    for (var entry in credentials.entries) {
      await _storage.write(
        key: '${_brokerPrefix}${brokerId}_${entry.key}',
        value: entry.value,
      );
    }
    await _storage.write(
      key: '${_brokerPrefix}${brokerId}_connected',
      value: 'true',
    );
  }
  
  Future<Map<String, String>> getBrokerCredentials(String brokerId) async {
    final keys = await _storage.readAll();
    final result = <String, String>{};
    final prefix = '${_brokerPrefix}${brokerId}_';
    for (var entry in keys.entries) {
      if (entry.key.startsWith(prefix) && entry.key != '${_brokerPrefix}${brokerId}_connected') {
        final key = entry.key.substring(prefix.length);
        result[key] = entry.value;
      }
    }
    return result;
  }
  
  Future<bool> isBrokerConnected(String brokerId) async {
    final value = await _storage.read(key: '${_brokerPrefix}${brokerId}_connected');
    return value == 'true';
  }
  
  Future<void> removeBrokerCredentials(String brokerId) async {
    final keys = await _storage.readAll();
    final prefix = '${_brokerPrefix}${brokerId}_';
    for (var key in keys.keys) {
      if (key.startsWith(prefix)) {
        await _storage.delete(key: key);
      }
    }
  }
  
  // General token storage
  Future<void> saveToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> getToken(String key) async {
    return await _storage.read(key: key);
  }
  
  Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }
  
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
