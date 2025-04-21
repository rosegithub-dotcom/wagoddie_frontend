// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wagoddie_app/screens/grocery_staples_screen.dart';
import 'package:wagoddie_app/screens/personal_care_screen.dart';
import 'package:wagoddie_app/screens/produce_screen.dart';
import 'package:wagoddie_app/screens/categories_screen.dart';
import 'package:wagoddie_app/screens/profile_screen.dart'; // Add this import for ProfileScreen

class WagoddieOnlineHome extends StatefulWidget {
  @override
  _WagoddieOnlineHomeState createState() => _WagoddieOnlineHomeState();
}

class _WagoddieOnlineHomeState extends State<WagoddieOnlineHome> {
  // Define the primary orange color as a constant
  final Color primaryOrange = Color(0xFFF9943A);

  // Your actual API base URL - update this with your real backend URL
  final String apiBaseUrl = "http://127.0.0.1:5000"; // Base URL without /api/v2 for flexibility

  // Updated banner images with local assets
  final List<String> bannerImages = [
    "assets/images/barnner6.jpg",
    "assets/images/barnner2.jpg",
    "assets/images/barnner3.jpg",
    "assets/images/barnner4.jpg",
    "assets/images/barnner5.jpg",
    "assets/images/barnner6.jpg",
    "assets/images/barnner7.jpg",
  ];

  // Updated new products with local assets
  final List<Map<String, dynamic>> newProducts = [
    {
      "name": "Baking Aids",
      "price": "8,500",
      "imageUrl": "assets/images/Baking Aids.jpg",
      "discount": "10%"
    },
    {
      "name": "Disposables, Foils and Packaging",
      "price": "7,200",
      "imageUrl": "assets/images/Disposables, Foils and Packaging.jpg",
      "discount": null
    },
    {
      "name": "Stationary",
      "price": "15,000",
      "imageUrl": "assets/images/Stationery.jpg",
      "discount": "5%"
    },
    {
      "name": "Whole Grain Bread",
      "price": "5,000",
      "imageUrl": "assets/images/spa.jpg",
      "discount": null
    },
  ];

  // Categories to be fetched from backend
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/v2/menus/allmenu'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(data['menus']);
          isLoading = false;
        });
        print('Categories fetched: $categories');
      } else {
        print('Failed to load menus: ${response.statusCode} - ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          hintStyle: TextStyle(color: Colors.black),
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
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(Icons.shopping_cart, color: primaryOrange),
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildImageSlider(),
            const SizedBox(height: 20),
            _buildSectionHeader(
              context,
              "Shop by Category",
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen(menuId: null)),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                    ),
                  )
                : categories.isEmpty
                    ? Center(
                        child: Text(
                          "No categories available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: categories.length > 6 ? 6 : categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(
                            context,
                            categories[index]["category_name"] ?? "Unnamed",
                            categories[index]["image_path"] ?? "",
                            categories[index]["id"] ?? 0,
                          );
                        },
                      ),
            const SizedBox(height: 20),
            _buildSectionHeader(
              context,
              "New Products",
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CategoriesScreen(initialTab: 1, menuId: null)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: newProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(newProducts[index]);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
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
          switch (index) {
            case 1: // Categories
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen(menuId: null)),
              );
              break;
            case 3: // Account
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
            // Add navigation for other tabs (Offers, Cart) as needed
            default:
              break;
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onViewAllPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryOrange,
          ),
        ),
        TextButton(
          onPressed: onViewAllPressed,
          child: Row(
            children: [
              Text(
                "View All",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black87),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  child: Image.asset(
                    product["imageUrl"],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (product["discount"] != null)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product["discount"],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product["name"],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  "UGX ${product["price"]}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      "Add to Cart",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayInterval: Duration(seconds: 3),
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        viewportFraction: 0.9,
      ),
      items: bannerImages.map((imageUrl) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath, int menuId) {
    String fullImageUrl = '$apiBaseUrl$imagePath';
    print('Loading category image: $fullImageUrl');

    return GestureDetector(
      onTap: () => _navigateToCategory(context, title, menuId),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 3,
        child: Container(
          height: 100,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      print('Image load error for $fullImageUrl: $error');
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                          color: primaryOrange,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String title, int menuId) {
    switch (title) {
      case "Produce":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProduceScreen(menuId: menuId)),
        );
        break;
      case "Personal Care":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PersonalCareScreen(menuId: menuId)),
        );
        break;
      case "Grocery & Staples":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroceryStaplesScreen(menuId: menuId)),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoriesScreen(menuId: menuId)),
        );
        break;
    }
  }
}