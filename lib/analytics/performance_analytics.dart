// lib/analytics/performance_analytics.dart
import 'dart:math';
import 'package:flutter/material.dart';

class PerformanceAnalytics {
  final List<double> _returns;
  final List<double> _equityCurve;
  final List<DateTime> _dates;
  
  PerformanceAnalytics({
    required List<double> returns,
    required List<double> equityCurve,
    required List<DateTime> dates,
  }) : _returns = returns,
       _equityCurve = equityCurve,
       _dates = dates;
  
  // ==================== CORE PERFORMANCE METRICS ====================
  
  double get totalReturn {
    if (_equityCurve.isEmpty) return 0;
    return ((_equityCurve.last - _equityCurve.first) / _equityCurve.first) * 100;
  }
  
  double get annualizedReturn {
    if (_equityCurve.isEmpty) return 0;
    final years = _getTradingYears();
    return (pow(1 + totalReturn / 100, 1 / years) - 1) * 100;
  }
  
  double get volatility {
    if (_returns.length < 2) return 0;
    final mean = _returns.reduce((a, b) => a + b) / _returns.length;
    final variance = _returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / _returns.length;
    return sqrt(variance) * sqrt(252) * 100;
  }
  
  double get sharpeRatio {
    final riskFreeRate = 0.02;
    return volatility > 0 ? (annualizedReturn / 100 - riskFreeRate) / (volatility / 100) : 0;
  }
  
  double get sortinoRatio {
    final riskFreeRate = 0.02;
    final downsideDeviation = _calculateDownsideDeviation();
    return downsideDeviation > 0 ? (annualizedReturn / 100 - riskFreeRate) / downsideDeviation : 0;
  }
  
  double get calmarRatio {
    return maxDrawdown > 0 ? annualizedReturn / maxDrawdown : 0;
  }
  
  double get omegaRatio {
    // Omega ratio = (positive returns) / (negative returns)
    final positiveReturns = _returns.where((r) => r > 0).toList();
    final negativeReturns = _returns.where((r) => r < 0).toList();
    
    final totalPositive = positiveReturns.reduce((a, b) => a + b);
    final totalNegative = negativeReturns.reduce((a, b) => a + b).abs();
    
    return totalNegative > 0 ? totalPositive / totalNegative : double.infinity;
  }
  
  // ==================== RISK METRICS ====================
  
  double get maxDrawdown {
    var peak = _equityCurve.first;
    var maxDD = 0.0;
    
    for (var value in _equityCurve) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / peak * 100;
      if (drawdown > maxDD) maxDD = drawdown;
    }
    
