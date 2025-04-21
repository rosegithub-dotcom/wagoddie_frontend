// screens/grocery_staples_screen.dart


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wagoddie_app/services/cart_service.dart';

class GroceryStaplesScreen extends StatelessWidget {
  const GroceryStaplesScreen({super.key, required int menuId});

  @override
  Widget build(BuildContext context) {
    // Access the cart service
    final cartService = Provider.of<CartService>(context);
    final cartItemCount = cartService.itemCount;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              "Grocery & Staples",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            const SizedBox(width: 8),
            // Cart icon with badge showing number of items
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.black),
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                ),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: const TextStyle(
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Search prompt button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "What are you looking for?",
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),

            // Featured product image
            Image.asset("assets/images/onboarding.png", height: 120), // Replace with actual image
            const SizedBox(height: 10),

            // Products grid
            Expanded(
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(context, product);
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Important for 5 items
        onTap: (index) {
          if (index == 4) { // Cart index
            Navigator.pushNamed(context, '/cart');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    // Access cart service without listening for changes
    final cartService = Provider.of<CartService>(context, listen: false);
    
    // Convert price string to double for CartItem
    String rawPrice = product["price"].replaceAll(',', '');
    double price = double.tryParse(rawPrice) ?? 0.0;
    
    // Generate a unique ID if not provided
    final productId = product["id"] ?? products.indexOf(product) + 1;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Image.asset(
            product["image"],
            height: 100,
            errorBuilder: (context, error, stackTrace) {
              // Fallback widget if image fails to load
              return Container(
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 40),
              );
            },
          ),
          const SizedBox(height: 3),
          Text(
            product["name"],
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "UGX ${product["price"]}",
            style: const TextStyle(color: Colors.black),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () {
              // Add product to cart using the service
              cartService.addToCart(
                CartItem(
                  id: productId,
                  name: product["name"],
                  price: price,
                  description: product["description"] ?? "No description available",
                  image: product["image"],
                  quantity: 1,
                ),
              );
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product["name"]} added to cart'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'VIEW CART',
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9943A),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            child: const Text("ADD TO CART", style: TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// Updated sample product data with descriptions
List<Map<String, dynamic>> products = [
  {"id": 1, "name": "Cooking Oil", "price": "20,000", "image": "assets/images/cooking_oil.png", "description": "High quality cooking oil, perfect for all your cooking needs."},
  {"id": 2, "name": "Spaghetti", "price": "12,000", "image": "assets/images/spa.jpg", "description": "Premium Italian spaghetti pasta."},
  {"id": 3, "name": "Macaroni", "price": "14,000", "image": "assets/macaroni.png", "description": "Delicious macaroni pasta for all your favorite dishes."},
  {"id": 4, "name": "Lato Milk", "price": "15,000", "image": "assets/images/latomilk.jpg", "description": "Fresh and nutritious milk for your daily needs."},
  {"id": 5, "name": "Tomato Sauce", "price": "10,000", "image": "assets/tomato_sauce.png", "description": "Rich and flavorful tomato sauce."},
  {"id": 6, "name": "Mukwano Soap", "price": "8,000", "image": "assets/images/soap 1.jpg", "description": "Quality soap for household cleaning."},
  {"id": 7, "name": "Rice", "price": "22,000", "image": "assets/rice.png", "description": "Premium quality rice grains."},
  {"id": 8, "name": "Honey", "price": "25,000", "image": "assets/honey.png", "description": "Pure and natural honey."},
  {"id": 9, "name": "More Tomato Sauce", "price": "10,000", "image": "assets/tomato_sauce2.png", "description": "Extra rich tomato sauce with herbs."},
];
