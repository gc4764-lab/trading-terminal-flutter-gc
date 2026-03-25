// lib/models/news_article.dart
import 'package:hive/hive.dart';

part 'news_article.g.dart';

enum NewsType { stocks, crypto, forex }
enum NewsFormat { rss, json, html }

@HiveType(typeId: 7)
class NewsArticle {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String url;
  
  @HiveField(4)
  final String source;
  
  @HiveField(5)
  final NewsType type;
  
  @HiveField(6)
  final DateTime publishedAt;
  
  @HiveField(7)
  final double sentiment;
  
  @HiveField(8)
  final List<String> currencies;
  
  @HiveField(9)
  bool isRead;
  
  @HiveField(10)
  bool isBookmarked;
  
  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.type,
    required this.publishedAt,
    this.sentiment = 0,
    this.currencies = const [],
    this.isRead = false,
    this.isBookmarked = false,
  });
  
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';
  }
  
  Color get sentimentColor {
    if (sentiment > 0.2) return Colors.green;
    if (sentiment < -0.2) return Colors.red;
    return Colors.grey;
  }
  
  String get sentimentText {
    if (sentiment > 0.2) return 'Bullish';
    if (sentiment < -0.2) return 'Bearish';
    return 'Neutral';
  }
  
  IconData get sentimentIcon {
    if (sentiment > 0.2) return Icons.trending_up;
    if (sentiment < -0.2) return Icons.trending_down;
    return Icons.remove;
  }
  
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      source: json['source'],
      type: NewsType.values[json['type']],
      publishedAt: DateTime.parse(json['publishedAt']),
      sentiment: json['sentiment']?.toDouble() ?? 0,
      currencies: List<String>.from(json['currencies'] ?? []),
      isRead: json['isRead'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'source': source,
      'type': type.index,
      'publishedAt': publishedAt.toIso8601String(),
      'sentiment': sentiment,
      'currencies': currencies,
      'isRead': isRead,
      'isBookmarked': isBookmarked,
    };
  }
  
  NewsArticle copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? source,
    NewsType? type,
    DateTime? publishedAt,
    double? sentiment,
    List<String>? currencies,
    bool? isRead,
    bool? isBookmarked,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      source: source ?? this.source,
      type: type ?? this.type,
      publishedAt: publishedAt ?? this.publishedAt,
      sentiment: sentiment ?? this.sentiment,
      currencies: currencies ?? this.currencies,
      isRead: isRead ?? this.isRead,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class NewsSource {
  final String id;
  final String name;
  final String url;
  final NewsType type;
  final NewsFormat format;
  final int priority;
  
  NewsSource({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.format,
    this.priority = 1,
  });
}
