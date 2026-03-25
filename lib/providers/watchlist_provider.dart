import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/symbol.dart';
import '../models/watchlist.dart';

class WatchlistProvider extends ChangeNotifier {
  List<Watchlist> _watchlists = [];
  int _activeWatchlistIndex = 0;
  
  List<Watchlist> get watchlists => _watchlists;
  Watchlist get activeWatchlist => _watchlists[_activeWatchlistIndex];
  int get activeWatchlistIndex => _activeWatchlistIndex;

  WatchlistProvider() {
    loadWatchlists();
  }

  Future<void> loadWatchlists() async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistsJson = prefs.getStringList('watchlists');
    
    if (watchlistsJson != null) {
      _watchlists = watchlistsJson
          .map((json) => Watchlist.fromJson(jsonDecode(json)))
          .toList();
    } else {
      // Create default watchlist
      _watchlists = [
        Watchlist(
          id: 'default',
          name: 'My Watchlist',
          symbols: [],
          isDefault: true,
        ),
      ];
    }
    
    notifyListeners();
  }

  Future<void> saveWatchlists() async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistsJson = _watchlists
        .map((watchlist) => jsonEncode(watchlist.toJson()))
        .toList();
    await prefs.setStringList('watchlists', watchlistsJson);
  }

  void addWatchlist(String name) {
    final watchlist = Watchlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      symbols: [],
      isDefault: false,
    );
    
    _watchlists.add(watchlist);
    saveWatchlists();
    notifyListeners();
  }

  void removeWatchlist(String id) {
    _watchlists.removeWhere((w) => w.id == id);
    if (_activeWatchlistIndex >= _watchlists.length) {
      _activeWatchlistIndex = _watchlists.length - 1;
    }
    saveWatchlists();
    notifyListeners();
  }

  void setActiveWatchlist(int index) {
    _activeWatchlistIndex = index;
    notifyListeners();
  }

  void addSymbolToWatchlist(String watchlistId, Symbol symbol) {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      if (!_watchlists[index].symbols.contains(symbol.symbol)) {
        _watchlists[index].symbols.add(symbol.symbol);
        saveWatchlists();
        notifyListeners();
      }
    }
  }

  void removeSymbolFromWatchlist(String watchlistId, String symbol) {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      _watchlists[index].symbols.remove(symbol);
      saveWatchlists();
      notifyListeners();
    }
  }

  void moveSymbol(String watchlistId, int oldIndex, int newIndex) {
    final index = _watchlists.indexWhere((w) => w.id == watchlistId);
    if (index != -1) {
      final symbol = _watchlists[index].symbols.removeAt(oldIndex);
      _watchlists[index].symbols.insert(newIndex, symbol);
      saveWatchlists();
      notifyListeners();
    }
  }
}
