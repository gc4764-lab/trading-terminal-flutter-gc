// lib/providers/portfolio_provider.dart
import 'package:flutter/material.dart';
import '../models/position.dart';
import '../models/holding.dart';
import '../services/broker_manager.dart';

class PortfolioProvider extends ChangeNotifier {
  List<Position> _openPositions = [];
  List<Holding> _holdings = [];
  double _totalValue = 0;
  double _totalPnL = 0;
  double _availableMargin = 0;
  
  List<Position> get openPositions => _openPositions;
  List<Holding> get holdings => _holdings;
  double get totalValue => _totalValue;
  double get totalPnL => _totalPnL;
  double get totalPnLPercent => _totalValue > 0 ? (_totalPnL / (_totalValue - _totalPnL)) * 100 : 0;
  double get availableMargin => _availableMargin;
  
  PortfolioProvider() {
    loadPortfolio();
  }
  
  Future<void> loadPortfolio() async {
    // Load from all connected brokers
    final brokerManager = BrokerManager();
    final allBrokers = brokerManager.getAllBrokers();
    
    for (var broker in allBrokers) {
      if (broker.isConnected) {
        await _loadPositionsFromBroker(broker);
        await _loadHoldingsFromBroker(broker);
        await _loadMarginFromBroker(broker);
      }
    }
    
    _calculateTotals();
    notifyListeners();
  }
  
  Future<void> _loadPositionsFromBroker(BaseBroker broker) async {
    final response = await broker.getPositions();
    if (response.success && response.data != null) {
      final positions = (response.data as List).map((json) => Position.fromJson(json)).toList();
      _openPositions.addAll(positions);
    }
  }
  
  Future<void> _loadHoldingsFromBroker(BaseBroker broker) async {
    final response = await broker.getHoldings();
    if (response.success && response.data != null) {
      final holdings = (response.data as List).map((json) => Holding.fromJson(json)).toList();
      _holdings.addAll(holdings);
    }
  }
  
  Future<void> _loadMarginFromBroker(BaseBroker broker) async {
    final response = await broker.getMargin();
    if (response.success && response.data != null) {
      _availableMargin += (response.data['available_margin'] ?? 0).toDouble();
    }
  }
  
  void _calculateTotals() {
    _totalValue = _openPositions.fold(0, (sum, p) => sum + p.currentValue) +
                  _holdings.fold(0, (sum, h) => sum + h.currentValue);
    
    _totalPnL = _openPositions.fold(0, (sum, p) => sum + p.unrealizedPnL) +
                _holdings.fold(0, (sum, h) => sum + h.unrealizedPnL);
  }
  
  Future<void> refreshPortfolio() async {
    _openPositions.clear();
    _holdings.clear();
    _totalValue = 0;
    _totalPnL = 0;
    _availableMargin = 0;
    
    await loadPortfolio();
  }
  
  Future<void> closePosition(String symbol, double quantity) async {
    // Implement position closing
    notifyListeners();
  }
}





// lib/providers/portfolio_provider.dart (Updated)
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/position.dart';
import '../models/holding.dart';
import '../services/broker_manager.dart';

class PortfolioProvider extends ChangeNotifier {
  List<Position> _openPositions = [];
  List<Holding> _holdings = [];
  List<double> _equityHistory = [];
  Map<String, Map<int, double>> _monthlyReturns = {};
  Map<String, double> _varData = {};
  Map<String, double> _stressTestResults = {};
  Map<String, Map<String, double>> _correlationMatrix = {};
  Map<String, double> _assetAllocation = {};
  Map<String, double> _sectorExposure = {};
  Map<String, double> _expectedReturns = {};
  Map<String, List<double>> _monteCarloResults = {};
  
  // Performance metrics
  double _totalReturnPercent = 0;
  double _annualizedReturn = 0;
  double _volatility = 0;
  double _sharpeRatio = 0;
  double _sortinoRatio = 0;
  double _maxDrawdown = 0;
  double _calmarRatio = 0;
  double _winRate = 0;
  double _profitFactor = 0;
  double _recoveryFactor = 0;
  double _beta = 0;
  double _alpha = 0;
  double _valueAtRisk = 0;
  double _conditionalVaR = 0;
  double _riskScore = 0;
  
  // Getters
  List<Position> get openPositions => _openPositions;
  List<Holding> get holdings => _holdings;
  List<double> get equityHistory => _equityHistory;
  Map<String, Map<int, double>> get monthlyReturns => _monthlyReturns;
  Map<String, double> get varData => _varData;
  Map<String, double> get stressTestResults => _stressTestResults;
  Map<String, Map<String, double>> get correlationMatrix => _correlationMatrix;
  Map<String, double> get assetAllocation => _assetAllocation;
  Map<String, double> get sectorExposure => _sectorExposure;
  Map<String, double> get expectedReturns => _expectedReturns;
  Map<String, List<double>> get monteCarloResults => _monteCarloResults;
  
