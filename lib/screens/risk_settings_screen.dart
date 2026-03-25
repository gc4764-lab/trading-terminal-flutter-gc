import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/risk_settings.dart';
import '../providers/risk_provider.dart';

class RiskSettingsScreen extends StatefulWidget {
  const RiskSettingsScreen({Key? key}) : super(key: key);

  @override
  _RiskSettingsScreenState createState() => _RiskSettingsScreenState();
}

class _RiskSettingsScreenState extends State<RiskSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return Consumer<RiskProvider>(
      builder: (context, provider, _) {
        final settings = provider.settings;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Position Sizing
                _buildSection(
                  title: 'Position Sizing',
                  icon: Icons.timeline,
                  children: [
                    _buildSliderSetting(
                      label: 'Maximum Position Size (% of Account)',
                      value: settings.maxPositionSizePercent,
                      min: 0,
                      max: 100,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(maxPositionSizePercent: value),
                        );
                      },
                      formatter: (v) => '${v.toStringAsFixed(1)}%',
                    ),
                    _buildSliderSetting(
                      label: 'Maximum Risk Per Trade (%)',
                      value: settings.maxRiskPerTradePercent,
                      min: 0,
                      max: 10,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(maxRiskPerTradePercent: value),
                        );
                      },
                      formatter: (v) => '${v.toStringAsFixed(1)}%',
                    ),
                    _buildSliderSetting(
                      label: 'Maximum Daily Loss (%)',
                      value: settings.maxDailyLossPercent,
                      min: 0,
                      max: 20,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(maxDailyLossPercent: value),
                        );
                      },
                      formatter: (v) => '${v.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Stop Loss & Take Profit
                _buildSection(
                  title: 'Stop Loss & Take Profit',
                  icon: Icons.pause_circle_filled,
                  children: [
                    _buildSliderSetting(
                      label: 'Default Stop Loss (%)',
                      value: settings.defaultStopLossPercent,
                      min: 0,
                      max: 20,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(defaultStopLossPercent: value),
                        );
                      },
                      formatter: (v) => '${v.toStringAsFixed(1)}%',
                    ),
                    _buildSliderSetting(
                      label: 'Default Take Profit (%)',
                      value: settings.defaultTakeProfitPercent,
                      min: 0,
                      max: 50,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(defaultTakeProfitPercent: value),
                        );
                      },
                      formatter: (v) => '${v.toStringAsFixed(1)}%',
                    ),
                    SwitchListTile(
                      title: const Text('Trailing Stop Loss'),
                      subtitle: const Text('Automatically adjust stop loss as price moves in your favor'),
                      value: settings.trailingStopEnabled,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(trailingStopEnabled: value),
                        );
                      },
                    ),
                    if (settings.trailingStopEnabled)
                      _buildSliderSetting(
                        label: 'Trailing Stop Distance (%)',
                        value: settings.trailingStopDistance,
                        min: 0,
                        max: 10,
                        onChanged: (value) {
                          provider.updateSettings(
                            settings.copyWith(trailingStopDistance: value),
                          );
                        },
                        formatter: (v) => '${v.toStringAsFixed(1)}%',
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Trading Hours
                _buildSection(
                  title: 'Trading Hours',
                  icon: Icons.access_time,
                  children: [
                    SwitchListTile(
                      title: const Text('Restrict Trading Hours'),
                      value: settings.restrictTradingHours,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(restrictTradingHours: value),
                        );
                      },
                    ),
                    if (settings.restrictTradingHours) ...[
                      _buildTimePicker(
                        label: 'Start Time',
                        time: settings.tradingStartTime,
                        onChanged: (time) {
                          provider.updateSettings(
                            settings.copyWith(tradingStartTime: time),
                          );
                        },
                      ),
                      _buildTimePicker(
                        label: 'End Time',
                        time: settings.tradingEndTime,
                        onChanged: (time) {
                          provider.updateSettings(
                            settings.copyWith(tradingEndTime: time),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Symbol Restrictions
                _buildSection(
                  title: 'Symbol Restrictions',
                  icon: Icons.block,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Restricted Symbols (comma separated)',
                        border: OutlineInputBorder(),
                        helperText: 'List symbols that cannot be traded',
                      ),
                      initialValue: settings.restrictedSymbols.join(', '),
                      onChanged: (value) {
                        final symbols = value.split(',').map((s) => s.trim().toUpperCase()).toList();
                        provider.updateSettings(
                          settings.copyWith(restrictedSymbols: symbols),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Allowed Symbols (empty = all)',
                        border: OutlineInputBorder(),
                        helperText: 'If specified, only these symbols can be traded',
                      ),
                      initialValue: settings.allowedSymbols.join(', '),
                      onChanged: (value) {
                        final symbols = value.split(',').map((s) => s.trim().toUpperCase()).toList();
                        provider.updateSettings(
                          settings.copyWith(allowedSymbols: symbols),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Maximum Order Size
                _buildSection(
                  title: 'Order Limits',
                  icon: Icons.speed,
                  children: [
                    _buildTextFieldSetting(
                      label: 'Maximum Order Value (\$)',
                      value: settings.maxOrderValue?.toString() ?? '',
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(
                            maxOrderValue: value.isEmpty ? null : double.parse(value),
                          ),
                        );
                      },
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextFieldSetting(
                      label: 'Maximum Order Quantity',
                      value: settings.maxOrderQuantity?.toString() ?? '',
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(
                            maxOrderQuantity: value.isEmpty ? null : double.parse(value),
                          ),
                        );
                      },
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Risk Limits
                _buildSection(
                  title: 'Risk Limits',
                  icon: Icons.warning,
                  children: [
                    _buildSliderSetting(
                      label: 'Maximum Leverage',
                      value: settings.maxLeverage,
                      min: 1,
                      max: 100,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(maxLeverage: value),
                        );
                      },
                      formatter: (v) => '${v.toStringAsFixed(0)}x',
                    ),
                    _buildSliderSetting(
                      label: 'Maximum Open Positions',
                      value: settings.maxOpenPositions.toDouble(),
                      min: 1,
                      max: 50,
                      onChanged: (value) {
                        provider.updateSettings(
                          settings.copyWith(maxOpenPositions: value.toInt()),
                        );
                      },
                      formatter: (v) => v.toInt().toString(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      provider.saveSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Risk settings saved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Save Risk Settings'),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String Function(double) formatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              formatter(value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldSetting({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        initialValue: value,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: (val) {
          if (val != null && val.isNotEmpty) {
            if (double.tryParse(val) == null) {
              return 'Please enter a valid number';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(label),
        subtitle: Text(time.format(context)),
        trailing: const Icon(Icons.access_time),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
      ),
    );
  }
}
