// screens/beverages_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BeverageScreen extends StatefulWidget {
  final int menuId; // Pass the menu_id for Beverages (e.g., 1)
  final String categoryName; // Pass the category name for display

  const BeverageScreen({super.key, required this.menuId, required this.categoryName});

  @override
  _BeverageScreenState createState() => _BeverageScreenState();
}

class _BeverageScreenState extends State<BeverageScreen> {
  final storage = FlutterSecureStorage();
  List<dynamic> items = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'access_token');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/v2/item_bp/${widget.menuId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch items response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          // Expecting {"category": "Beverages", "items": [...]}
          items = responseData['items'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load items: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        errorMessage = 'Failed to fetch items: $e';
        isLoading = false;
      });
    }
  }

  String formatImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/api/v2/menus/images/')) {
      return 'http://127.0.0.1:5000$imagePath';
    }
    return 'http://127.0.0.1:5000/api/v2/menus/images/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFACD), // lightYellow
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color.fromARGB(255, 235, 128, 6), // primaryOrange
        foregroundColor: const Color(0xFFFFFFFF), // primaryYellow
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 235, 128, 6)),
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : items.isEmpty
                  ? const Center(
                      child: Text('No items found in this category',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              item['image_path'] != null
                                  ? Image.network(
                                      formatImageUrl(item['image_path']),
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Color.fromARGB(255, 235, 128, 6)),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading image: ${item['image_path']} - $error');
                                        return Container(
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.broken_image,
                                                color: Colors.red, size: 40),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.image,
                                            color: Colors.grey, size: 40),
                                      ),
                                    ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'Unnamed Item',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'UGX ${item['price']?.toString() ?? '0'}',
                                      style: const TextStyle(
                                          color: Color.fromARGB(255, 235, 128, 6),
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['description'] ?? 'No description',
                                      style: TextStyle(color: Colors.grey[700]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}