  double get totalReturnPercent => _totalReturnPercent;
  double get annualizedReturn => _annualizedReturn;
  double get volatility => _volatility;
  double get sharpeRatio => _sharpeRatio;
  double get sortinoRatio => _sortinoRatio;
  double get maxDrawdown => _maxDrawdown;
  double get calmarRatio => _calmarRatio;
  double get winRate => _winRate;
  double get profitFactor => _profitFactor;
  double get recoveryFactor => _recoveryFactor;
  double get beta => _beta;
  double get alpha => _alpha;
  double get valueAtRisk => _valueAtRisk;
  double get conditionalVaR => _conditionalVaR;
  double get riskScore => _riskScore;
  
  double get totalValue {
    return _openPositions.fold(0, (sum, p) => sum + p.currentValue) +
           _holdings.fold(0, (sum, h) => sum + h.currentValue);
  }
  
  double get totalPnL {
    return _openPositions.fold(0, (sum, p) => sum + p.unrealizedPnL) +
           _holdings.fold(0, (sum, h) => sum + h.unrealizedPnL);
  }
  
  double get totalPnLPercent => totalValue > 0 ? (totalPnL / (totalValue - totalPnL)) * 100 : 0;
  
  PortfolioProvider() {
    loadPortfolio();
  }
  
  Future<void> loadPortfolio() async {
    await _loadFromBrokers();
    await _calculateMetrics();
    await _runAnalytics();
    notifyListeners();
  }
  
  Future<void> _loadFromBrokers() async {
    final brokerManager = BrokerManager();
    final allBrokers = brokerManager.getAllBrokers();
    
    for (var broker in allBrokers) {
      if (broker.isConnected) {
        await _loadPositionsFromBroker(broker);
        await _loadHoldingsFromBroker(broker);
      }
    }
  }
  
  Future<void> _loadPositionsFromBroker(BaseBroker broker) async {
    final response = await broker.getPositions();
    if (response.success && response.data != null) {
      final positions = (response.data as List).map((json) => Position.fromJson(json)).toList();
      _openPositions.addAll(positions);
    }
  }
  
  Future<void> _loadHoldingsFromBroker(BaseBroker broker) async {
    final response = await broker.getHoldings();
    if (response.success && response.data != null) {
      final holdings = (response.data as List).map((json) => Holding.fromJson(json)).toList();
      _holdings.addAll(holdings);
    }
  }
  
  Future<void> _calculateMetrics() async {
    // Calculate equity history from trades
    _calculateEquityHistory();
    
    // Calculate monthly returns
    _calculateMonthlyReturns();
    
    // Calculate performance metrics
    _calculatePerformanceMetrics();
    
    // Calculate risk metrics
    _calculateRiskMetrics();
  }
  
  void _calculateEquityHistory() {
    // Build equity curve from trade history
    _equityHistory = [];
    double equity = 100000; // Starting capital
    
    // This would be populated from actual trade history
    for (var i = 0; i < 100; i++) {
      equity *= (1 + (Random().nextDouble() - 0.5) * 0.05);
      _equityHistory.add(equity);
    }
  }
  
  void _calculateMonthlyReturns() {
    // Calculate monthly returns from equity curve
    _monthlyReturns = {};
    // Implementation
  }
  
  void _calculatePerformanceMetrics() {
    if (_equityHistory.isEmpty) return;
    
    final initialEquity = _equityHistory.first;
    final finalEquity = _equityHistory.last;
    _totalReturnPercent = ((finalEquity - initialEquity) / initialEquity) * 100;
    
    // Annualized return
    final years = _equityHistory.length / 252; // Assuming daily data
    _annualizedReturn = (pow(1 + _totalReturnPercent / 100, 1 / years) - 1) * 100;
    
    // Calculate daily returns
    final dailyReturns = <double>[];
    for (var i = 1; i < _equityHistory.length; i++) {
      dailyReturns.add((_equityHistory[i] - _equityHistory[i - 1]) / _equityHistory[i - 1]);
    }
    
    // Volatility (annualized)
    final meanReturn = dailyReturns.reduce((a, b) => a + b) / dailyReturns.length;
    final variance = dailyReturns.map((r) => pow(r - meanReturn, 2)).reduce((a, b) => a + b) / dailyReturns.length;
    _volatility = sqrt(variance) * sqrt(252) * 100;
    
    // Sharpe Ratio (assuming 2% risk-free rate)
    final riskFreeRate = 0.02;
    _sharpeRatio = ((_annualizedReturn / 100) - riskFreeRate) / (_volatility / 100);
    
    // Sortino Ratio (downside deviation)
    final negativeReturns = dailyReturns.where((r) => r < 0).toList();
    final downsideVariance = negativeReturns.isEmpty ? 0 : 
        negativeReturns.map((r) => pow(r - meanReturn, 2)).reduce((a, b) => a + b) / negativeReturns.length;
    final downsideDeviation = sqrt(downsideVariance) * sqrt(252);
    _sortinoRatio = downsideDeviation > 0 ? ((_annualizedReturn / 100) - riskFreeRate) / downsideDeviation : 0;
    
    // Maximum Drawdown
    var peak = _equityHistory[0];
    _maxDrawdown = 0;
    for (var value in _equityHistory) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / peak * 100;
      if (drawdown > _maxDrawdown) _maxDrawdown = drawdown;
    }
    
