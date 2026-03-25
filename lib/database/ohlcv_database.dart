// lib/database/ohlcv_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/chart_data.dart';

class OHLCVDatabase {
  static final OHLCVDatabase _instance = OHLCVDatabase._internal();
  static Database? _database;
  
  factory OHLCVDatabase() => _instance;
  OHLCVDatabase._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ohlcv_data.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create symbols table
    await db.execute('''
      CREATE TABLE symbols (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT NOT NULL,
        exchange TEXT,
        type TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(symbol, exchange)
      )
    ''');
    
    // Create OHLCV data table
    await db.execute('''
      CREATE TABLE ohlcv_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol_id INTEGER NOT NULL,
        timeframe TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        open REAL NOT NULL,
        high REAL NOT NULL,
        low REAL NOT NULL,
        close REAL NOT NULL,
        volume REAL NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (symbol_id) REFERENCES symbols (id) ON DELETE CASCADE,
        UNIQUE(symbol_id, timeframe, timestamp)
      )
    ''');
    
    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_ohlcv_symbol_timeframe 
      ON ohlcv_data(symbol_id, timeframe, timestamp)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_ohlcv_timestamp 
      ON ohlcv_data(timestamp)
    ''');
    
    // Create cache metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol_id INTEGER NOT NULL,
        timeframe TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        first_timestamp INTEGER NOT NULL,
        last_timestamp INTEGER NOT NULL,
        total_bars INTEGER NOT NULL,
        FOREIGN KEY (symbol_id) REFERENCES symbols (id) ON DELETE CASCADE,
        UNIQUE(symbol_id, timeframe)
      )
    ''');
    
    // Create table for chart settings
    await db.execute('''
      CREATE TABLE chart_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol_id INTEGER NOT NULL,
        timeframe TEXT NOT NULL,
        indicator_settings TEXT,
        drawing_settings TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (symbol_id) REFERENCES symbols (id) ON DELETE CASCADE,
        UNIQUE(symbol_id, timeframe)
      )
    ''');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add any future migrations here
    }
  }
  
  // Get or create symbol
  Future<int> getOrCreateSymbol(String symbol, {String? exchange, String? type}) async {
    final db = await database;
    
    // Check if symbol exists
    List<Map<String, dynamic>> result = await db.query(
      'symbols',
      where: 'symbol = ? AND exchange = ?',
      whereArgs: [symbol, exchange ?? ''],
    );
    
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    
    // Insert new symbol
    int id = await db.insert('symbols', {
      'symbol': symbol,
      'exchange': exchange,
      'type': type,
    });
    
    return id;
  }
  
  // Save OHLCV data in batch
  Future<void> saveOHLCVDataBatch(
    String symbol,
    String timeframe,
    List<ChartData> data,
    {String? exchange, String? type}
  ) async {
    final db = await database;
    final symbolId = await getOrCreateSymbol(symbol, exchange: exchange, type: type);
    
    // Use batch transaction for better performance
    Batch batch = db.batch();
    
    for (var candle in data) {
      batch.insert(
        'ohlcv_data',
        {
          'symbol_id': symbolId,
          'timeframe': timeframe,
          'timestamp': candle.date.millisecondsSinceEpoch,
          'open': candle.open,
          'high': candle.high,
          'low': candle.low,
          'close': candle.close,
          'volume': candle.volume,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
    
    // Update cache metadata
    await _updateCacheMetadata(symbolId, timeframe, data);
  }
  
  // Update cache metadata
  Future<void> _updateCacheMetadata(int symbolId, String timeframe, List<ChartData> data) async {
    final db = await database;
    
    if (data.isEmpty) return;
    
    data.sort((a, b) => a.date.compareTo(b.date));
    
    await db.insert(
      'cache_metadata',
      {
        'symbol_id': symbolId,
        'timeframe': timeframe,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
        'first_timestamp': data.first.date.millisecondsSinceEpoch,
        'last_timestamp': data.last.date.millisecondsSinceEpoch,
        'total_bars': data.length,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Retrieve OHLCV data
  Future<List<ChartData>> getOHLCVData(
    String symbol,
    String timeframe, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? exchange,
    String? type,
  }) async {
    final db = await database;
    final symbolId = await getOrCreateSymbol(symbol, exchange: exchange, type: type);
    
    var conditions = ['symbol_id = ?', 'timeframe = ?'];
    var args = [symbolId, timeframe];
    
    if (startDate != null) {
      conditions.add('timestamp >= ?');
      args.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      conditions.add('timestamp <= ?');
      args.add(endDate.millisecondsSinceEpoch);
    }
    
    String query = '''
      SELECT * FROM ohlcv_data 
      WHERE ${conditions.join(' AND ')}
      ORDER BY timestamp ASC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    
    List<Map<String, dynamic>> results = await db.rawQuery(query, args);
    
    return results.map((row) => ChartData(
      date: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      open: row['open'] as double,
      high: row['high'] as double,
      low: row['low'] as double,
      close: row['close'] as double,
      volume: row['volume'] as double,
    )).toList();
  }
  
  // Get cache metadata
  Future<Map<String, dynamic>?> getCacheMetadata(String symbol, String timeframe, {String? exchange, String? type}) async {
    final db = await database;
    final symbolId = await getOrCreateSymbol(symbol, exchange: exchange, type: type);
    
    List<Map<String, dynamic>> results = await db.query(
      'cache_metadata',
      where: 'symbol_id = ? AND timeframe = ?',
      whereArgs: [symbolId, timeframe],
    );
    
    if (results.isEmpty) return null;
    return results.first;
  }
  
  // Check if data is available in cache
  Future<bool> isDataCached(
    String symbol,
    String timeframe,
    DateTime startDate,
    DateTime endDate,
    {String? exchange, String? type}
  ) async {
    final metadata = await getCacheMetadata(symbol, timeframe, exchange: exchange, type: type);
    
    if (metadata == null) return false;
    
    final cachedStart = DateTime.fromMillisecondsSinceEpoch(metadata['first_timestamp'] as int);
    final cachedEnd = DateTime.fromMillisecondsSinceEpoch(metadata['last_timestamp'] as int);
    
    return cachedStart.isBefore(startDate) && cachedEnd.isAfter(endDate);
  }
  
  // Delete old data to manage storage
  Future<int> deleteOldData(int daysOld) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    return await db.delete(
      'ohlcv_data',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }
  
  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final db = await database;
    
    // Total number of bars
    var result = await db.rawQuery('SELECT COUNT(*) as count FROM ohlcv_data');
    final totalBars = result.first['count'] as int;
    
    // Total symbols
    result = await db.rawQuery('SELECT COUNT(*) as count FROM symbols');
    final totalSymbols = result.first['count'] as int;
    
    // Database size
    final dbPath = await getDatabasesPath();
    final file = File(join(dbPath, 'ohlcv_data.db'));
    final size = await file.exists() ? await file.length() : 0;
    
    return {
      'total_bars': totalBars,
      'total_symbols': totalSymbols,
      'database_size_bytes': size,
      'database_size_mb': size / (1024 * 1024),
    };
  }
  
  // Optimize database
  Future<void> optimizeDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
    await db.execute('REINDEX');
  }
  
  // Get latest data point
  Future<ChartData?> getLatestData(String symbol, String timeframe, {String? exchange, String? type}) async {
    final db = await database;
    final symbolId = await getOrCreateSymbol(symbol, exchange: exchange, type: type);
    
    List<Map<String, dynamic>> results = await db.query(
      'ohlcv_data',
      where: 'symbol_id = ? AND timeframe = ?',
      whereArgs: [symbolId, timeframe],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    final row = results.first;
    return ChartData(
      date: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      open: row['open'] as double,
      high: row['high'] as double,
      low: row['low'] as double,
      close: row['close'] as double,
      volume: row['volume'] as double,
    );
  }
  
  // Get multiple symbols data in one query
  Future<Map<String, List<ChartData>>> getMultipleSymbolsData(
    List<String> symbols,
    String timeframe,
    DateTime startDate,
    DateTime endDate,
    {String? exchange, String? type}
  ) async {
    final db = await database;
    final result = <String, List<ChartData>>{};
    
    for (var symbol in symbols) {
      final data = await getOHLCVData(
        symbol,
        timeframe,
        startDate: startDate,
        endDate: endDate,
        exchange: exchange,
        type: type,
      );
      result[symbol] = data;
    }
    
    return result;
  }
}
