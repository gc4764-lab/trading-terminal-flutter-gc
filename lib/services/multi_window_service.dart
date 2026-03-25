import 'package:flutter/material.dart';
import 'package:multi_window/multi_window.dart';
import 'package:window_manager/window_manager.dart';

class MultiWindowService {
  static const String channelName = 'trading-terminal';
  
  static Future<void> createNewWindow(String title) async {
    if (!await windowManager.isMultiWindowSupported()) {
      debugPrint('Multi-window not supported on this platform');
      return;
    }
    
    final newWindow = await MultiWindow.create(
      title: title,
      width: 1200,
      height: 800,
    );
    
    newWindow
      ..setTitle(title)
      ..show();
  }
  
  static Future<void> sendMessageToWindow(
    String windowId,
    Map<String, dynamic> message,
  ) async {
    final window = MultiWindowController(windowId);
    await window.sendMessage(channelName, message);
  }
  
  static void setupMessageListener(Function(Map<String, dynamic>) onMessage) {
    MultiWindow.setMethodCallHandler((call) async {
      if (call.method == channelName) {
        onMessage(call.arguments as Map<String, dynamic>);
      }
      return null;
    });
  }
  
  static Future<void> closeWindow(String windowId) async {
    final window = MultiWindowController(windowId);
    await window.close();
  }
  
  static Future<List<MultiWindowInfo>> getAllWindows() async {
    return await MultiWindow.getAll();
  }
}

// Platform detection helper
class PlatformUtils {
  static bool get isDesktop => 
      !isMobile && !isTablet;
      
  static bool get isMobile => 
      isIOS || isAndroid;
      
  static bool get isIOS => 
      Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.iOS;
      
  static bool get isAndroid => 
      Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.android;
      
  static bool get isTablet => 
      isIOS && MediaQuery.of(WidgetsBinding.instance.rootElement!).size.shortestSide >= 768;
}