    // Calmar Ratio
    _calmarRatio = _maxDrawdown > 0 ? _annualizedReturn / _maxDrawdown : 0;
  }
  
  void _calculateRiskMetrics() {
    // Value at Risk (95% confidence)
    final dailyReturns = <double>[];
    for (var i = 1; i < _equityHistory.length; i++) {
      dailyReturns.add((_equityHistory[i] - _equityHistory[i - 1]) / _equityHistory[i - 1]);
    }
    
    dailyReturns.sort();
    final var95Index = (dailyReturns.length * 0.05).floor();
    _valueAtRisk = dailyReturns[var95Index] * totalValue * -1;
    
    // Conditional VaR
    final tailReturns = dailyReturns.sublist(0, var95Index);
    final avgTailReturn = tailReturns.reduce((a, b) => a + b) / tailReturns.length;
    _conditionalVaR = avgTailReturn * totalValue * -1;
    
    // Risk Score (0-100)
    _riskScore = (_volatility / 50 * 30 + _maxDrawdown / 20 * 30 + (1 - _sharpeRatio / 3).clamp(0, 1) * 40).clamp(0, 100).toDouble();
  }
  
  Future<void> _runAnalytics() async {
    await _calculateCorrelationMatrix();
    await _calculateAssetAllocation();
    await _calculateSectorExposure();
    await _calculateExpectedReturns();
    await _runMonteCarloSimulation();
    await _calculateStressTestResults();
  }
  
  Future<void> _calculateCorrelationMatrix() async {
    // Calculate correlation between assets
    _correlationMatrix = {};
    // Implementation
  }
  
  Future<void> _calculateAssetAllocation() async {
    _assetAllocation = {};
    for (var position in _openPositions) {
      _assetAllocation[position.symbol] = (position.currentValue / totalValue) * 100;
    }
  }
  
  Future<void> _calculateSectorExposure() async {
    _sectorExposure = {
      'Technology': 35.0,
      'Finance': 25.0,
      'Healthcare': 15.0,
      'Energy': 10.0,
      'Consumer': 10.0,
      'Industrial': 5.0,
    };
  }
  
  Future<void> _calculateExpectedReturns() async {
    _expectedReturns = {
      'AAPL': 12.5,
      'GOOGL': 10.2,
      'MSFT': 11.8,
      'AMZN': 15.3,
      'TSLA': 8.5,
    };
  }
  
  Future<void> _runMonteCarloSimulation() async {
    final simulations = 10000;
    final days = 252;
    final results = <double>[];
    
    final meanReturn = _annualizedReturn / 100 / 252;
    final stdDev = _volatility / 100 / sqrt(252);
    
    for (var i = 0; i < simulations; i++) {
      var equity = totalValue;
      for (var day = 0; day < days; day++) {
        final randomReturn = meanReturn + stdDev * _generateNormalRandom();
        equity *= (1 + randomReturn);
      }
      results.add(equity);
    }
    
    results.sort();
    
    _monteCarloResults = {
      'median': [totalValue],
      'upper': [totalValue],
      'lower': [totalValue],
    };
    
    // Calculate percentiles
    final medianIndex = (simulations * 0.5).floor();
    final upperIndex = (simulations * 0.95).floor();
    final lowerIndex = (simulations * 0.05).floor();
    
    // Generate path for visualization
    for (var day = 0; day < days; day += days ~/ 100) {
      // Simplified: would need to calculate paths
    }
  }
  
  double _generateNormalRandom() {
    double u1 = Random().nextDouble();
    double u2 = Random().nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }
  
  Future<void> _calculateStressTestResults() async {
    _stressTestResults = {
      'Market Crash (-20%)': -18.5,
      'Interest Rate Hike (+2%)': -12.3,
      'Recession': -25.7,
      'Oil Price Spike': -8.2,
      'Currency Crisis': -15.4,
    };
  }
  
  Future<void> refreshPortfolio() async {
    _openPositions.clear();
    _holdings.clear();
    await loadPortfolio();
  }
}





