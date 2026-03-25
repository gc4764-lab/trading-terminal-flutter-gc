import 'package:flutter/material.dart';
import '../services/multi_window_service.dart';

class MultiWindowProvider extends ChangeNotifier {
  List<String> _windows = [];
  String? _activeWindowId;
  
  List<String> get windows => _windows;
  String? get activeWindowId => _activeWindowId;
  
  MultiWindowProvider() {
    initialize();
  }
  
  void initialize() async {
    if (await windowManager.isMultiWindowSupported()) {
      MultiWindowService.setupMessageListener(_handleMessage);
      await _loadWindows();
    }
  }
  
  Future<void> _loadWindows() async {
    final windows = await MultiWindowService.getAllWindows();
    _windows = windows.map((w) => w.windowId).toList();
    notifyListeners();
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    // Handle messages between windows
    debugPrint('Received message: $message');
    notifyListeners();
  }
  
  Future<void> openNewWindow(String title) async {
    await MultiWindowService.createNewWindow(title);
    await _loadWindows();
  }
  
  Future<void> closeWindow(String windowId) async {
    await MultiWindowService.closeWindow(windowId);
    await _loadWindows();
  }
  
  Future<void> sendDataToWindow(String windowId, Map<String, dynamic> data) async {
    await MultiWindowService.sendMessageToWindow(windowId, data);
  }
}
