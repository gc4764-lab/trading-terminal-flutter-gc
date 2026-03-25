// lib/widgets/economic_calendar.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EconomicEvent {
  final String name;
  final String country;
  final DateTime date;
  final String impact;
  final double? actual;
  final double? forecast;
  final double? previous;
  
  EconomicEvent({
    required this.name,
    required this.country,
    required this.date,
    required this.impact,
    this.actual,
    this.forecast,
    this.previous,
  });
  
  Color get impactColor {
    switch (impact.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
  
  String get formattedTime {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class EconomicCalendar extends StatefulWidget {
  const EconomicCalendar({Key? key}) : super(key: key);

  @override
  _EconomicCalendarState createState() => _EconomicCalendarState();
}

class _EconomicCalendarState extends State<EconomicCalendar> {
  List<EconomicEvent> _events = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadEconomicEvents();
  }
  
  Future<void> _loadEconomicEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Free economic calendar API (example using ForexFactory)
      final response = await http.get(
        Uri.parse('https://www.forexfactory.com/calendar.php'),
      );
      
      if (response.statusCode == 200) {
        // Parse the response - implement actual parsing based on the source
        _events = await _parseEconomicEvents(response.body);
      } else {
        // Use mock data for demo
        _events = _getMockEvents();
      }
    } catch (e) {
      _error = e.toString();
      _events = _getMockEvents();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<List<EconomicEvent>> _parseEconomicEvents(String html) async {
    // Implement actual parsing logic here
    // For demo, return mock data
    return _getMockEvents();
  }
  
  List<EconomicEvent> _getMockEvents() {
    final today = DateTime.now();
    return [
      EconomicEvent(
        name: 'Federal Reserve Interest Rate Decision',
        country: 'US',
        date: DateTime(today.year, today.month, today.day, 14, 0),
        impact: 'High',
        forecast: 5.5,
        previous: 5.5,
      ),
      EconomicEvent(
        name: 'Non-Farm Payrolls',
        country: 'US',
        date: DateTime(today.year, today.month, today.day, 8, 30),
        impact: 'High',
        forecast: 180,
        previous: 175,
      ),
      EconomicEvent(
        name: 'ECB Press Conference',
        country: 'EU',
        date: DateTime(today.year, today.month, today.day, 13, 45),
        impact: 'Medium',
      ),
      EconomicEvent(
        name: 'CPI Data',
        country: 'UK',
        date: DateTime(today.year, today.month, today.day, 4, 30),
        impact: 'Medium',
        forecast: 2.1,
        previous: 2.0,
      ),
      EconomicEvent(
        name: 'GDP Growth Rate',
        country: 'JP',
        date: DateTime(today.year, today.month, today.day, 23, 50),
        impact: 'Low',
        forecast: 0.4,
        previous: 0.3,
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(width: 8),
                Text(
                  'Economic Calendar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No events scheduled'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return _buildEventRow(event);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventRow(EconomicEvent event) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Text(
              event.formattedTime,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Country flag emoji placeholder
          Container(
            width: 32,
            child: Text(
              _getCountryFlag(event.country),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          
          // Impact indicator
          Container(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: event.impactColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.impact,
                  style: TextStyle(
                    fontSize: 10,
                    color: event.impactColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (event.actual != null || event.forecast != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (event.actual != null)
                          _buildMetric('Actual', event.actual!),
                        if (event.forecast != null)
                          _buildMetric('Forecast', event.forecast!),
                        if (event.previous != null)
                          _buildMetric('Previous', event.previous!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetric(String label, double value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
  
  String _getCountryFlag(String country) {
    // Return emoji flags for countries
    switch (country) {
      case 'US':
        return '🇺🇸';
      case 'EU':
        return '🇪🇺';
      case 'UK':
        return '🇬🇧';
      case 'JP':
        return '🇯🇵';
      case 'CN':
        return '🇨🇳';
      default:
        return '🌍';
    }
  }
}
