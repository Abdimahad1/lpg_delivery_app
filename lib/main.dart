import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Controllers
import 'VendorUI/VendorMainScreen.dart';
import 'controllers/cart_controller.dart';
import 'controllers/profile_controller.dart';
import 'services/http_service.dart'; // Add this import
import 'customerUI/search_vendors_screen.dart';
// Auth Screens
import 'auth/loading_screen.dart';
import 'auth/login_screen.dart' as login;
import 'auth/sign_up_screen.dart' as signup;

// Customer Navigation UI with Bottom Navbar
import 'customerUI/CustomerMainScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔥 REQUIRED
  await GetStorage.init(); // Initialize GetStorage first
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LPG Delivery App',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(), // Add this line
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoadingScreen(),
      getPages: [
        GetPage(name: '/', page: () => const LoadingScreen()),
        GetPage(name: '/login', page: () => login.LoginScreen()),
        GetPage(name: '/signup', page: () => signup.SignupScreen()),
        GetPage(name: '/customer-home', page: () => const CustomerMainScreen()),
        GetPage(name: '/vendor-home', page: () => const VendorMainScreen()),
        GetPage(name: '/search-vendors', page: () => const SearchVendorsScreen()),

      ],
    );
  }
}

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize HttpService first as it's used by other controllers
    Get.lazyPut(() => HttpService(), fenix: true);

    // Then initialize other controllers
    Get.put(ProfileController(), permanent: true);
    Get.put(CartController());
  }
}