// screens/item_detail_screen.dart
import 'package:flutter/material.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.item['image_path'] != null
        ? 'http://127.0.0.1:5000${widget.item['image_path']}'
        : '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.item['name'] ?? 'Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, height: 200)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.image_not_supported)),
              ),
            SizedBox(height: 16),
            Text(
              widget.item['description'] ?? 'No description provided.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                ),
                Text(
                  quantity.toString(),
                  style: TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  ...widget.item,
                  'quantity': quantity,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("Add \$quantity to Cart", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
