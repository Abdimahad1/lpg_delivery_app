import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controllers
import 'controllers/cart_controller.dart';
import 'controllers/favorites_controller.dart';

// Auth Screens
import 'auth/loading_screen.dart';
import 'auth/login_screen.dart' as login;
import 'auth/sign_up_screen.dart' as signup;

// Customer Navigation UI with Bottom Navbar
import 'customerUI/CustomerMainScreen.dart';

void main() {
  // Initialize controllers
  Get.put(CartController());
  Get.put(FavoritesController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LPG Delivery App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoadingScreen(), // Initial loading splash
      getPages: [
        GetPage(name: '/', page: () => const LoadingScreen()),
        GetPage(name: '/login', page: () => login.LoginScreen()),
        GetPage(name: '/signup', page: () => signup.SignUpScreen()),
        GetPage(name: '/customer-home', page: () => const CustomerMainScreen()),
      ],
    );
  }
}
