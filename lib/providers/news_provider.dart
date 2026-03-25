// lib/providers/news_provider.dart
import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _newsService = NewsService();
  List<NewsArticle> _articles = [];
  List<NewsArticle> _bookmarkedArticles = [];
  bool _isLoading = false;
  String? _error;
  
  List<NewsArticle> get articles => _articles;
  List<NewsArticle> get bookmarkedArticles => _bookmarkedArticles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  NewsProvider() {
    _newsService.initialize();
    _newsService.addListener(_onNewsUpdated);
    refreshNews();
  }
  
  void _onNewsUpdated(List<NewsArticle> articles) {
    _articles = articles;
    _loadBookmarks();
    notifyListeners();
  }
  
  Future<void> refreshNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _newsService.refreshAllNews();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<NewsArticle>> searchNews(String query, {NewsType? type}) async {
    try {
      return await _newsService.searchNews(query, type: type);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
  
  Future<List<NewsArticle>> getNewsForSymbol(String symbol) async {
    try {
      return await _newsService.getNewsForSymbol(symbol);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
  
  void markAsRead(String articleId) {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(isRead: true);
      notifyListeners();
    }
  }
  
  void toggleBookmark(String articleId) {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = _articles[index];
      final newBookmark = !article.isBookmarked;
      _articles[index] = article.copyWith(isBookmarked: newBookmark);
      
      if (newBookmark) {
        _bookmarkedArticles.add(_articles[index]);
      } else {
        _bookmarkedArticles.removeWhere((a) => a.id == articleId);
      }
      
      _saveBookmarks();
      notifyListeners();
    }
  }
  
  void _loadBookmarks() {
    // Load from shared preferences
    _bookmarkedArticles = _articles.where((a) => a.isBookmarked).toList();
  }
  
  void _saveBookmarks() {
    // Save to shared preferences
  }
  
  void clearAll() {
    _articles.clear();
    _bookmarkedArticles.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _newsService.removeListener(_onNewsUpdated);
    _newsService.dispose();
    super.dispose();
  }
}
