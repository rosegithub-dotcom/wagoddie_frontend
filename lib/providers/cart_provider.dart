// providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class CartItem {
  final int id;
  final String name;
  final double price;
  final String imagePath;
  final int menuId;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.menuId,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imagePath: imagePath,
      menuId: menuId,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'imagePath': imagePath,
        'menuId': menuId,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    try {
      return CartItem(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name: json['name']?.toString() ?? 'Unnamed Item',
        price: json['price'] is double
            ? json['price']
            : double.parse(json['price']?.toString() ?? '0.0'),
        imagePath: json['imagePath']?.toString() ?? '',
        menuId: json['menuId'] is int 
            ? json['menuId'] 
            : int.parse(json['menuId']?.toString() ?? '0'),
        quantity: json['quantity'] is int 
            ? json['quantity'] 
            : int.parse(json['quantity']?.toString() ?? '1'),
      );
    } catch (e) {
      print('Error parsing CartItem from JSON: $e');
      // Return a default item in case of parsing errors
      return CartItem(
        id: 0,
        name: 'Error Item',
        price: 0.0,
        imagePath: '',
        menuId: 0,
        quantity: 1,
      );
    }
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  final storage = FlutterSecureStorage();

  List<CartItem> get items => List.unmodifiable(_items);

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cartJson = await storage.read(key: 'cart');
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> cartData = jsonDecode(cartJson);
        _items = cartData
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .where((item) => item.id > 0) // Filter out invalid items
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
      // Reset cart if there's an error loading
      _items = [];
      await storage.delete(key: 'cart');
    }
  }

  Future<void> _saveCart() async {
    try {
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await storage.write(key: 'cart', value: cartJson);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addItem(CartItem item) {
    try {
      // Validate item data
      if (item.id <= 0 || item.name.isEmpty || item.price < 0) {
        print('Invalid item data: ${item.toJson()}');
        return;
      }

      final index = _items.indexWhere((i) => i.id == item.id && i.menuId == item.menuId);
      if (index >= 0) {
        // Item exists, update quantity
        _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
      } else {
        // Add new item
        _items.add(item);
      }
      notifyListeners();
      _saveCart();
    } catch (e) {
      print('Error adding item to cart: $e');
    }
  }

  void removeItem(int id, int menuId) {
    try {
      _items.removeWhere((item) => item.id == id && item.menuId == menuId);
      notifyListeners();
      _saveCart();
    } catch (e) {
      print('Error removing item from cart: $e');
    }
  }

  void updateQuantity(int id, int menuId, int quantity) {
    try {
      if (quantity <= 0) {
        removeItem(id, menuId);
        return;
      }
      
      final index = _items.indexWhere((i) => i.id == id && i.menuId == menuId);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(quantity: quantity);
        notifyListeners();
        _saveCart();
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  void clearCart() {
    try {
      _items.clear();
      notifyListeners();
      _saveCart();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  double get totalPrice {
    try {
      return _items.fold(0, (sum, item) => sum + item.price * item.quantity);
    } catch (e) {
      print('Error calculating total price: $e');
      return 0.0;
    }
  }

  int get itemCount {
    try {
      return _items.fold(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      print('Error calculating item count: $e');
      return 0;
    }
  }
}
