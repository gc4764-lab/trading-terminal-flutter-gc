import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/multi_window_provider.dart';
import 'screens/main_screen.dart';
import 'utils/constants.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize window manager for desktop
  await windowManager.ensureInitialized();
  
  if (PlatformUtils.isDesktop) {
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.setTitle('Trading Terminal');
  }
  
  // Initialize services
  await DataService.initialize();
  
  runApp(const TradingTerminalApp());
  
  FlutterNativeSplash.remove();
}

class TradingTerminalApp extends StatelessWidget {
  const TradingTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiWindowProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}



// lib/main.dart (Updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/broker_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/risk_provider.dart';
import 'screens/main_screen.dart';
import 'services/broker_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatelessWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}



// lib/main.dart (Updated with prefetch)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/broker_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/chart_provider.dart';
import 'screens/main_screen.dart';
import 'services/broker_manager.dart';
import 'services/prefetch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatefulWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  _TradingTerminalAppState createState() => _TradingTerminalAppState();
}

class _TradingTerminalAppState extends State<TradingTerminalApp> {
  final PrefetchService _prefetchService = PrefetchService();
  
  @override
  void initState() {
    super.initState();
    _initializePrefetch();
  }
  
  Future<void> _initializePrefetch() async {
    // Wait for providers to be ready
    await Future.delayed(const Duration(seconds: 2));
    
    // Start prefetching
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    _prefetchService.startPrefetching(watchlistProvider);
  }
  
  @override
  void dispose() {
    _prefetchService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}




// lib/main.dart (Final Updated Version)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/broker_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/chart_provider.dart';
import 'screens/main_screen.dart';
import 'services/broker_manager.dart';
import 'services/prefetch_service.dart';
import 'services/performance_monitor.dart';
import 'services/enhanced_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  // Start performance monitoring
  PerformanceMonitor().startMonitoring();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatefulWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  _TradingTerminalAppState createState() => _TradingTerminalAppState();
}

class _TradingTerminalAppState extends State<TradingTerminalApp> {
  final PrefetchService _prefetchService = PrefetchService();
  final EnhancedDataService _dataService = EnhancedDataService();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    // Wait for providers to be ready
    await Future.delayed(const Duration(seconds: 2));
    
    // Start prefetching
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    _prefetchService.startPrefetching(watchlistProvider);
    
    // Prefetch common symbols on launch
    final symbols = watchlistProvider.activeWatchlist.symbols;
    for (var symbol in symbols) {
      unawaited(_dataService.getData(
        symbol: symbol,
        timeframe: '1d',
        limit: 100,
      ));
    }
  }
  
  @override
  void dispose() {
    _prefetchService.dispose();
    PerformanceMonitor().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}





// lib/main.dart (Updated with News)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/broker_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/chart_provider.dart';
import 'providers/news_provider.dart';
import 'screens/main_screen.dart';
import 'services/broker_manager.dart';
import 'services/prefetch_service.dart';
import 'services/performance_monitor.dart';
import 'services/enhanced_data_service.dart';
import 'services/news_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  // Initialize news service
  final newsService = NewsService();
  newsService.initialize();
  
  // Start performance monitoring
  PerformanceMonitor().startMonitoring();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatefulWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  _TradingTerminalAppState createState() => _TradingTerminalAppState();
}

class _TradingTerminalAppState extends State<TradingTerminalApp> {
  final PrefetchService _prefetchService = PrefetchService();
  final EnhancedDataService _dataService = EnhancedDataService();
  final NewsService _newsService = NewsService();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    _prefetchService.startPrefetching(watchlistProvider);
    
    final symbols = watchlistProvider.activeWatchlist.symbols;
    for (var symbol in symbols) {
      unawaited(_dataService.getData(
        symbol: symbol,
        timeframe: '1d',
        limit: 100,
      ));
    }
  }
  
  @override
  void dispose() {
    _prefetchService.dispose();
    _newsService.dispose();
    PerformanceMonitor().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}






// lib/main.dart (updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/broker_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/chart_provider.dart';
import 'providers/news_provider.dart';
import 'screens/main_screen.dart';
import 'services/broker_manager.dart';
import 'services/prefetch_service.dart';
import 'services/performance_monitor.dart';
import 'services/enhanced_data_service.dart';
import 'services/news_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  // Restore saved broker sessions
  await brokerManager.restoreSessions();
  
  // Initialize news service
  final newsService = NewsService();
  newsService.initialize();
  
  // Start performance monitoring
  PerformanceMonitor().startMonitoring();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatefulWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  _TradingTerminalAppState createState() => _TradingTerminalAppState();
}

class _TradingTerminalAppState extends State<TradingTerminalApp> {
  final PrefetchService _prefetchService = PrefetchService();
  final EnhancedDataService _dataService = EnhancedDataService();
  final NewsService _newsService = NewsService();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    _prefetchService.startPrefetching(watchlistProvider);
    
    final symbols = watchlistProvider.activeWatchlist.symbols;
    for (var symbol in symbols) {
      unawaited(_dataService.getData(
        symbol: symbol,
        timeframe: '1d',
        limit: 100,
      ));
    }
  }
  
  @override
  void dispose() {
    _prefetchService.dispose();
    _newsService.dispose();
    PerformanceMonitor().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}





// lib/main.dart (updated with routing)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
// ... other providers
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  // Restore saved broker sessions
  await brokerManager.restoreSessions();
  
  // Initialize news service
  final newsService = NewsService();
  newsService.initialize();
  
  // Start performance monitoring
  PerformanceMonitor().startMonitoring();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatelessWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (userProvider.isLoggedIn) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}





// lib/main.dart (Final Updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/broker_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/order_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/chart_provider.dart';
import 'providers/news_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/broker_manager.dart';
import 'services/token_refresh_manager.dart';
import 'services/performance_monitor.dart';
import 'services/enhanced_data_service.dart';
import 'services/news_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize broker manager
  final brokerManager = BrokerManager();
  brokerManager.initializeBrokers();
  
  // Restore saved broker sessions
  await brokerManager.restoreSessions();
  
  // Initialize news service
  final newsService = NewsService();
  newsService.initialize();
  
  // Start performance monitoring
  PerformanceMonitor().startMonitoring();
  
  runApp(const TradingTerminalApp());
}

class TradingTerminalApp extends StatefulWidget {
  const TradingTerminalApp({Key? key}) : super(key: key);

  @override
  _TradingTerminalAppState createState() => _TradingTerminalAppState();
}

class _TradingTerminalAppState extends State<TradingTerminalApp> {
  final PrefetchService _prefetchService = PrefetchService();
  final EnhancedDataService _dataService = EnhancedDataService();
  final NewsService _newsService = NewsService();
  final TokenRefreshManager _tokenRefreshManager = TokenRefreshManager();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    _prefetchService.startPrefetching(watchlistProvider);
    
    final symbols = watchlistProvider.activeWatchlist.symbols;
    for (var symbol in symbols) {
      unawaited(_dataService.getData(
        symbol: symbol,
        timeframe: '1d',
        limit: 100,
      ));
    }
  }
  
  @override
  void dispose() {
    _prefetchService.dispose();
    _newsService.dispose();
    PerformanceMonitor().dispose();
    _tokenRefreshManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BrokerProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => RiskProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'Trading Terminal Pro',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          cardTheme: CardTheme(
            color: Colors.grey[900],
            elevation: 2,
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (userProvider.isLoggedIn) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}









