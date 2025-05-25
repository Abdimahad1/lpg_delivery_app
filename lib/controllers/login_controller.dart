// login_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../auth/network_service.dart';
import '../config/api_config.dart';
import 'profile_controller.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var selectedRole = ''.obs;
  final isLoading = false.obs;
  final box = GetStorage();
  final isOnline = false.obs;

  @override
  void onInit() {
    final args = Get.arguments;
    if (args != null && args is Map) {
      emailController.text = args["email"] ?? '';
      passwordController.text = args["password"] ?? '';
      selectedRole.value = args["role"] ?? '';
    }
    _checkInternetConnection();
    super.onInit();
  }

  void _showSnackbar(String title, String message, {bool isError = true}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(12),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'vendor':
        return 'Vendor';
      case 'deliveryperson':
        return 'DeliveryPerson';
      default:
        return role;
    }
  }

  Future<void> _checkInternetConnection() async {
    isOnline.value = await NetworkService.isConnected();
  }

  Future<void> _storeOfflineLogin() async {
    final loginData = {
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
      'role': _formatRole(selectedRole.value),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };

    final pendingLogins = box.read('pendingLogins') ?? [];
    pendingLogins.add(loginData);
    await box.write('pendingLogins', pendingLogins);
  }

  Future<void> _syncPendingLogins() async {
    if (!isOnline.value) return;

    final pendingLogins = box.read('pendingLogins') ?? [];
    if (pendingLogins.isEmpty) return;

    for (var loginData in pendingLogins) {
      if (loginData['synced'] == true) continue;

      try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/auth/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginData),
        ).timeout(apiTimeout);

        if (response.statusCode == 200) {
          loginData['synced'] = true;
          await box.write('pendingLogins', pendingLogins);
          _handleSuccessfulLogin(jsonDecode(response.body));
        }
      } catch (e) {
        print("Failed to sync login: $e");
      }
    }

    // Remove synced logins
    final remainingLogins = pendingLogins.where((l) => l['synced'] == false).toList();
    await box.write('pendingLogins', remainingLogins);
  }

  Future<void> loginUser() async {
    if (selectedRole.value.isEmpty) {
      _showSnackbar("Error", "Please select a role");
      return;
    }

    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      _showSnackbar("Error", "Please enter a valid email");
      return;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      _showSnackbar("Error", "Password must be at least 6 characters");
      return;
    }

    // Check internet connection before proceeding
    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "role": selectedRole.value,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final token = responseBody['token'];
        final profileController = Get.put(ProfileController());
        profileController.setAuthToken(token);
        await profileController.fetchProfile();
        _handleSuccessfulLogin(responseBody);
      } else {
        _showSnackbar(
            "Login Failed",
            responseBody['message'] ?? "Invalid credentials",
            isError: true
        );
      }
    } on SocketException {
      _showSnackbar("Network Error", "No internet connection", isError: true);
    } on TimeoutException {
      _showSnackbar("Timeout", "Server took too long to respond", isError: true);
    } catch (e) {
      _showSnackbar("Error", "An unexpected error occurred", isError: true);
      print("Login error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleOfflineLogin() async {
    // Check if credentials match any locally stored user
    final localUsers = box.read('localUsers') ?? [];
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final role = _formatRole(selectedRole.value);

    final user = localUsers.firstWhere(
          (u) => u['email'] == email && u['role'] == role,
      orElse: () => null,
    );

    if (user != null) {
      // In a real app, you'd want to use proper password hashing here
      if (user['password'] == password) {
        _showSnackbar("Offline Mode", "Logged in offline", isError: false);
        Get.offAllNamed('/offline-home'); // You'll need to create this route
        return;
      } else {
        _showSnackbar("Error", "Invalid credentials");
        return;
      }
    }

    // No local user found - store for later sync
    await _storeOfflineLogin();
    _showSnackbar("Offline Mode", "Login will be processed when online", isError: false);
    Get.offAllNamed('/offline-home');
  }

  void _handleSuccessfulLogin(Map<String, dynamic> result) {
    final user = result['user'];
    final roleFromServer = user['role'];

    _showSnackbar("Success", "Welcome, ${user['name']}", isError: false);

    switch (roleFromServer) {
      case "Customer":
        Get.offAllNamed('/customer-home');
        break;
      case "Vendor":
        Get.offAllNamed('/vendor-home');
        break;
      case "DeliveryPerson":
        Get.offAllNamed('/delivery-home');
        break;
      default:
        _showSnackbar("Error", "Unknown role: $roleFromServer");
    }
  }

  Future<void> syncPendingLogins() async {
    if (!isOnline.value) return;

    final pendingLogins = box.read('pendingLogins') ?? [];
    if (pendingLogins.isEmpty) return;

    for (var loginData in pendingLogins) {
      if (loginData['synced'] == true) continue;

      try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/auth/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(loginData),
        ).timeout(apiTimeout);

        if (response.statusCode == 200) {
          loginData['synced'] = true;
          await box.write('pendingLogins', pendingLogins);
          _handleSuccessfulLogin(jsonDecode(response.body));
        }
      } catch (e) {
        print("Failed to sync login: $e");
      }
    }

    // Remove synced logins
    final remainingLogins = pendingLogins.where((l) => l['synced'] == false).toList();
    await box.write('pendingLogins', remainingLogins);
  }
}