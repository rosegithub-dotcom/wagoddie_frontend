// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:wagoddie_app/services/network_service.dart';
import 'package:wagoddie_app/screens/admin_dashdoard_screen.dart';
import 'package:wagoddie_app/screens/create_account_screen.dart';
import 'package:wagoddie_app/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final NetworkService _networkService = NetworkService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Updated brand colors
  static const Color darkGrayColor = Color(0xFF333333);
  static const Color primaryOrange = Color.fromARGB(255, 235, 128, 6);
  static const Color logoBackgroundColor = Color(0xFFF5F5F5); // Light gray background

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_emailController.text.trim() == AdminDashboardScreen.ADMIN_EMAIL &&
          _passwordController.text.trim() == AdminDashboardScreen.ADMIN_PASSWORD) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome Admin!', style: TextStyle(color: darkGrayColor)),
            backgroundColor: primaryOrange,
          ),
        );
        return;
      }

      final response = await _networkService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WagoddieOnlineHome()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back!', style: TextStyle(color: darkGrayColor)),
            backgroundColor: primaryOrange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Login failed", style: TextStyle(color: darkGrayColor))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e', style: TextStyle(color: darkGrayColor))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: logoBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo section
                SizedBox(
                  height: 150,
                  child: Center(
                    child: Image.asset(
                      'assets/images/CLEAR LOGO.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Center-aligned Login text
                const Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGrayColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: "E-mail",
                  icon: Icons.email,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Email is required";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _buildPasswordField(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Implement forgot password functionality
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(color: darkGrayColor),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: darkGrayColor,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Logging in...",
                                  style: TextStyle(
                                    color: darkGrayColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                color: darkGrayColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAccountScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Create an account",
                      style: TextStyle(color: darkGrayColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: darkGrayColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: darkGrayColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        prefixIcon: icon != null ? Icon(icon, color: darkGrayColor) : null,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: darkGrayColor),
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: null,
      validator: (value) {
        if (value?.isEmpty ?? true) return "Password is required";
        return null;
      },
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: darkGrayColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryOrange),
        ),
        prefixIcon: const Icon(Icons.lock, color: darkGrayColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: darkGrayColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }
}
