// lib/widgets/breaking_news_ticker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../models/news_article.dart';

class BreakingNewsTicker extends StatefulWidget {
  final VoidCallback? onTap;
  
  const BreakingNewsTicker({Key? key, this.onTap}) : super(key: key);

  @override
  _BreakingNewsTickerState createState() => _BreakingNewsTickerState();
}

class _BreakingNewsTickerState extends State<BreakingNewsTicker> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  int _currentIndex = 0;
  Timer? _tickerTimer;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _startTicker();
  }
  
  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _getBreakingNews().length;
      });
      _animationController.reset();
      _animationController.forward();
    });
  }
  
  List<NewsArticle> _getBreakingNews() {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    return provider.articles
        .where((a) => a.sentiment.abs() > 0.5 || a.title.contains('BREAKING'))
        .take(10)
        .toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final breakingNews = _getBreakingNews();
    
    if (breakingNews.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final currentNews = breakingNews[_currentIndex % breakingNews.length];
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 40,
        color: Colors.red,
        child: SlideTransition(
          position: _slideAnimation,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.red[800],
                child: const Center(
                  child: Text(
                    'BREAKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Marquee(
                  text: currentNews.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                onPressed: () {
                  // Dismiss ticker temporarily
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _tickerTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

class Marquee extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  
  const Marquee({
    Key? key,
    required this.text,
    required this.style,
    this.duration = const Duration(seconds: 10),
  }) : super(key: key);

  @override
  _MarqueeState createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    
    _animation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(-1, 0),
    ).animate(_controller);
  }
  
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_animation.value.dx * MediaQuery.of(context).size.width, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
