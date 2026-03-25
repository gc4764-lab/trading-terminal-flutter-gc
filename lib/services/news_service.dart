// lib/services/news_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_article.dart';

class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();
  
  final Map<String, List<NewsSource>> _sources = {};
  Timer? _refreshTimer;
  final List<NewsArticle> _articles = [];
  final List<Function(List<NewsArticle>)> _listeners = [];
  
  void initialize() {
    _initializeSources();
    _startAutoRefresh();
  }
  
  void _initializeSources() {
    // Stock News Sources
    _sources['stocks'] = [
      NewsSource(
        id: 'yahoo_finance_rss',
        name: 'Yahoo Finance',
        url: 'https://finance.yahoo.com/news/rssindex',
        type: NewsType.stocks,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'marketwatch_rss',
        name: 'MarketWatch',
        url: 'https://www.marketwatch.com/rss/marketwatch',
        type: NewsType.stocks,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'seeking_alpha_rss',
        name: 'Seeking Alpha',
        url: 'https://seekingalpha.com/feed.xml',
        type: NewsType.stocks,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'finviz_news',
        name: 'Finviz News',
        url: 'https://finviz.com/news.ashx',
        type: NewsType.stocks,
        format: NewsFormat.html,
      ),
      NewsSource(
        id: 'investing_com',
        name: 'Investing.com',
        url: 'https://www.investing.com/rss/news.rss',
        type: NewsType.stocks,
        format: NewsFormat.rss,
      ),
    ];
    
    // Crypto News Sources
    _sources['crypto'] = [
      NewsSource(
        id: 'coindesk_rss',
        name: 'CoinDesk',
        url: 'https://www.coindesk.com/feed/',
        type: NewsType.crypto,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'cointelegraph_rss',
        name: 'CoinTelegraph',
        url: 'https://cointelegraph.com/rss',
        type: NewsType.crypto,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'crypto_panic',
        name: 'CryptoPanic',
        url: 'https://cryptopanic.com/api/v1/posts/?auth_token=YOUR_TOKEN',
        type: NewsType.crypto,
        format: NewsFormat.json,
      ),
      NewsSource(
        id: 'cryptoslate',
        name: 'CryptoSlate',
        url: 'https://cryptoslate.com/feed/',
        type: NewsType.crypto,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'bitcoin_news',
        name: 'Bitcoin News',
        url: 'https://news.bitcoin.com/feed/',
        type: NewsType.crypto,
        format: NewsFormat.rss,
      ),
    ];
    
    // Forex News Sources
    _sources['forex'] = [
      NewsSource(
        id: 'forex_factory',
        name: 'Forex Factory',
        url: 'https://www.forexfactory.com/feed.php',
        type: NewsType.forex,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'dailyfx_news',
        name: 'DailyFX',
        url: 'https://www.dailyfx.com/feeds/news',
        type: NewsType.forex,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'fxstreet_news',
        name: 'FXStreet',
        url: 'https://www.fxstreet.com/feed/news',
        type: NewsType.forex,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'forex_live',
        name: 'ForexLive',
        url: 'https://www.forexlive.com/feed/news',
        type: NewsType.forex,
        format: NewsFormat.rss,
      ),
      NewsSource(
        id: 'bloomberg_forex',
        name: 'Bloomberg Forex',
        url: 'https://www.bloomberg.com/markets/currencies',
        type: NewsType.forex,
        format: NewsFormat.html,
      ),
    ];
  }
  
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      refreshAllNews();
    });
  }
  
  Future<void> refreshAllNews() async {
    final allArticles = <NewsArticle>[];
    
    for (var type in _sources.keys) {
      final articles = await fetchNewsByType(type);
      allArticles.addAll(articles);
    }
    
    // Sort by date
    allArticles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    // Update articles
    _articles.clear();
    _articles.addAll(allArticles);
    
    // Notify listeners
    for (var listener in _listeners) {
      listener(_articles);
    }
  }
  
  Future<List<NewsArticle>> fetchNewsByType(String type) async {
    final sources = _sources[type] ?? [];
    final allArticles = <NewsArticle>[];
    
    for (var source in sources) {
      try {
        final articles = await _fetchFromSource(source);
        allArticles.addAll(articles);
      } catch (e) {
        print('Error fetching from ${source.name}: $e');
      }
    }
    
    return allArticles;
  }
  
  Future<List<NewsArticle>> _fetchFromSource(NewsSource source) async {
    try {
      final response = await http.get(Uri.parse(source.url));
      
      if (response.statusCode == 200) {
        switch (source.format) {
          case NewsFormat.rss:
            return _parseRSS(response.body, source);
          case NewsFormat.json:
            return _parseJSON(response.body, source);
          case NewsFormat.html:
            return _parseHTML(response.body, source);
        }
      }
    } catch (e) {
      print('Error: $e');
    }
    
    return [];
  }
  
  List<NewsArticle> _parseRSS(String xmlString, NewsSource source) {
    final articles = <NewsArticle>[];
    final document = XmlDocument.parse(xmlString);
    
    final items = document.findAllElements('item');
    
    for (var item in items) {
      try {
        final title = item.findElements('title').first.text;
        final link = item.findElements('link').first.text;
        final description = item.findElements('description').first.text;
        final pubDate = item.findElements('pubDate').first.text;
        final guid = item.findElements('guid').first.text;
        
        articles.add(NewsArticle(
          id: guid,
          title: title,
          description: _cleanHtml(description),
          url: link,
          source: source.name,
          type: source.type,
          publishedAt: DateTime.parse(pubDate),
          sentiment: _analyzeSentiment(title + ' ' + description),
        ));
      } catch (e) {
        // Skip malformed items
      }
    }
    
    return articles;
  }
  
  List<NewsArticle> _parseJSON(String jsonString, NewsSource source) {
    final articles = <NewsArticle>[];
    final data = jsonDecode(jsonString);
    
    // CryptoPanic API format
    if (source.id == 'crypto_panic') {
      final results = data['results'] as List;
      for (var item in results) {
        articles.add(NewsArticle(
          id: item['id'].toString(),
          title: item['title'],
          description: item['body'] ?? '',
          url: item['url'],
          source: source.name,
          type: source.type,
          publishedAt: DateTime.parse(item['created_at']),
          sentiment: _analyzeSentiment(item['title']),
          currencies: _extractCurrencies(item['currencies'] ?? []),
        ));
      }
    }
    
    return articles;
  }
  
  List<NewsArticle> _parseHTML(String htmlString, NewsSource source) {
    // Basic HTML parsing - for production, use a proper HTML parser
    final articles = <NewsArticle>[];
    // Simplified parsing - implement based on source structure
    return articles;
  }
  
  String _cleanHtml(String html) {
    // Remove HTML tags
    return html.replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
  
  double _analyzeSentiment(String text) {
    // Simple sentiment analysis based on keywords
    final bullish = ['bullish', 'surge', 'rally', 'gain', 'up', 'positive', 'breakout', 'high'];
    final bearish = ['bearish', 'drop', 'fall', 'down', 'negative', 'crash', 'low', 'decline'];
    
    final lowerText = text.toLowerCase();
    var bullishScore = 0.0;
    var bearishScore = 0.0;
    
    for (var word in bullish) {
      if (lowerText.contains(word)) bullishScore += 0.1;
    }
    
    for (var word in bearish) {
      if (lowerText.contains(word)) bearishScore += 0.1;
    }
    
    return (bullishScore - bearishScore).clamp(-1.0, 1.0);
  }
  
  List<String> _extractCurrencies(List<dynamic> currencies) {
    return currencies.map((c) => c['code'] as String).toList();
  }
  
  Future<List<NewsArticle>> searchNews(String query, {NewsType? type, int limit = 50}) async {
    final allArticles = type != null 
        ? await fetchNewsByType(_getTypeString(type))
        : _articles;
    
    final lowerQuery = query.toLowerCase();
    final results = allArticles.where((article) =>
        article.title.toLowerCase().contains(lowerQuery) ||
        article.description.toLowerCase().contains(lowerQuery)
    ).toList();
    
    results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return results.take(limit).toList();
  }
  
  Future<List<NewsArticle>> getNewsForSymbol(String symbol, {int limit = 20}) async {
    final allArticles = await refreshAllNews();
    final lowerSymbol = symbol.toLowerCase();
    
    return allArticles
        .where((article) =>
            article.title.toLowerCase().contains(lowerSymbol) ||
            article.description.toLowerCase().contains(lowerSymbol) ||
            article.currencies.any((c) => c.toLowerCase() == lowerSymbol))
        .take(limit)
        .toList();
  }
  
  void addListener(Function(List<NewsArticle>) listener) {
    _listeners.add(listener);
  }
  
  void removeListener(Function(List<NewsArticle>) listener) {
    _listeners.remove(listener);
  }
  
  void dispose() {
    _refreshTimer?.cancel();
    _listeners.clear();
  }
  
  String _getTypeString(NewsType type) {
    switch (type) {
      case NewsType.stocks:
        return 'stocks';
      case NewsType.crypto:
        return 'crypto';
      case NewsType.forex:
        return 'forex';
    }
  }
}