    return maxDD;
  }
  
  Map<String, double> get drawdownPeriods {
    var peak = _equityCurve.first;
    var peakDate = _dates.first;
    var maxDD = 0.0;
    var maxDDStart = _dates.first;
    var maxDDEnd = _dates.first;
    var currentDD = 0.0;
    var currentDDStart = _dates.first;
    var inDrawdown = false;
    
    for (var i = 0; i < _equityCurve.length; i++) {
      final value = _equityCurve[i];
      final date = _dates[i];
      
      if (value > peak) {
        peak = value;
        peakDate = date;
        inDrawdown = false;
      } else {
        final drawdown = (peak - value) / peak * 100;
        if (!inDrawdown) {
          inDrawdown = true;
          currentDDStart = date;
        }
        
        if (drawdown > maxDD) {
          maxDD = drawdown;
          maxDDStart = currentDDStart;
          maxDDEnd = date;
        }
        currentDD = drawdown;
      }
    }
    
    return {
      'max_drawdown': maxDD,
      'max_drawdown_days': maxDDEnd.difference(maxDDStart).inDays.toDouble(),
      'current_drawdown': currentDD,
    };
  }
  
  double get valueAtRisk95 {
    if (_returns.isEmpty) return 0;
    final sortedReturns = List<double>.from(_returns)..sort();
    final index = (sortedReturns.length * 0.05).floor();
    return sortedReturns[index] * 100;
  }
  
  double get conditionalVaR95 {
    if (_returns.isEmpty) return 0;
    final sortedReturns = List<double>.from(_returns)..sort();
    final index = (sortedReturns.length * 0.05).floor();
    final tail = sortedReturns.sublist(0, index);
    return (tail.reduce((a, b) => a + b) / tail.length) * 100;
  }
  
  Map<String, double> get riskMetrics {
    return {
      'var_95': valueAtRisk95,
      'cvar_95': conditionalVaR95,
      'expected_shortfall': conditionalVaR95,
      'max_drawdown': maxDrawdown,
      'volatility': volatility,
    };
  }
  
  // ==================== TRADE STATISTICS ====================
  
  Map<String, double> get tradeStatistics {
    final winningTrades = _returns.where((r) => r > 0).toList();
    final losingTrades = _returns.where((r) => r < 0).toList();
    
    final winRate = winningTrades.length / _returns.length * 100;
    final avgWin = winningTrades.isEmpty ? 0 : winningTrades.reduce((a, b) => a + b) / winningTrades.length * 100;
    final avgLoss = losingTrades.isEmpty ? 0 : losingTrades.reduce((a, b) => a + b) / losingTrades.length * 100;
    
    return {
      'total_trades': _returns.length.toDouble(),
      'winning_trades': winningTrades.length.toDouble(),
      'losing_trades': losingTrades.length.toDouble(),
      'win_rate': winRate,
      'average_win': avgWin,
      'average_loss': avgLoss.abs(),
      'profit_factor': avgLoss.abs() > 0 ? avgWin / avgLoss.abs() : 0,
      'largest_win': winningTrades.isEmpty ? 0 : winningTrades.reduce((a, b) => a > b ? a : b) * 100,
      'largest_loss': losingTrades.isEmpty ? 0 : losingTrades.reduce((a, b) => a < b ? a : b).abs() * 100,
      'average_trade': (_returns.reduce((a, b) => a + b) / _returns.length) * 100,
    };
  }
  
  Map<String, double> get recoveryMetrics {
    final maxDD = maxDrawdown;
    final peak = _findPeak();
    final current = _equityCurve.last;
    final recoveryFromPeak = ((current - peak) / peak) * 100;
    
    return {
      'peak_value': peak,
      'recovery_from_peak': recoveryFromPeak,
      'days_to_recover': _calculateRecoveryDays(),
      'recovery_factor': recoveryFactor,
    };
  }
  
  double get recoveryFactor {
    final totalProfit = _returns.where((r) => r > 0).reduce((a, b) => a + b);
    final maxDDValue = maxDrawdown / 100;
    return maxDDValue > 0 ? totalProfit / maxDDValue : 0;
  }
  
  // ==================== RATIOS ====================
  
  Map<String, double> get performanceRatios {
    return {
      'sharpe_ratio': sharpeRatio,
      'sortino_ratio': sortinoRatio,
      'calmar_ratio': calmarRatio,
      'omega_ratio': omegaRatio,
      'sterling_ratio': _calculateSterlingRatio(),
      'burke_ratio': _calculateBurkeRatio(),
      'martin_ratio': _calculateMartinRatio(),
    };
  }
  
  double _calculateSterlingRatio() {
    final avgReturn = annualizedReturn / 100;
    final avgDrawdown = _calculateAverageDrawdown();
    return avgDrawdown > 0 ? avgReturn / avgDrawdown : 0;
  }
  
  double _calculateBurkeRatio() {
    final avgReturn = annualizedReturn / 100;
    final squaredDrawdowns = _calculateSquaredDrawdowns();
    return squaredDrawdowns > 0 ? avgReturn / sqrt(squaredDrawdowns) : 0;
  }
  
  double _calculateMartinRatio() {
    final avgReturn = annualizedReturn / 100;
    final ulcerIndex = _calculateUlcerIndex();
    return ulcerIndex > 0 ? avgReturn / ulcerIndex : 0;
  }
  
  // ==================== MONTHLY & YEARLY ANALYSIS ====================
  
  Map<int, Map<int, double>> get monthlyReturns {
    final result = <int, Map<int, double>>{};
    
    for (var i = 0; i < _dates.length; i++) {
      final date = _dates[i];
      final year = date.year;
      final month = date.month;
      
      if (!result.containsKey(year)) {
        result[year] = {};
      }
      
      // Calculate monthly return
      if (i > 0 && _dates[i - 1].month != month) {
        final startValue = _equityCurve[i - 1];
        final endValue = _equityCurve[i];
        result[year]![month] = ((endValue - startValue) / startValue) * 100;
      }
    }
    
    return result;
  }
  
  Map<int, double> get yearlyReturns {
    final result = <int, double>{};
    var startValue = _equityCurve.first;
    var currentYear = _dates.first.year;
    
    for (var i = 1; i < _dates.length; i++) {
      if (_dates[i].year != currentYear) {
        final endValue = _equityCurve[i - 1];
        result[currentYear] = ((endValue - startValue) / startValue) * 100;
        startValue = endValue;
        currentYear = _dates[i].year;
      }
    }
    
    // Last year
    final endValue = _equityCurve.last;
    result[currentYear] = ((endValue - startValue) / startValue) * 100;
    
    return result;
  }
  
  Map<String, double> get rollingReturns {
    final rolling30 = <double>[];
    final rolling60 = <double>[];
    final rolling90 = <double>[];
    
    for (var i = 30; i < _returns.length; i++) {
      final sum30 = _returns.sublist(i - 30, i).reduce((a, b) => a + b);
      rolling30.add(sum30 * 100);
      
      if (i >= 60) {
        final sum60 = _returns.sublist(i - 60, i).reduce((a, b) => a + b);
        rolling60.add(sum60 * 100);
      }
      
      if (i >= 90) {
        final sum90 = _returns.sublist(i - 90, i).reduce((a, b) => a + b);
        rolling90.add(sum90 * 100);
      }
    }
    
    return {
      'rolling_30_avg': rolling30.isEmpty ? 0 : rolling30.reduce((a, b) => a + b) / rolling30.length,
      'rolling_30_max': rolling30.isEmpty ? 0 : rolling30.reduce((a, b) => a > b ? a : b),
      'rolling_30_min': rolling30.isEmpty ? 0 : rolling30.reduce((a, b) => a < b ? a : b),
      'rolling_60_avg': rolling60.isEmpty ? 0 : rolling60.reduce((a, b) => a + b) / rolling60.length,
      'rolling_90_avg': rolling90.isEmpty ? 0 : rolling90.reduce((a, b) => a + b) / rolling90.length,
    };
  }
  
  // ==================== BENCHMARK COMPARISON ====================
  
  Map<String, double> compareToBenchmark(List<double> benchmarkReturns) {
    if (benchmarkReturns.isEmpty || _returns.isEmpty) return {};
    
    final excessReturns = <double>[];
    for (var i = 0; i < min(_returns.length, benchmarkReturns.length); i++) {
      excessReturns.add(_returns[i] - benchmarkReturns[i]);
    }
    
    final alpha = _calculateAlpha(benchmarkReturns);
    final beta = _calculateBeta(benchmarkReturns);
    final trackingError = _calculateTrackingError(benchmarkReturns);
    final informationRatio = trackingError > 0 ? alpha / trackingError : 0;
    
    return {
      'alpha': alpha * 100,
      'beta': beta,
      'tracking_error': trackingError * 100,
      'information_ratio': informationRatio,
      'relative_return': (excessReturns.reduce((a, b) => a + b)) * 100,
      'upside_capture': _calculateUpsideCapture(benchmarkReturns),
      'downside_capture': _calculateDownsideCapture(benchmarkReturns),
    };
  }
  
  double _calculateAlpha(List<double> benchmarkReturns) {
    final beta = _calculateBeta(benchmarkReturns);
    final portfolioReturn = annualizedReturn / 100;
    final benchmarkReturn = _calculateBenchmarkReturn(benchmarkReturns);
    final riskFreeRate = 0.02;
    
    return portfolioReturn - (riskFreeRate + beta * (benchmarkReturn - riskFreeRate));
  }
  
  double _calculateBeta(List<double> benchmarkReturns) {
    if (_returns.length != benchmarkReturns.length) return 0;
    
    final cov = _calculateCovariance(_returns, benchmarkReturns);
    final varBenchmark = _calculateVariance(benchmarkReturns);
    
    return varBenchmark > 0 ? cov / varBenchmark : 0;
  }
  
  double _calculateUpsideCapture(List<double> benchmarkReturns) {
    var portfolioUpside = 0.0;
    var benchmarkUpside = 0.0;
    
    for (var i = 0; i < min(_returns.length, benchmarkReturns.length); i++) {
      if (benchmarkReturns[i] > 0) {
        portfolioUpside += _returns[i];
        benchmarkUpside += benchmarkReturns[i];
      }
    }
    
    return benchmarkUpside > 0 ? (portfolioUpside / benchmarkUpside) * 100 : 0;
  }
  
  double _calculateDownsideCapture(List<double> benchmarkReturns) {
    var portfolioDownside = 0.0;
    var benchmarkDownside = 0.0;
    
    for (var i = 0; i < min(_returns.length, benchmarkReturns.length); i++) {
      if (benchmarkReturns[i] < 0) {
        portfolioDownside += _returns[i];
        benchmarkDownside += benchmarkReturns[i];
      }
    }
    
    return benchmarkDownside < 0 ? (portfolioDownside / benchmarkDownside) * 100 : 0;
  }
  
  // ==================== DISTRIBUTION ANALYSIS ====================
  
  Map<String, dynamic> get returnDistribution {
    final sortedReturns = List<double>.from(_returns)..sort();
    
    return {
      'mean': _returns.reduce((a, b) => a + b) / _returns.length * 100,
      'median': sortedReturns[sortedReturns.length ~/ 2] * 100,
      'std_dev': volatility / 100,
      'skewness': _calculateSkewness(),
      'kurtosis': _calculateKurtosis(),
      'percentile_5': sortedReturns[(sortedReturns.length * 0.05).floor()] * 100,
      'percentile_25': sortedReturns[(sortedReturns.length * 0.25).floor()] * 100,
      'percentile_75': sortedReturns[(sortedReturns.length * 0.75).floor()] * 100,
      'percentile_95': sortedReturns[(sortedReturns.length * 0.95).floor()] * 100,
    };
  }
  
  double _calculateSkewness() {
    final mean = _returns.reduce((a, b) => a + b) / _returns.length;
    final std = volatility / 100;
    if (std == 0) return 0;
    
    final cubed = _returns.map((r) => pow((r - mean) / std, 3)).toList();
    return cubed.reduce((a, b) => a + b) / _returns.length;
  }
  
  double _calculateKurtosis() {
    final mean = _returns.reduce((a, b) => a + b) / _returns.length;
    final std = volatility / 100;
    if (std == 0) return 0;
    
    final fourth = _returns.map((r) => pow((r - mean) / std, 4)).toList();
    return fourth.reduce((a, b) => a + b) / _returns.length - 3;
  }
  
  // ==================== CONSECUTIVE PERFORMANCE ====================
  
  Map<String, int> get consecutiveStats {
    var currentWinStreak = 0;
    var maxWinStreak = 0;
    var currentLossStreak = 0;
    var maxLossStreak = 0;
    
    for (var r in _returns) {
      if (r > 0) {
        currentWinStreak++;
        currentLossStreak = 0;
        if (currentWinStreak > maxWinStreak) maxWinStreak = currentWinStreak;
      } else if (r < 0) {
        currentLossStreak++;
        currentWinStreak = 0;
        if (currentLossStreak > maxLossStreak) maxLossStreak = currentLossStreak;
      } else {
        currentWinStreak = 0;
        currentLossStreak = 0;
      }
    }
    
    return {
      'max_win_streak': maxWinStreak,
      'max_loss_streak': maxLossStreak,
    };
  }
  
  // ==================== TIME-BASED ANALYSIS ====================
  
  Map<String, double> get intradayAnalysis {
    // This would require tick data
    return {
      'best_hour': 0,
      'worst_hour': 0,
      'best_day': 0,
      'worst_day': 0,
    };
  }
  
  Map<String, double> get seasonalAnalysis {
    final monthly = monthlyReturns;
    final monthlyAverages = <int, List<double>>{};
    
    for (var yearMap in monthly.values) {
      for (var entry in yearMap.entries) {
        monthlyAverages.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }
    
    final bestMonth = monthlyAverages.entries
        .map((e) => MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .reduce((a, b) => a.value > b.value ? a : b).key;
    
    final worstMonth = monthlyAverages.entries
        .map((e) => MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .reduce((a, b) => a.value < b.value ? a : b).key;
    
    return {
      'best_month': bestMonth.toDouble(),
      'worst_month': worstMonth.toDouble(),
      'q1_return': _getQuarterlyReturn(1),
      'q2_return': _getQuarterlyReturn(2),
      'q3_return': _getQuarterlyReturn(3),
      'q4_return': _getQuarterlyReturn(4),
    };
  }
  
  double _getQuarterlyReturn(int quarter) {
    var totalReturn = 0.0;
    var count = 0;
    
    for (var i = 0; i < _dates.length; i++) {
      final month = _dates[i].month;
      final quarterMonth = ((month - 1) ~/ 3) + 1;
      
      if (quarterMonth == quarter && i > 0) {
        final return_ = (_equityCurve[i] - _equityCurve[i - 1]) / _equityCurve[i - 1];
        totalReturn += return_;
        count++;
      }
    }
    
    return count > 0 ? (totalReturn / count) * 100 : 0;
  }
  
  // ==================== HELPER METHODS ====================
  
  double _getTradingYears() {
    if (_dates.isEmpty) return 1;
    final days = _dates.last.difference(_dates.first).inDays;
    return max(1.0, days / 365.0);
  }
  
  double _calculateDownsideDeviation() {
    final negativeReturns = _returns.where((r) => r < 0).toList();
    if (negativeReturns.isEmpty) return 0;
    
    final mean = negativeReturns.reduce((a, b) => a + b) / negativeReturns.length;
    final squared = negativeReturns.map((r) => pow(r - mean, 2)).toList();
    final variance = squared.reduce((a, b) => a + b) / negativeReturns.length;
    
    return sqrt(variance) * sqrt(252);
  }
  
  double _calculateAverageDrawdown() {
    var peak = _equityCurve.first;
    var totalDrawdown = 0.0;
    var drawdownCount = 0;
    var inDrawdown = false;
    
    for (var value in _equityCurve) {
      if (value > peak) {
        peak = value;
        inDrawdown = false;
      } else {
        if (!inDrawdown) {
          inDrawdown = true;
          drawdownCount++;
        }
        final drawdown = (peak - value) / peak;
        totalDrawdown += drawdown;
      }
    }
    
    return drawdownCount > 0 ? totalDrawdown / drawdownCount : 0;
  }
  
  double _calculateSquaredDrawdowns() {
    var peak = _equityCurve.first;
    var sumSquared = 0.0;
    
    for (var value in _equityCurve) {
      if (value > peak) {
        peak = value;
      } else {
        final drawdown = (peak - value) / peak;
        sumSquared += drawdown * drawdown;
      }
    }
    
    return sumSquared;
  }
  
  double _calculateUlcerIndex() {
    var peak = _equityCurve.first;
    var sumSquared = 0.0;
    
    for (var value in _equityCurve) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / peak;
      sumSquared += drawdown * drawdown;
    }
    
    return sqrt(sumSquared / _equityCurve.length);
  }
  
  double _findPeak() {
    return _equityCurve.reduce((a, b) => a > b ? a : b);
  }
  
  double _calculateRecoveryDays() {
    final peak = _findPeak();
    var peakIndex = _equityCurve.indexOf(peak);
    var recoveryDays = 0;
    
    for (var i = peakIndex; i < _equityCurve.length; i++) {
      if (_equityCurve[i] >= peak) {
        recoveryDays = i - peakIndex;
        break;
      }
    }
    
    return recoveryDays.toDouble();
  }
  
  double _calculateCovariance(List<double> x, List<double> y) {
    final meanX = x.reduce((a, b) => a + b) / x.length;
    final meanY = y.reduce((a, b) => a + b) / y.length;
    
    var cov = 0.0;
    for (var i = 0; i < x.length; i++) {
      cov += (x[i] - meanX) * (y[i] - meanY);
    }
    
    return cov / x.length;
  }
  
  double _calculateVariance(List<double> x) {
    final mean = x.reduce((a, b) => a + b) / x.length;
    final squared = x.map((v) => pow(v - mean, 2)).toList();
    return squared.reduce((a, b) => a + b) / x.length;
  }
  
  double _calculateTrackingError(List<double> benchmark) {
    final differences = <double>[];
    for (var i = 0; i < min(_returns.length, benchmark.length); i++) {
      differences.add(_returns[i] - benchmark[i]);
    }
    final std = _calculateVariance(differences);
    return sqrt(std);
  }
  
  double _calculateBenchmarkReturn(List<double> benchmarkReturns) {
    var cumulative = 1.0;
    for (var r in benchmarkReturns) {
      cumulative *= (1 + r);
    }
    return pow(cumulative, 1 / (benchmarkReturns.length / 252)) - 1;
  }
}

