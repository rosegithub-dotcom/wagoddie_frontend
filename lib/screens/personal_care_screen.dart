// screens/personal_care_screen.dart
import 'package:flutter/material.dart';

class PersonalCareScreen extends StatelessWidget {
  const PersonalCareScreen({super.key, required int menuId});

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.shopping_cart, color: Colors.black),
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

            // Banner Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "assets/banner.png",  // Replace with your banner image
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Products Grid
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
                  return _buildProductCard(product);
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Image.asset(product["image"], height: 70), // Replace with actual image
          const SizedBox(height: 8),
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
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            child: const Text("ADD TO CART", style: TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// Sample product data
List<Map<String, dynamic>> products = [
  {"name": "Cooking Oil", "price": "20,000", "image": "assets/cooking_oil.png"},
  {"name": "Spaghetti", "price": "12,000", "image": "assets/spaghetti.png"},
  {"name": "Macaroni", "price": "14,000", "image": "assets/macaroni.png"},
  {"name": "Lato Milk", "price": "15,000", "image": "assets/lato_milk.png"},
  {"name": "Tomato Sauce", "price": "10,000", "image": "assets/tomato_sauce.png"},
  {"name": "Mukwano Soap", "price": "8,000", "image": "assets/mukwano_soap.png"},
  {"name": "Rice", "price": "22,000", "image": "assets/rice.png"},
  {"name": "Honey", "price": "25,000", "image": "assets/honey.png"},
  {"name": "More Tomato Sauce", "price": "10,000", "image": "assets/tomato_sauce2.png"},
];
