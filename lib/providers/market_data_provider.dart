import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/symbol.dart';
import '../services/data_service.dart';

class MarketDataProvider extends ChangeNotifier {
  Map<String, Symbol> _symbols = {};
  Map<String, WebSocketChannel> _channels = {};
  bool _isConnected = false;
  
  Map<String, Symbol> get symbols => _symbols;
  bool get isConnected => _isConnected;

  MarketDataProvider() {
    initializeWebSocket();
  }

  void initializeWebSocket() {
    try {
      // Connect to WebSocket for real-time data
      final channel = IOWebSocketChannel.connect(
        'wss://stream.tradingdata.com/market',
      );
      
      channel.stream.listen(
        (data) {
          updateMarketData(data);
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
      );
      
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _isConnected = false;
    }
  }

  void updateMarketData(dynamic data) {
    // Parse and update symbol data
    // This is a simplified version - implement based on your data source
    
    final symbolData = data as Map<String, dynamic>;
    final symbol = symbolData['symbol'];
    
    if (_symbols.containsKey(symbol)) {
      _symbols[symbol]!.lastPrice = symbolData['price']?.toDouble() ?? 0.0;
      _symbols[symbol]!.change = symbolData['change']?.toDouble() ?? 0.0;
      _symbols[symbol]!.changePercent = symbolData['changePercent']?.toDouble() ?? 0.0;
      _symbols[symbol]!.lastUpdate = DateTime.now();
      
      notifyListeners();
    }
  }

  void subscribeSymbol(String symbol) {
    if (_channels.containsKey(symbol)) return;
    
    // Send subscription message
    final channel = IOWebSocketChannel.connect(
      'wss://stream.tradingdata.com/market/$symbol',
    );
    
    _channels[symbol] = channel;
    
    channel.stream.listen(
      (data) {
        updateSymbolData(symbol, data);
      },
    );
  }

  void unsubscribeSymbol(String symbol) {
    if (_channels.containsKey(symbol)) {
      _channels[symbol]!.sink.close();
      _channels.remove(symbol);
    }
  }

  void updateSymbolData(String symbol, dynamic data) {
    if (_symbols.containsKey(symbol)) {
      final priceData = data as Map<String, dynamic>;
      _symbols[symbol]!.lastPrice = priceData['price']?.toDouble() ?? 0.0;
      _symbols[symbol]!.bid = priceData['bid']?.toDouble() ?? 0.0;
      _symbols[symbol]!.ask = priceData['ask']?.toDouble() ?? 0.0;
      _symbols[symbol]!.volume = priceData['volume']?.toDouble() ?? 0.0;
      _symbols[symbol]!.lastUpdate = DateTime.now();
      
      notifyListeners();
    }
  }

  void addSymbol(Symbol symbol) {
    _symbols[symbol.symbol] = symbol;
    subscribeSymbol(symbol.symbol);
    notifyListeners();
  }

  void removeSymbol(String symbol) {
    _symbols.remove(symbol);
    unsubscribeSymbol(symbol);
    notifyListeners();
  }

  Symbol? getSymbol(String symbol) {
    return _symbols[symbol];
  }

  @override
  void dispose() {
    for (var channel in _channels.values) {
      channel.sink.close();
    }
    super.dispose();
  }
}
