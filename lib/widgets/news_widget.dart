// lib/widgets/news_widget.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import '../providers/news_provider.dart';

class NewsWidget extends StatefulWidget {
  final NewsType? type;
  final String? symbol;
  
  const NewsWidget({Key? key, this.type, this.symbol}) : super(key: key);

  @override
  _NewsWidgetState createState() => _NewsWidgetState();
}

class _NewsWidgetState extends State<NewsWidget> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  NewsType _selectedType = NewsType.stocks;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.type ?? NewsType.stocks;
    _loadNews();
  }
  
  Future<void> _loadNews() async {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    await provider.refreshNews();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<NewsProvider>(
      builder: (context, provider, _) {
        final articles = _getFilteredArticles(provider.articles);
        
        return Column(
          children: [
            _buildSearchBar(),
            _buildTypeTabs(),
            Expanded(
              child: articles.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        return _buildNewsCard(articles[index], provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search news...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
  
  Widget _buildTypeTabs() {
    if (widget.type != null) return const SizedBox.shrink();
    
    return Container(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTypeTab(NewsType.stocks, 'Stocks', Icons.trending_up),
          _buildTypeTab(NewsType.crypto, 'Crypto', Icons.currency_bitcoin),
          _buildTypeTab(NewsType.forex, 'Forex', Icons.currency_exchange),
        ],
      ),
    );
  }
  
  Widget _buildTypeTab(NewsType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<NewsArticle> _getFilteredArticles(List<NewsArticle> articles) {
    var filtered = articles;
    
    // Filter by type
    if (widget.type != null) {
      filtered = filtered.where((a) => a.type == widget.type).toList();
    } else {
      filtered = filtered.where((a) => a.type == _selectedType).toList();
    }
    
    // Filter by symbol
    if (widget.symbol != null) {
      filtered = filtered.where((a) =>
          a.title.toLowerCase().contains(widget.symbol!.toLowerCase()) ||
          a.description.toLowerCase().contains(widget.symbol!.toLowerCase()) ||
          a.currencies.any((c) => c.toLowerCase() == widget.symbol!.toLowerCase())
      ).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) =>
          a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }
  
  Widget _buildNewsCard(NewsArticle article, NewsProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _openArticle(article, provider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor(article.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeLabel(article.type),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getTypeColor(article.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article.source,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article.formattedDate,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      article.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 16,
                    ),
                    onPressed: () => provider.toggleBookmark(article.id),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Title
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Description
              Text(
                article.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Footer
              Row(
                children: [
                  // Sentiment indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: article.sentimentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(article.sentimentIcon, size: 12, color: article.sentimentColor),
                        const SizedBox(width: 4),
                        Text(
                          article.sentimentText,
                          style: TextStyle(
                            fontSize: 10,
                            color: article.sentimentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Currencies
                  if (article.currencies.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: article.currencies.take(3).map((currency) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currency,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.newspaper, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No news available',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadNews,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
  
  Color _getTypeColor(NewsType type) {
    switch (type) {
      case NewsType.stocks:
        return Colors.blue;
      case NewsType.crypto:
        return Colors.orange;
      case NewsType.forex:
        return Colors.green;
    }
  }
  
  String _getTypeLabel(NewsType type) {
    switch (type) {
      case NewsType.stocks:
        return 'STOCKS';
      case NewsType.crypto:
        return 'CRYPTO';
      case NewsType.forex:
        return 'FOREX';
    }
  }
  
  Future<void> _openArticle(NewsArticle article, NewsProvider provider) async {
    // Mark as read
    provider.markAsRead(article.id);
    
    final url = Uri.parse(article.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open article')),
      );
    }
  }
}
