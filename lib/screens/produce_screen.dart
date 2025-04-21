// screens/produce_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:wagoddie_app/screens/categories_screen.dart';
import 'package:wagoddie_app/services/cart_service.dart';

class ProduceScreen extends StatefulWidget {
  final int menuId;

  const ProduceScreen({Key? key, required this.menuId}) : super(key: key);

  @override
  _ProduceScreenState createState() => _ProduceScreenState();
}

class _ProduceScreenState extends State<ProduceScreen> {
  final Color primaryOrange = const Color.fromARGB(255, 235, 128, 6);
  final Color lightYellow = const Color(0xFFFFFACD);
  final String apiBaseUrl = "http://127.0.0.1:5000";
  bool isLoading = true;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/v2/item_bp/get?menuId=${widget.menuId}'));
      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(productData);
          isLoading = false;
        });
        print('Products fetched for Produce: $products');
      } else {
        print('Failed to load products: ${response.statusCode} - ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120),
        child: AppBar(
          backgroundColor: primaryOrange,
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "+256 123 456 789",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search for a product",
                          hintStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: IconButton(
                            icon: Icon(Icons.shopping_cart, color: primaryOrange),
                            onPressed: () {
                              Navigator.pushNamed(context, '/cart');
                            },
                          ),
                        ),
                        if (cartService.itemCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${cartService.itemCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Produce", style: TextStyle(color: Colors.white)),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
              ),
            )
          : products.isEmpty
              ? Center(
                  child: Text(
                    "No products available",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        apiBaseUrl: apiBaseUrl,
                        primaryOrange: primaryOrange,
                        onAddToCart: (cartItem) {
                          final cartService = Provider.of<CartService>(context, listen: false);
                          cartService.addToCart(cartItem);
                          _showSuccessSnackbar("${product['name']} added to cart!");
                        },
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white10,
        selectedItemColor: primaryOrange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CategoriesScreen(menuId: null)),
            );
          } else if (index == 4) {
            Navigator.pushNamed(context, '/cart');
          }
        },
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final String apiBaseUrl;
  final Color primaryOrange;
  final Function(CartItem) onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.apiBaseUrl,
    required this.primaryOrange,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    String fullImageUrl = widget.product["image"] != null ? '${widget.apiBaseUrl}${widget.product["image"]}' : '';
    print('Loading product image: $fullImageUrl');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: fullImageUrl.isNotEmpty
                ? Image.network(
                    fullImageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Product image load error: $error');
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.yellow),
                    SizedBox(width: 4),
                    Icon(Icons.star, size: 12, color: Colors.yellow),
                    SizedBox(width: 4),
                    Icon(Icons.star, size: 12, color: Colors.yellow),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  widget.product["name"] ?? "Unnamed Product",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "UGX ${widget.product["price"]?.toString() ?? "0"}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.primaryOrange,
                      ),
                    ),
                    Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  "4 pc",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      },
                    ),
                    Text('$quantity', style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: widget.product['id'],
                              name: widget.product['name'],
                              price: (widget.product['price'] as num).toDouble(),
                              description: widget.product['description'] ?? '',
                              image: widget.product['image'] ?? '',
                              quantity: quantity,
                            );
                            widget.onAddToCart(cartItem);
                            setState(() {
                              quantity = 1; // Reset quantity after adding to cart
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryOrange,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            "ADD TO CART",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}