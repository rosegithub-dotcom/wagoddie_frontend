// screens/categories_screen.dart
// screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wagoddie_app/screens/customer_menu_screen.dart'; // adjust path if needed

// import 'package:wagoddie_app/screens/grocery_staples_screen.dart';
// import 'package:wagoddie_app/screens/personal_care_screen.dart';
// import 'package:wagoddie_app/screens/produce_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final int? menuId;
  final int initialTab;

  const CategoriesScreen({
    Key? key,
    this.menuId,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  final Color primaryOrange = const Color.fromARGB(255, 235, 128, 6);
  final String apiBaseUrl = "http://127.0.0.1:5000";

  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      // Fetch categories
      final menuResponse = await http.get(Uri.parse('$apiBaseUrl/api/v2/menus/allmenu'));
      if (menuResponse.statusCode == 200) {
        final menuData = json.decode(menuResponse.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(menuData['menus']);
        });
        print('Categories fetched: $categories');
      } else {
        print('Failed to load menus: ${menuResponse.statusCode} - ${menuResponse.body}');
      }

      // Fetch products
      String productUrl = widget.menuId != null
          ? '$apiBaseUrl/api/v2/item_bp/get?menuId=${widget.menuId}'
          : '$apiBaseUrl/api/v2/item_bp/get';
      final productResponse = await http.get(Uri.parse(productUrl));
      if (productResponse.statusCode == 200) {
        final productData = json.decode(productResponse.body);
        setState(() {
          products = List<Map<String, dynamic>>.from(productData);
        });
        print('Products fetched: $products');
      } else {
        print('Failed to load products: ${productResponse.statusCode} - ${productResponse.body}');
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: primaryOrange,
              labelColor: primaryOrange,
              unselectedLabelColor: Colors.white10,
              tabs: [
                Tab(text: "Categories"),
                Tab(text: "Products"),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoriesTab(),
                      _buildProductsTab(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white10,
        selectedItemColor: primaryOrange,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(
            context,
            category["category_name"] ?? "Unnamed",
            category["image_path"] ?? "",
            category["id"] ?? 0,
          );
        },
      ),
    );
  }

  Widget _buildProductsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: products.isEmpty
          ? Center(
              child: Text(
                "No products available",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath, int menuId) {
    String fullImageUrl = '$apiBaseUrl$imagePath';
    print('Loading category image: $fullImageUrl');

    return GestureDetector(
      onTap: () {
        _navigateToCategory(context, title, menuId);
      },
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
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
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: primaryOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    String fullImageUrl = product["image"] != null ? '$apiBaseUrl${product["image"]}' : '';
    print('Loading product image: $fullImageUrl');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
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
              // Note: Your Flask model doesn’t include "discount" yet, so this is commented out unless added later
              // if (product["discount"] != null)
              //   Positioned(
              //     top: 5,
              //     right: 5,
              //     child: Container(
              //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //       decoration: BoxDecoration(
              //         color: Colors.red,
              //         borderRadius: BorderRadius.circular(20),
              //       ),
              //       child: Text(
              //         "${product["discount"]}% OFF",
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 10,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product["name"] ?? "Unnamed Product",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  "UGX ${product["price"]?.toString() ?? "0"}",
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
                      backgroundColor: primaryOrange,
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

void _navigateToCategory(BuildContext context, String title, int menuId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CustomerMenuScreen(menuId: menuId, categoryTitle: title),
    ),
  );
}

//   void _navigateToCategory(BuildContext context, String title, int menuId) {
//     switch (title) {
//       case "Produce":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => ProduceScreen(menuId: menuId)),
//         );
//         break;
//       case "Personal Care":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => PersonalCareScreen(menuId: menuId)),
//         );
//         break;
//       case "Grocery & Staples":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => GroceryStaplesScreen(menuId: menuId)),
//         );
//         break;
//       default:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CategoriesScreen(
//               menuId: menuId,
//               initialTab: 1,
//             ),
//           ),
//         );
//         break;
//             }
//   }
 } // 