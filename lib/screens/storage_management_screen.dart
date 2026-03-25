// lib/screens/storage_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chart_provider.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({Key? key}) : super(key: key);

  @override
  _StorageManagementScreenState createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool _isOptimizing = false;
  bool _isClearing = false;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    final provider = Provider.of<ChartProvider>(context, listen: false);
    await provider.getStorageStats();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
      ),
      body: Consumer<ChartProvider>(
        builder: (context, provider, _) {
          final stats = provider.cacheStats;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Storage Usage Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Storage Usage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Total Bars',
                        '${stats['total_bars'] ?? 0}',
                        Icons.show_chart,
                      ),
                      _buildStatRow(
                        'Total Symbols',
                        '${stats['total_symbols'] ?? 0}',
                        Icons.category,
                      ),
                      _buildStatRow(
                        'Database Size',
                        _formatBytes(stats['database_size_bytes'] ?? 0),
                        Icons.storage,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Storage Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Clear old data
                      ListTile(
                        leading: const Icon(Icons.delete_sweep),
                        title: const Text('Clear Old Data'),
                        subtitle: const Text('Remove data older than 30 days'),
                        trailing: _isClearing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward),
                        onTap: _showClearDataDialog,
                      ),
                      
                      const Divider(),
                      
                      // Optimize database
                      ListTile(
                        leading: const Icon(Icons.optimize),
                        title: const Text('Optimize Database'),
                        subtitle: const Text('Vacuum and reindex database'),
                        trailing: _isOptimizing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward),
                        onTap: _optimizeDatabase,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cache Settings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cache Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Enable Background Prefetch'),
                        subtitle: const Text('Automatically prefetch data for watchlist symbols'),
                        value: true, // Add state management
                        onChanged: (value) {
                          // Implement prefetch toggle
                        },
                      ),
                      
                      SwitchListTile(
                        title: const Text('Auto-clean Old Data'),
                        subtitle: const Text('Automatically remove data older than 30 days'),
                        value: true, // Add state management
                        onChanged: (value) {
                          // Implement auto-clean toggle
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  Future<void> _showClearDataDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select how many days of data to keep:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: 30,
              items: [7, 14, 30, 60, 90].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('Keep last $days days'),
                );
              }).toList(),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() => _isClearing = true);
      
      final provider = Provider.of<ChartProvider>(context, listen: false);
      await provider.clearOldData(result);
      
      setState(() => _isClearing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared data older than $result days'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadStats();
    }
  }
  
  Future<void> _optimizeDatabase() async {
    setState(() => _isOptimizing = true);
    
    final provider = Provider.of<ChartProvider>(context, listen: false);
    await provider.optimizeStorage();
    
    setState(() => _isOptimizing = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database optimized successfully'),
        backgroundColor: Colors.green,
      ),
    );
    
    await _loadStats();
  }
}
