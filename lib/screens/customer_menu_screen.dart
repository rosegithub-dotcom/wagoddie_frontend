// screens/customer_menu_screen.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class CustomerMenuScreen extends StatefulWidget {
//   final int menuId;
//   final String categoryTitle;

//   const CustomerMenuScreen({
//     super.key,
//     required this.menuId,
//     required this.categoryTitle,
//   });

//   @override
//   State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
// }


// class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
//   Map<String, List<dynamic>> groupedItems = {};
//   bool isLoading = true;

//   final String baseUrl = 'http://127.0.0.1:5000';
  
  

//   @override
//   void initState() {
//     super.initState();
//     fetchMenuItems();
//   }

//   Future<void> fetchMenuItems() async {
//   setState(() => isLoading = true);
//   try {
//     final response = await http.get(
//    Uri.parse('$baseUrl/api/v2/item_bp/${widget.menuId}'),

//     );

//     if (response.statusCode == 200) {
//       final json = jsonDecode(response.body);
//       List<dynamic> items = json['items'] ?? [];

//       setState(() {
//         groupedItems = {
//           widget.categoryTitle: items,
//         };
//       });
//     } else {
//       print('Failed to fetch items: ${response.statusCode}');
//     }
//   } catch (e) {
//     print('Error: $e');
//   }
//   setState(() => isLoading = false);
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Menu"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: fetchMenuItems,
//           )
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : groupedItems.isEmpty
//               ? Center(child: Text("No items found"))
//               : ListView(
//                   children: groupedItems.entries.map((entry) {
//                     String category = entry.key;
//                     List<dynamic> items = entry.value;
//                     return ExpansionTile(
//                       title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
//                       children: items.map((item) {
//                         final imageUrl = item['image_path'] != null
//                             ? '$baseUrl${item['image_path']}'
//                             : '';
//                         return ListTile(
//                           leading: imageUrl.isNotEmpty
//                               ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
//                               : Icon(Icons.fastfood),
//                           title: Text(item['name']),
//                           subtitle: Text(item['description']),
//                           trailing: Text('UGX ${item['price']}'),
//                         );
//                       }).toList(),
//                     );
//                   }).toList(),
//                 ),
//     );
//   }
// }
// screens/customer_menu_screen.dart
// screens/customer_menu_screen.dart
// screens/customer_menu_screen.dart
// screens/customer_menu_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wagoddie_app/screens/cart_screen.dart';
import 'package:wagoddie_app/screens/item_detail_screen.dart'; 

class CustomerMenuScreen extends StatefulWidget {
  final int menuId;
  final String categoryTitle;

  const CustomerMenuScreen({
    super.key,
    required this.menuId,
    required this.categoryTitle,
  });

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  List<dynamic> items = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;

  final String baseUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v2/item_bp/${widget.menuId}'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        items = json['items'] ?? [];
      } else {
        print('Failed to fetch items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
    setState(() => isLoading = false);
  }

  void navigateToCartDetail(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        final existingIndex = cart.indexWhere((e) => e['id'] == result['id']);
        if (existingIndex != -1) {
          cart[existingIndex]['quantity'] += result['quantity'];
        } else {
          cart.add(result);
        }
      });
    }
  }

  void viewCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cart: cart,
          onCartUpdated: (updatedCart) {
            setState(() => cart = updatedCart);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = cart.fold(0, (sum, item) => sum + (item['quantity'] * double.parse(item['price'].toString())));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: viewCartPage,
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      cart.length.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text("No items found"))
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.all(10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final imageUrl = item['image_path'] != null
                              ? '$baseUrl${item['image_path']}'
                              : '';
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported),
                                          )
                                        : Container(color: Colors.grey[300]),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'UGX ${item['price']}',
                                        style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 35,
                                        child: ElevatedButton(
                                          onPressed: () => navigateToCartDetail(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            "Add to Cart",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (cart.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total: UGX ${total.toStringAsFixed(0)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ElevatedButton(
                              onPressed: viewCartPage,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: Text("Checkout", style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
