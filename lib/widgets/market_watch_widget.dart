import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/symbol.dart';
import '../providers/market_data_provider.dart';
import '../providers/watchlist_provider.dart';

class MarketWatchWidget extends StatelessWidget {
  final Function(String) onSymbolSelected;
  
  const MarketWatchWidget({
    Key? key,
    required this.onSymbolSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildWatchlistTabs(),
          Expanded(
            child: _buildSymbolList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistTabs() {
    return Consumer<WatchlistProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.watchlists.length,
            itemBuilder: (context, index) {
              final watchlist = provider.watchlists[index];
              final isActive = provider.activeWatchlistIndex == index;
              
              return GestureDetector(
                onTap: () => provider.setActiveWatchlist(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        Text(watchlist.name),
                        if (!watchlist.isDefault) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              provider.removeWatchlist(watchlist.id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSymbolList() {
    return Consumer2<WatchlistProvider, MarketDataProvider>(
      builder: (context, watchlistProvider, marketProvider, _) {
        final symbols = watchlistProvider.activeWatchlist.symbols;
        
        if (symbols.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No symbols in watchlist'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showAddSymbolDialog,
                  child: const Text('Add Symbol'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: symbols.length,
          itemBuilder: (context, index) {
            final symbol = marketProvider.getSymbol(symbols[index]);
            
            if (symbol == null) {
              return const SizedBox.shrink();
            }
            
            return _buildSymbolTile(symbol);
          },
        );
      },
    );
  }

  Widget _buildSymbolTile(Symbol symbol) {
    return ListTile(
      dense: true,
      onTap: () => onSymbolSelected(symbol.symbol),
      title: Row(
        children: [
          Text(
            symbol.symbol,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            symbol.name,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Text(
        '${symbol.exchange} | ${symbol.type.toUpperCase()}',
        style: const TextStyle(fontSize: 10),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${symbol.lastPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${symbol.formattedChange} (${symbol.formattedChangePercent})',
            style: TextStyle(
              color: symbol.priceColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSymbolDialog() {
    // Implement add symbol dialog
  }
}
