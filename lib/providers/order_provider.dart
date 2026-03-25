import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/broker_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _orderHistory = [];
  Map<String, String> _brokerConnections = {};
  
  List<Order> get orders => _orders;
  List<Order> get activeOrders => _orders.where((o) => o.isActive).toList();
  List<Order> get orderHistory => _orderHistory;
  Map<String, String> get brokerConnections => _brokerConnections;

  OrderProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    // Load orders from local storage
    // This is a placeholder - implement actual loading
    _orders = [];
    _orderHistory = [];
    notifyListeners();
  }

  Future<void> placeOrder(Order order) async {
    try {
      // Validate order
      final validationError = validateOrder(order);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Send order to broker
      final broker = BrokerService.getBroker(order.brokerId);
      final result = await broker.placeOrder(order);
      
      if (result.success) {
        order.status = OrderStatus.pending;
        _orders.add(order);
        saveOrders();
        notifyListeners();
        
        // Show success notification
        debugPrint('Order placed successfully: ${order.id}');
      } else {
        order.status = OrderStatus.rejected;
        throw Exception(result.error);
      }
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }

  String? validateOrder(Order order) {
    if (order.symbol.isEmpty) return 'Symbol is required';
    if (order.quantity <= 0) return 'Quantity must be greater than 0';
    
    if (order.type == OrderType.limit && order.price == null) {
      return 'Limit price is required for limit orders';
    }
    
    if (order.type == OrderType.stop && order.stopPrice == null) {
      return 'Stop price is required for stop orders';
    }
    
    if (order.type == OrderType.stopLimit && (order.stopPrice == null || order.price == null)) {
      return 'Stop price and limit price are required for stop-limit orders';
    }
    
    return null;
  }

  Future<void> cancelOrder(String orderId) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    
    if (!order.isActive) {
      throw Exception('Order cannot be cancelled - already ${order.status}');
    }
    
    try {
      final broker = BrokerService.getBroker(order.brokerId);
      final result = await broker.cancelOrder(orderId);
      
      if (result.success) {
        order.status = OrderStatus.cancelled;
        order.updatedAt = DateTime.now();
        moveToHistory(order);
        notifyListeners();
      } else {
        throw Exception(result.error);
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      rethrow;
    }
  }

  Future<void> modifyOrder(String orderId, {double? quantity, double? price, double? stopPrice}) async {
    final order = _orders.firstWhere((o) => o.id == orderId);
    
    if (!order.isActive) {
      throw Exception('Cannot modify order - already ${order.status}');
    }
    
    try {
      final broker = BrokerService.getBroker(order.brokerId);
      final result = await broker.modifyOrder(orderId, quantity: quantity, price: price, stopPrice: stopPrice);
      
      if (result.success) {
        if (quantity != null) order.quantity = quantity;
        if (price != null) order.price = price;
        if (stopPrice != null) order.stopPrice = stopPrice;
        order.updatedAt = DateTime.now();
        notifyListeners();
      } else {
        throw Exception(result.error);
      }
    } catch (e) {
      debugPrint('Error modifying order: $e');
      rethrow;
    }
  }

  void updateOrderStatus(String orderId, OrderStatus status, {double? filledQuantity, double? averagePrice}) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    order.status = status;
    order.updatedAt = DateTime.now();
    
    if (filledQuantity != null) order.filledQuantity = filledQuantity;
    if (averagePrice != null) order.averagePrice = averagePrice;
    
    if (!order.isActive) {
      moveToHistory(order);
    }
    
    notifyListeners();
  }

  void moveToHistory(Order order) {
    _orders.remove(order);
    _orderHistory.add(order);
    saveOrders();
  }

  Future<void> saveOrders() async {
    // Save orders to local storage
    // Implement with Hive or SQLite
  }

  void connectBroker(String brokerId, Map<String, dynamic> credentials) async {
    try {
      await BrokerService.connectBroker(brokerId, credentials);
      _brokerConnections[brokerId] = 'connected';
      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting to broker: $e');
      rethrow;
    }
  }

  void disconnectBroker(String brokerId) {
    BrokerService.disconnectBroker(brokerId);
    _brokerConnections.remove(brokerId);
    notifyListeners();
  }
}
