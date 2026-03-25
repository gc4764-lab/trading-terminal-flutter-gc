import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey[900],
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black87,
      elevation: 1,
    ),
    cardTheme: CardTheme(
      color: Colors.grey[900],
      elevation: 2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
  
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      foregroundColor: Colors.black,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
    ),
  );
}

class AppColors {
  static const Color bullish = Colors.green;
  static const Color bearish = Colors.red;
  static const Color neutral = Colors.grey;
  static const Color chartGrid = Color(0xFF2C2C2C);
  static const Color chartBackground = Color(0xFF1E1E1E);
}

class ApiEndpoints {
  static const String marketData = 'wss://stream.tradingdata.com/market';
  static const String historicalData = 'https://api.tradingdata.com/history';
  static const String brokerApi = 'https://api.broker.com/v1';
}
