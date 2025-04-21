// screens/admin_dashdoard_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Color constants
const Color primaryYellow = Color(0xFFFFFFFF); // White
const Color primaryOrange = Color.fromARGB(255, 235, 128, 6); // Orange
const Color lightYellow = Color(0xFFFFFACD);

class AdminDashboardScreen extends StatefulWidget {
  static const ADMIN_EMAIL = "aloyobrenda@gmail.com";
  static const ADMIN_PASSWORD = "aloyo2019";
  static const String baseUrl = 'http://127.0.0.1:5000'; // Replace with your IP for physical device
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<dynamic>> groupedMenuItems = {}; // Store items grouped by category
  List<dynamic> filteredMenuItems = []; // Filtered list for display
  List<dynamic> orders = [];
  List<dynamic> users = [];
  List<dynamic> categories = [];
  String? currentCategoryFilter; // Track the current category filter
  String? token;
  bool isLoading = true;
  bool isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _menuIdController = TextEditingController();
  final storage = FlutterSecureStorage();
  File? _selectedImage;
  int? _editingCategoryId;
  int? _editingItemId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    validateAdminAndInitialize();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    _categoryNameController.dispose();
    _menuIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> validateAdminAndInitialize() async {
    setState(() => isLoading = true);
    final currentUserEmail = await getCurrentUserEmail();
    final currentUserPassword = await getCurrentUserPassword();
    if (currentUserEmail == AdminDashboardScreen.ADMIN_EMAIL &&
        currentUserPassword == AdminDashboardScreen.ADMIN_PASSWORD) {
      await initializeData();
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
        _showErrorSnackbar('Access denied. Admin privileges required.');
      }
    }
    setState(() => isLoading = false);
  }

  Future<String> getCurrentUserEmail() async => AdminDashboardScreen.ADMIN_EMAIL;
  Future<String> getCurrentUserPassword() async => AdminDashboardScreen.ADMIN_PASSWORD;

  Future<void> initializeData() async {
    setState(() => isLoading = true);
    await loginAndStoreToken();
    token = await getToken();
    if (token != null) {
      await Future.wait([
        fetchMenuItems(),
        fetchOrders(),
        fetchUsers(),
        fetchCategories(),
      ]);
    } else {
      _showErrorSnackbar('Failed to authenticate. Please log in again.');
    }
    setState(() => isLoading = false);
  }

  Future<void> loginAndStoreToken() async {
    try {
      final response = await http.post(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": AdminDashboardScreen.ADMIN_EMAIL,
          "password": AdminDashboardScreen.ADMIN_PASSWORD
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data["access_token"];
        await storage.write(key: "access_token", value: token);
        print("Token stored: $token");
      } else {
        print("Login failed: ${response.body}");
        _showErrorSnackbar('Login failed: ${response.body}');
      }
    } catch (e) {
      print("Error during login: $e");
      _showErrorSnackbar("Login error: $e");
    }
  }

  Future<String?> getToken() async {
    token = await storage.read(key: "access_token");
    if (token == null) {
      await loginAndStoreToken();
      token = await storage.read(key: "access_token");
    }
    return token;
  }

  Future<void> debugImageUrl(String url) async {
    print('Debugging image URL: $url');
    try {
      final response = await http.head(Uri.parse(url));
      print('Image HEAD response: ${response.statusCode} - ${response.headers}');
    } catch (e) {
      print('Image HEAD request failed: $e');
    }
  }

  Future<void> fetchMenuItems() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/item_bp/get"),
        headers: {"Authorization": "Bearer $token"},
      );

      print('Fetch menu items response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Response body: $responseBody');

        try {
          final parsed = jsonDecode(responseBody);
          setState(() {
            // Expect a Map<String, List<dynamic>> where keys are category names
            groupedMenuItems = Map<String, List<dynamic>>.from(
              parsed.map((key, value) => MapEntry(key, List<dynamic>.from(value))),
            );
            // Flatten for filtering, preserving category info
            List<dynamic> allItems = [];
            groupedMenuItems.forEach((category, items) {
              for (var item in items) {
                item['category_name'] = category; // Add category name for display
                allItems.add(item);
              }
            });
            // Apply filter if one exists
            if (currentCategoryFilter != null) {
              filteredMenuItems = allItems
                  .where((item) => item['menu_id'].toString() == currentCategoryFilter)
                  .toList();
            } else {
              filteredMenuItems = allItems;
            }
            if (allItems.isNotEmpty && allItems[0].containsKey('image_path')) {
              print('First item image path: ${allItems[0]['image_path']}');
              if (allItems[0]['image_path'] != null) {
                String imageUrl = formatImageUrl(allItems[0]['image_path']);
                debugImageUrl(imageUrl);
              }
            }
          });
        } catch (parseError) {
          print('JSON parse error: $parseError');
          _showErrorSnackbar('Failed to parse menu items: $parseError');
        }
      } else {
        _showErrorSnackbar('Failed to fetch menu items: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error fetching menu items: $e");
      _showErrorSnackbar("Failed to load menu items: $e");
    }
  }

  String formatImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    imagePath = imagePath.trim();
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/api/v2/menus/images/')) {
      return '${AdminDashboardScreen.baseUrl}$imagePath';
    }
    return '${AdminDashboardScreen.baseUrl}/api/v2/menus/images/$imagePath';
  }

  Future<void> fetchOrders() async {
    try {
      final token = await getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/order1/get-orders"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() => orders = jsonDecode(response.body)["orders"]);
      } else {
        _showErrorSnackbar('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching orders: $e");
      _showErrorSnackbar("Failed to load orders: $e");
    }
  }

  Future<void> fetchUsers() async {
    try {
      final token = await getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/users/get_all_users"),
        headers: {"Authorization": "Bearer $token"},
      );
      print('Fetch users response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() => users = jsonDecode(response.body)["users"]);
      } else {
        _showErrorSnackbar('Failed to fetch users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error fetching users: $e");
      _showErrorSnackbar("Failed to load users: $e");
    }
  }

  Future<void> fetchCategories() async {
    try {
      final token = await getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/menus/allmenu"),
        headers: {"Authorization": "Bearer $token"},
      );
      print('Fetch categories response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body)["menus"];
          print('Parsed categories: $categories');
          
          if (categories.isNotEmpty && categories[0].containsKey('image_path')) {
            print('First category image path: ${categories[0]['image_path']}');
            if (categories[0]['image_path'] != null) {
              String imageUrl = formatImageUrl(categories[0]['image_path']);
              debugImageUrl(imageUrl);
            }
          }
        });
      } else {
        _showErrorSnackbar('Failed to fetch categories: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error fetching categories: $e");
      _showErrorSnackbar("Failed to load categories: $e");
    }
  }

  Future<void> createMenuItem() async {
    if (_selectedCategoryId == null) {
      _showErrorSnackbar('Please select a category');
      return;
    }
    if (_selectedImage == null && _editingItemId == null) {
      _showErrorSnackbar('Please select an image');
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final token = await getToken();
      if (token == null) return;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/item_bp/create"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['menu_id'] = _selectedCategoryId!;
      request.fields['name'] = _itemNameController.text;
      request.fields['description'] = _itemDescriptionController.text;
      request.fields['price'] = _itemPriceController.text;

      if (_selectedImage != null) {
        if (await _selectedImage!.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ));
        } else {
          _showErrorSnackbar('Selected image file does not exist or is not readable');
          setState(() => isSubmitting = false);
          return;
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Create menu item response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        await fetchMenuItems();
        setState(() {
          currentCategoryFilter = _selectedCategoryId; // Set filter to the selected category
          filteredMenuItems = groupedMenuItems[categories
                  .firstWhere((cat) => cat['id'].toString() == _selectedCategoryId)['category_name']] ??
              [];
        });
        _clearItemForm();
        _showSuccessSnackbar("Menu item created successfully!");
        _tabController.animateTo(2); // Ensure we stay on Menu Items tab
      } else {
        _showErrorSnackbar('Failed to create menu item: ${response.body}');
      }
    } catch (e) {
      print("Error creating menu item: $e");
      _showErrorSnackbar("Failed to create menu item: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> editMenuItem(int itemId) async {
    if (_selectedCategoryId == null) {
      _showErrorSnackbar('Please select a category');
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final token = await getToken();
      if (token == null) return;
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/item_bp/edit/$itemId"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = _itemNameController.text;
      request.fields['description'] = _itemDescriptionController.text;
      request.fields['price'] = _itemPriceController.text;

      if (_selectedImage != null) {
        if (await _selectedImage!.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ));
        } else {
          _showErrorSnackbar('Selected image file does not exist or is not readable');
          setState(() => isSubmitting = false);
          return;
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Edit menu item response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await fetchMenuItems();
        _clearItemForm();
        _showSuccessSnackbar("Menu item updated successfully!");
      } else {
        _showErrorSnackbar('Failed to update menu item: ${response.body}');
      }
    } catch (e) {
      print("Error updating menu item: $e");
      _showErrorSnackbar("Failed to update menu item: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _clearItemForm() {
    _itemNameController.clear();
    _itemDescriptionController.clear();
    _itemPriceController.clear();
    _menuIdController.clear();
    setState(() {
      _selectedImage = null;
      _editingItemId = null;
      _selectedCategoryId = null;
    });
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        print('Selected image path: $path');

        final file = File(path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
          });
          _showSuccessSnackbar('Image selected: ${file.lengthSync()} bytes');
        } else {
          _showErrorSnackbar('Selected file does not exist: $path');
        }
      } else {
        _showErrorSnackbar('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _createCategory() async {
    if (_categoryNameController.text.trim().isEmpty) {
      _showErrorSnackbar('Category name is required');
      return;
    }
    if (_selectedImage == null && _editingCategoryId == null) {
      _showErrorSnackbar('Please select an image');
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final token = await getToken();
      if (token == null) return;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/menus/create"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['category_name'] = _categoryNameController.text.trim();

      if (_selectedImage != null) {
        if (await _selectedImage!.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ));
        } else {
          _showErrorSnackbar('Selected image file does not exist or is not readable');
          setState(() => isSubmitting = false);
          return;
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Create category response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        _showSuccessSnackbar('Category created successfully');
        _resetForm();
        await fetchCategories();
      } else {
        _showErrorSnackbar('Failed to create category: ${response.body}');
      }
    } catch (e) {
      print('Error creating category: $e');
      _showErrorSnackbar('Error creating category: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _editCategory(int id) async {
    if (_categoryNameController.text.trim().isEmpty) {
      _showErrorSnackbar('Category name is required');
      return;
    }
    setState(() => isSubmitting = true);
    try {
      final token = await getToken();
      if (token == null) return;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/menus/edit/$id"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['category_name'] = _categoryNameController.text.trim();

      if (_selectedImage != null) {
        if (await _selectedImage!.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ));
        } else {
          _showErrorSnackbar('Selected image file does not exist or is not readable');
          setState(() => isSubmitting = false);
          return;
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('Edit category response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _showSuccessSnackbar('Category updated successfully');
        _resetForm();
        await fetchCategories();
      } else {
        _showErrorSnackbar('Failed to update category: ${response.body}');
      }
    } catch (e) {
      print('Error editing category: $e');
      _showErrorSnackbar('Error editing category: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    _categoryNameController.clear();
    setState(() {
      _selectedImage = null;
      _editingCategoryId = null;
    });
  }

  Future<void> _deleteCategory(int id) async {
    try {
      final token = await getToken();
      if (token == null) return;
      final response = await http.delete(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/menus/delete/$id"),
        headers: {"Authorization": "Bearer $token"},
      );
      print('Delete category response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _showSuccessSnackbar('Category deleted successfully');
        await fetchCategories();
      } else {
        _showErrorSnackbar('Failed to delete category: ${response.body}');
      }
    } catch (e) {
      print('Error deleting category: $e');
      _showErrorSnackbar('Error deleting category: $e');
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      final token = await getToken();
      if (token == null) return;
      final response = await http.delete(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/item_bp/delete/$itemId"),
        headers: {"Authorization": "Bearer $token"},
      );
      print('Delete menu item response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        await fetchMenuItems();
        _showSuccessSnackbar("Menu item deleted successfully");
      } else {
        _showErrorSnackbar('Failed to delete menu item: ${response.body}');
      }
    } catch (e) {
      print("Error deleting menu item: $e");
      _showErrorSnackbar("Failed to delete menu item: $e");
    }
  }

  Future<Map<String, dynamic>> getSpecificUser(String userId) async {
    try {
      final token = await getToken();
      if (token == null) return {};
      final response = await http.get(
        Uri.parse("${AdminDashboardScreen.baseUrl}/api/v2/users/user/$userId"),
        headers: {"Authorization": "Bearer $token"},
      );
      print('Get user response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body)["user"];
      }
      return {};
    } catch (e) {
      print("Error fetching user: $e");
      _showErrorSnackbar("Failed to fetch user: $e");
      return {};
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildNetworkImage(String? imageUrl, {double height = 80.0}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(height);
    }

    final url = formatImageUrl(imageUrl);

    print('Loading image from: $url');

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator(height);
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image from $url: $error');
        return _buildErrorImage(height);
      },
    );
  }

  Widget _buildPlaceholderImage(double height) {
    return Container(
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.image, color: Colors.grey[500], size: 40),
      ),
    );
  }

  Widget _buildLoadingIndicator(double height) {
    return Container(
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(color: primaryOrange),
      ),
    );
  }

  Widget _buildErrorImage(double height) {
    return Container(
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.red[300], size: 40),
            SizedBox(height: 8),
            Text('Image not available', style: TextStyle(color: Colors.red[300])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightYellow,
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: const Text("Admin Dashboard", style: TextStyle(color: primaryYellow)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryYellow),
            onPressed: initializeData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryYellow,
          labelColor: primaryYellow,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Overview"),
            Tab(icon: Icon(Icons.category), text: "Categories"),
            Tab(icon: Icon(Icons.fastfood), text: "Menu Items"),
            Tab(icon: Icon(Icons.people), text: "Users & Orders"),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryOrange)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoryManagementTab(),
                _buildMenuItemsTab(),
                _buildUsersAndOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: primaryYellow,
      onRefresh: initializeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminInfo(),
            SizedBox(height: 20),
            _buildStatCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                title: "Total Items",
                value: groupedMenuItems.values.fold(0, (sum, items) => sum + items.length).toString(),
                icon: Icons.fastfood)),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard(title: "Categories", value: categories.length.toString(), icon: Icons.category)),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard(title: "Users", value: users.length.toString(), icon: Icons.people)),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: primaryOrange),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryManagementTab() {
    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: primaryYellow,
      onRefresh: fetchCategories,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingCategoryId == null ? 'Create New Category' : 'Edit Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryOrange),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _categoryNameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: TextStyle(color: primaryOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.category, color: primaryOrange),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image),
                            label: Text('Select Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              foregroundColor: primaryYellow,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_selectedImage != null)
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    if (_editingCategoryId != null) {
                                      _editCategory(_editingCategoryId!);
                                    } else {
                                      _createCategory();
                                    }
                                  },
                            child: isSubmitting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_editingCategoryId == null ? 'Create Category' : 'Update Category'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              foregroundColor: primaryYellow,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_editingCategoryId != null) ...[
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _resetForm,
                            child: Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Existing Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryOrange),
            ),
            SizedBox(height: 8),
            categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('No categories found', style: TextStyle(color: Colors.grey[600])),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNetworkImage(category['image_path']),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category['category_name'] ?? 'Unnamed Category',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'ID: ${category['id']}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          setState(() {
                                            _editingCategoryId = category['id'];
                                            _categoryNameController.text = category['category_name'] ?? '';
                                            _selectedImage = null;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete Category'),
                                              content: Text(
                                                  'Are you sure you want to delete this category? This will also delete all menu items in this category.'),
                                              actions: [
                                                TextButton(
                                                  child: Text('Cancel'),
                                                  onPressed: () => Navigator.of(context).pop(),
                                                ),
                                                TextButton(
                                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _deleteCategory(category['id']);
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: primaryYellow,
      onRefresh: fetchMenuItems,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editingItemId == null ? 'Create New Menu Item' : 'Edit Menu Item',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryOrange),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Select Category',
                          labelStyle: TextStyle(color: primaryOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.category, color: primaryOrange),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'].toString(),
                            child: Text(category['category_name'] ?? 'Unnamed Category'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _itemNameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: TextStyle(color: primaryOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.fastfood, color: primaryOrange),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _itemDescriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: primaryOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.description, color: primaryOrange),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _itemPriceController,
                        decoration: InputDecoration(
                          labelText: 'Price (UGX)',
                          labelStyle: TextStyle(color: primaryOrange),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.attach_money, color: primaryOrange),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(Icons.image),
                              label: Text('Select Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange,
                                foregroundColor: primaryYellow,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (_selectedImage != null)
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        if (_editingItemId != null) {
                                          editMenuItem(_editingItemId!);
                                        } else {
                                          createMenuItem();
                                        }
                                      }
                                    },
                              child: isSubmitting
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(_editingItemId == null ? 'Create Item' : 'Update Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange,
                                foregroundColor: primaryYellow,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_editingItemId != null) ...[
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _clearItemForm,
                              child: Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menu Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryOrange),
                ),
                if (currentCategoryFilter != null)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentCategoryFilter = null;
                        // Show all items when filter is cleared
                        List<dynamic> allItems = [];
                        groupedMenuItems.forEach((category, items) {
                          for (var item in items) {
                            item['category_name'] = category;
                            allItems.add(item);
                          }
                        });
                        filteredMenuItems = allItems;
                      });
                    },
                    child: Text('Show All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: primaryYellow,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            groupedMenuItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No menu items found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : Column(
                    children: groupedMenuItems.entries.map((entry) {
                      final categoryName = entry.key;
                      final items = currentCategoryFilter == null
                          ? entry.value
                          : entry.value
                              .where((item) => item['menu_id'].toString() == currentCategoryFilter)
                              .toList();
                      if (items.isEmpty) return SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryOrange,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNetworkImage(item['image_path']),
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['name'] ?? 'Unnamed Item',
                                                      style: TextStyle(
                                                          fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'UGX ${item['price'] ?? '0'}',
                                                      style: TextStyle(
                                                          color: primaryOrange, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit, color: Colors.blue),
                                                    onPressed: () {
                                                      setState(() {
                                                        _editingItemId = item['id'];
                                                        _itemNameController.text = item['name'] ?? '';
                                                        _itemDescriptionController.text =
                                                            item['description'] ?? '';
                                                        _itemPriceController.text =
                                                            item['price']?.toString() ?? '';
                                                        _selectedCategoryId = item['menu_id']?.toString();
                                                        _selectedImage = null;
                                                      });
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: Text('Delete Menu Item'),
                                                          content: Text(
                                                              'Are you sure you want to delete this menu item?'),
                                                          actions: [
                                                            TextButton(
                                                              child: Text('Cancel'),
                                                              onPressed: () => Navigator.of(context).pop(),
                                                            ),
                                                            TextButton(
                                                              child: Text('Delete',
                                                                  style: TextStyle(color: Colors.red)),
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                                deleteMenuItem(item['id'].toString());
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            item['description'] ?? 'No description',
                                            style: TextStyle(color: Colors.grey[700]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.category, size: 16, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Text(
                                                item['category_name'] ?? 'Uncategorized',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersAndOrdersTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[200],
            child: TabBar(
              labelColor: primaryOrange,
              unselectedLabelColor: Colors.grey[700],
              indicatorColor: primaryOrange,
              tabs: [
                Tab(icon: Icon(Icons.people), text: "Users"),
                Tab(icon: Icon(Icons.receipt_long), text: "Orders"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersTab(),
                _buildOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: primaryYellow,
      onRefresh: fetchUsers,
      child: users.isEmpty
          ? Center(child: Text('No users found', style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: primaryOrange,
                      child: Text(
                        (user['username'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user['username'] ?? 'Unknown User',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(user['email'] ?? 'No email'),
                        SizedBox(height: 4),
                        Text(
                          'Joined: ${user['created_at'] != null ? DateTime.parse(user['created_at']).toString().split('.')[0] : 'Unknown'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('User Details'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user['id']}'),
                              SizedBox(height: 8),
                              Text('Username: ${user['username'] ?? 'N/A'}'),
                              SizedBox(height: 8),
                              Text('Email: ${user['email'] ?? 'N/A'}'),
                              SizedBox(height: 8),
                              Text('Role: ${user['is_admin'] == true ? 'Admin' : 'Customer'}'),
                              SizedBox(height: 8),
                              Text('Created: ${user['created_at'] != null ? DateTime.parse(user['created_at']).toString().split('.')[0] : 'Unknown'}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text('Close'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      color: primaryOrange,
      backgroundColor: primaryYellow,
      onRefresh: fetchOrders,
      child: orders.isEmpty
          ? Center(child: Text('No orders found', style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(order['status']),
                      child: Icon(Icons.receipt, color: Colors.white),
                    ),
                    title: Text(
                      'Order #${order['id']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('Status: ${order['status'] ?? 'Unknown'}'),
                        SizedBox(height: 4),
                        Text(
                          'Date: ${order['created_at'] != null ? DateTime.parse(order['created_at']).toString().split('.')[0] : 'Unknown'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Text(
                      'UGX ${order['total_price'] ?? '0'}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryOrange),
                    ),
                    children: [
                      if (order['items'] != null && order['items'] is List) ...[
                        Divider(),
                        Text(
                          'Order Items:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        ...List.generate(
                          order['items'].length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order['items'][i]['quantity']}x ${order['items'][i]['name'] ?? 'Unknown Item'}'),
                                Text('UGX ${order['items'][i]['price'] ?? '0'}'),
                              ],
                            ),
                          ),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('UGX ${order['total_price'] ?? '0'}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Update Order Status'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: Text('Pending'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            title: Text('Processing'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            title: Text('Completed'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            title: Text('Cancelled'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Update Status'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryOrange,
                                  foregroundColor: primaryYellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Widget _buildAdminInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryOrange,
              radius: 30,
              child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.white),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Welcome, ${AdminDashboardScreen.ADMIN_EMAIL}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your shop operations here',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}