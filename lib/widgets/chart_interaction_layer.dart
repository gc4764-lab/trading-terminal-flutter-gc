// lib/widgets/chart_interaction_layer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/alert.dart';
import '../providers/order_provider.dart';
import '../providers/alert_provider.dart';
import '../services/chart_interaction_service.dart';

class ChartInteractionLayer extends StatefulWidget {
  final String symbol;
  final List<ChartData> data;
  final double currentPrice;
  final Function(Offset) onTap;
  final Function(Offset, Offset) onDrag;
  
  const ChartInteractionLayer({
    Key? key,
    required this.symbol,
    required this.data,
    required this.currentPrice,
    required this.onTap,
    required this.onDrag,
  }) : super(key: key);

  @override
  _ChartInteractionLayerState createState() => _ChartInteractionLayerState();
}

class _ChartInteractionLayerState extends State<ChartInteractionLayer> {
  final ChartInteractionService _interactionService = ChartInteractionService();
  List<ChartAnnotation> _annotations = [];
  ChartAnnotation? _selectedAnnotation;
  Offset? _dragStart;
  InteractionMode _mode = InteractionMode.normal;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onLongPress: _handleLongPress,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        painter: ChartAnnotationPainter(
          annotations: _annotations,
          selectedAnnotation: _selectedAnnotation,
        ),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
  
  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _dragStart = details.localPosition;
    });
  }
  
  void _handleTapUp(TapUpDetails details) {
    final endPosition = details.localPosition;
    
    if (_dragStart != null && (_dragStart! - endPosition).distance < 5) {
      // Single tap
      _showPriceMenu(endPosition);
    }
    
    _dragStart = null;
  }
  
  void _handleLongPress(LongPressStartDetails details) {
    _showOrderDialog(details.localPosition);
  }
  
  void _handlePanStart(DragStartDetails details) {
    if (_mode == InteractionMode.drawing) {
      _dragStart = details.localPosition;
    }
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_mode == InteractionMode.drawing && _dragStart != null) {
      final current = details.localPosition;
      
      // Draw line while dragging
      setState(() {
        _annotations.add(ChartAnnotation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AnnotationType.trendLine,
          points: [_dragStart!, current],
          color: Colors.yellow,
        ));
        _dragStart = current;
      });
    }
  }
  
  void _handlePanEnd(DragEndDetails details) {
    _dragStart = null;
  }
  
  void _showPriceMenu(Offset position) {
    final price = _getPriceAtPosition(position);
    if (price == null) return;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'order',
          child: Row(
            children: const [
              Icon(Icons.shopping_cart, size: 20),
              SizedBox(width: 8),
              Text('Place Order at \$${price.toStringAsFixed(2)}'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'alert',
          child: Row(
            children: const [
              Icon(Icons.notifications, size: 20),
              SizedBox(width: 8),
              Text('Create Alert at \$${price.toStringAsFixed(2)}'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'alert_order',
          child: Row(
            children: const [
              Icon(Icons.notifications_active, size: 20),
              SizedBox(width: 8),
              Text('Create Alert-based Order at \$${price.toStringAsFixed(2)}'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'draw_line',
          child: const Row(
            children: [
              Icon(Icons.show_chart, size: 20),
              SizedBox(width: 8),
              Text('Draw Trend Line'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'draw_horizontal',
          child: const Row(
            children: [
              Icon(Icons.horizontal_rule, size: 20),
              SizedBox(width: 8),
              Text('Draw Horizontal Line'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'fibonacci',
          child: const Row(
            children: [
              Icon(Icons.timeline, size: 20),
              SizedBox(width: 8),
              Text('Draw Fibonacci Retracement'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value, price, position);
      }
    });
  }
  
  void _handleMenuSelection(String value, double price, Offset position) {
    switch (value) {
      case 'order':
        _showQuickOrderDialog(price);
        break;
      case 'alert':
        _showCreateAlertDialog(price);
        break;
      case 'alert_order':
        _showAlertOrderDialog(price);
        break;
      case 'draw_line':
        _startDrawing(AnnotationType.trendLine);
        break;
      case 'draw_horizontal':
        _addHorizontalLine(price);
        break;
      case 'fibonacci':
        _addFibonacciRetracement(position);
        break;
    }
  }
  
  void _showQuickOrderDialog(double price) {
    showDialog(
      context: context,
      builder: (context) => QuickOrderDialog(
        symbol: widget.symbol,
        defaultPrice: price,
        currentPrice: widget.currentPrice,
      ),
    );
  }
  
  void _showCreateAlertDialog(double price) {
    showDialog(
      context: context,
      builder: (context) => CreateAlertFromChartDialog(
        symbol: widget.symbol,
        price: price,
        currentPrice: widget.currentPrice,
      ),
    );
  }
  
  void _showAlertOrderDialog(double price) {
    showDialog(
      context: context,
      builder: (context) => AlertOrderDialog(
        symbol: widget.symbol,
        triggerPrice: price,
        currentPrice: widget.currentPrice,
      ),
    );
  }
  
  void _showOrderDialog(Offset position) {
    final price = _getPriceAtPosition(position);
    if (price == null) return;
    
    _showQuickOrderDialog(price);
  }
  
  void _startDrawing(AnnotationType type) {
    setState(() {
      _mode = InteractionMode.drawing;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Click and drag to draw on chart'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _addHorizontalLine(double price) {
    setState(() {
      _annotations.add(ChartAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AnnotationType.horizontalLine,
        points: [Offset(0, price), Offset(1, price)],
        color: Colors.cyan,
        value: price,
      ));
    });
  }
  
  void _addFibonacciRetracement(Offset startPosition) {
    // Show Fibonacci retracement dialog
    showDialog(
      context: context,
      builder: (context) => FibonacciDialog(
        onConfirm: (startPrice, endPrice) {
          setState(() {
            _annotations.add(ChartAnnotation(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: AnnotationType.fibonacci,
              points: [Offset(0, startPrice), Offset(1, endPrice)],
              color: Colors.purple,
            ));
          });
        },
      ),
    );
  }
  
  double? _getPriceAtPosition(Offset position) {
    if (widget.data.isEmpty) return null;
    
    // Convert screen position to price
    final maxPrice = widget.data.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final minPrice = widget.data.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;
    
    // Assuming chart takes full height
    final chartHeight = MediaQuery.of(context).size.height - 200;
    final price = maxPrice - (position.dy / chartHeight) * priceRange;
    
    return price.clamp(minPrice, maxPrice);
  }
  
  void addAnnotation(ChartAnnotation annotation) {
    setState(() {
      _annotations.add(annotation);
    });
  }
  
  void removeAnnotation(String id) {
    setState(() {
      _annotations.removeWhere((a) => a.id == id);
    });
  }
  
  void clearAnnotations() {
    setState(() {
      _annotations.clear();
    });
  }
  
  void setInteractionMode(InteractionMode mode) {
    setState(() {
      _mode = mode;
    });
  }
}

enum InteractionMode {
  normal,
  drawing,
  measuring,
  selecting,
}

enum AnnotationType {
  trendLine,
  horizontalLine,
  verticalLine,
  fibonacci,
  supportResistance,
  alertLine,
  orderLine,
}

