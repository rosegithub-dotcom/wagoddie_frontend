// main.dart
// import 'package:flutter/material.dart';
// import 'package:wagoddie_app/screens/splash_screen.dart';
 


// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
       
       
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
        
//       ),
//       debugShowCheckedModeBanner: false,
//       home:   const SplashScreen()
  
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:wagoddie_app/screens/cart_screen.dart';
// import 'package:wagoddie_app/screens/splash_screen.dart';
// import 'package:wagoddie_app/services/cart_service.dart';
// // Import other services if needed

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => CartService()),
//         // Add other providers/services here
//       ],
//       child: MaterialApp(
//         title: 'Flutter Demo',
//         theme: ThemeData(
//           colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//           useMaterial3: true,
//         ),
//         debugShowCheckedModeBanner: false,
//         home: const SplashScreen(),
//         routes: {
//           // Define your routes here
//           '/cart': (context) => const CartScreen(), // Your existing cart screen
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/foundation.dart' show kIsWeb; // Add this for platform detection
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wagoddie_app/screens/admin_dashdoard_screen.dart';
import 'package:wagoddie_app/screens/create_account_screen.dart';
import 'package:wagoddie_app/screens/login_screen.dart';
import 'package:wagoddie_app/screens/splash_screen.dart';
import 'package:wagoddie_app/providers/cart_provider.dart'; // Updated import
import 'package:window_manager/window_manager.dart'; // For desktop window management

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window_manager only on non-web platforms (desktop)
  if (!kIsWeb) {
    try {
      await windowManager.ensureInitialized();
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setTitle('Wagoddie Mobile Application'); // Optional: Set app title
        await windowManager.setSize(const Size(800, 600)); // Initial window size
        await windowManager.setMinimumSize(const Size(400, 300)); // Minimum size
        await windowManager.center(); // Center the window
        await windowManager.show(); // Show the window
      });
    } catch (e) {
      print('Window manager initialization error: $e');
      // Continue with app startup even if window manager fails
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()), // Updated to use CartProvider
        // Add other providers/services here if needed
      ],
      child: MaterialApp(
        title: 'Wagoddie App', // Consistent app title
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 235, 128, 6), // Using your primary orange color
            primary: const Color.fromARGB(255, 235, 128, 6),
          ),
          useMaterial3: true,
          // Add text theme to ensure text is properly sized
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 14),
            bodyLarge: TextStyle(fontSize: 16),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          
          // Add other routes here as needed
          '/login': (context) => LoginScreen(), // Add this
          '/account': (context) => const CreateAccountScreen(), // Add this
          '/admin_dashboard': (context) => const AdminDashboardScreen(), // Add this
       
        },
      ),
    );
  }
}