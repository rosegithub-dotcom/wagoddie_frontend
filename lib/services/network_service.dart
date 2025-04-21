// services/network_service.dart
// // services/network_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class NetworkService {
//   static const String registerUrl = "http://127.0.0.1:5000/api/v2/users/register"; // Ensure Flask is running here!
//   static const String loginUrl = "http://127.0.0.1:5000/api/v2/users/login"; // Login API endpoint

//   Future<Map<String, dynamic>> createAccount({
//     required String username,
//     required String email,
//     required String password,
//     required String contact,
//     required String role,
//     required String location,
//   }) async {
//     try {
//       final Map<String, dynamic> requestBody = {
//         'username': username,
//         'email': email,
//         'password': password,
//         'contact': contact,
//         'role': role,
//         'location': location,
//       };

//       print("Sending Request to API: $registerUrl");
//       print("Request Body: $requestBody");

//       final response = await http.post(
//         Uri.parse(registerUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );

//       print("Response Status Code: ${response.statusCode}");
//       print("Response Body: ${response.body}");

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         return {
//           'success': false,
//           'message': jsonDecode(response.body)['message'] ?? 'Failed to register!',
//         };
//       }
//     } catch (e) {
//       print("Error: $e");
//       return {
//         'success': false,
//         'message': 'Network error. Please check your internet connection.',
//       };
//     }
//   }

//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final Map<String, dynamic> requestBody = {
//         'email': email,
//         'password': password,
//       };

//       print("Sending Login Request to API: $loginUrl");
//       print("Request Body: $requestBody");

//       final response = await http.post(
//         Uri.parse(loginUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );

//       print("Response Status Code: ${response.statusCode}");
//       print("Response Body: ${response.body}");

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         return {
//           'success': false,
//           'message': jsonDecode(response.body)['message'] ?? 'Invalid login credentials!',
//         };
//       }
//     } catch (e) {
//       print("Error: $e");
//       return {
//         'success': false,
//         'message': 'Network error. Please check your internet connection.',
//       };
//     }
//   }
// }


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NetworkService {
  static const String registerUrl = "http://127.0.0.1:5000/api/v2/users/register";
  static const String loginUrl = "http://127.0.0.1:5000/api/v2/users/login";
  static const String profileUrl = "http://127.0.0.1:5000/api/v2/users/profile"; // Added profile endpoint
  final storage = const FlutterSecureStorage(); // For storing JWT token

  // Register User
  Future<Map<String, dynamic>> createAccount({
    required String username,
    required String email,
    required String password,
    required String contact,
    required String role,
    required String location,
    required String phone, // Note: 'phone' and 'phonenumber' seem redundant; using 'contact' as per your Flask API
    required String name,
    required String phonenumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'contact': contact, // Using 'contact' as per your Flask API
          'role': role,
          'location': location,
          // Note: 'phone', 'name', 'phonenumber' aren't in your Flask API; adjust if needed
        }),
      );

      return _processResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Login User
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final result = _processResponse(response);
      if (result['success']) {
        // Store the token after successful login
        final token = result['data']['access_token'] as String;
        await storage.write(key: 'jwt_token', value: token);
      }
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  // Fetch Profile (New Method)
  Future<Map<String, dynamic>> fetchProfile() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please log in.',
        };
      }

      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final result = _processResponse(response);
      if (result['success']) {
        // Adjust the response to include profile data directly under 'data'
        result['data'] = result['data']['profile'];
      }
      return result;
    } catch (e) {
      return _handleError(e);
    }
  }

  // Process HTTP Response
  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201, // 201 for register
        'message': data['message'] ?? 'Operation completed.',
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response.',
      };
    }
  }

  // Handle Errors
  Map<String, dynamic> _handleError(dynamic e) {
    return {
      'success': false,
      'message': 'Network error: ${e.toString()}\nPlease check your internet connection.',
    };
  }

  // Optional: Clear token on logout
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
  }
}