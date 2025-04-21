// screens/cart_screen.dart
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const CartScreen({super.key, required this.cart, required this.onCartUpdated});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> localCart;

  @override
  void initState() {
    super.initState();
    localCart = List<Map<String, dynamic>>.from(widget.cart);
  }

  void removeItem(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Item'),
        content: Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                localCart.removeAt(index);
              });
              widget.onCartUpdated(localCart);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = localCart.fold(0, (sum, item) => sum + (item['quantity'] * double.parse(item['price'].toString())));

    return Scaffold(
      appBar: AppBar(title: Text("Your Cart")),
      body: localCart.isEmpty
          ? Center(child: Text("Your cart is empty."))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: localCart.length,
                    itemBuilder: (context, index) {
                      final item = localCart[index];
                      final imageUrl = item['image_path'] != null
                          ? 'http://127.0.0.1:5000${item['image_path']}'
                          : '';
                      return ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image),
                        title: Text(item['name']),
                        subtitle: Text("Qty: ${item['quantity']}"),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("UGX ${item['price']}"),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Total: UGX ${total.toStringAsFixed(0)}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Order placed successfully!")),
                          );
                          setState(() => localCart.clear());
                          widget.onCartUpdated(localCart);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Place Order", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
