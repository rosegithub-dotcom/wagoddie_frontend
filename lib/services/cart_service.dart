// services/cart_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  final String description;
  final String image;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.image,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image': image,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      description: json['description'],
      image: json['image'],
      quantity: json['quantity'],
    );
  }
}

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  
  CartService() {
    // Load cart items from local storage when service is initialized
    _loadCartFromStorage();
  }

  // Add item to cart
  void addToCart(CartItem item) {
    final existingIndex = _items.indexWhere((existingItem) => existingItem.id == item.id);
    
    if (existingIndex >= 0) {
      // Update quantity if item exists
      final updatedItem = CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        description: item.description,
        image: item.image,
        quantity: _items[existingIndex].quantity + 1,
      );
      
      _items[existingIndex] = updatedItem;
    } else {
      _items.add(item);
    }
    
    // Save changes to local storage
    _saveCartToStorage();
    notifyListeners();
  }
  
  // Update item quantity
  void updateQuantity(int id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    
    if (index >= 0) {
      if (quantity <= 0) {
        removeFromCart(id);
      } else {
        final item = _items[index];
        final updatedItem = CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          description: item.description,
          image: item.image,
          quantity: quantity,
        );
        
        _items[index] = updatedItem;
        _saveCartToStorage();
        notifyListeners();
      }
    }
  }
  
  // Remove item from cart
  void removeFromCart(int id) {
    _items.removeWhere((item) => item.id == id);
    _saveCartToStorage();
    notifyListeners();
  }
  
  // Clear the cart
  void clearCart() {
    _items = [];
    _saveCartToStorage();
    notifyListeners();
  }
  
  // Get total amount
  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  // Get item count
  int get itemCount {
    return _items.length;
  }
  
  // Save cart to local storage
  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items.map((item) => item.toJson()).toList();
      await prefs.setString('cart_items', jsonEncode(cartData));
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
  
  // Load cart from local storage
  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items');
      
      if (cartData != null && cartData.isNotEmpty) {
        final List<dynamic> decodedData = jsonDecode(cartData);
        _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }
  
  // Submit order to API
  Future<bool> placeOrder(String deliveryAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      
      if (userData == null) {
        return false;
      }
      
      final user = jsonDecode(userData);
      
      final orderRequests = _items.map((item) async {
        final orderData = {
          'restaurant_id': 1,
          'deliveryInformation': deliveryAddress.isNotEmpty ? deliveryAddress : 'default address',
          'quantity': item.quantity,
          'total_amount': item.price,
          'status': 'Received',
          'item_id': item.id,
        };
        
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/api/v2/order1/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${user['access_token']}',
          },
          body: jsonEncode(orderData),
        );
        
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Failed to place order');
        }
      }).toList();
      
      await Future.wait(orderRequests);
      clearCart();
      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }
}