import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';
import 'login_controller.dart';

class SignupController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var selectedRole = ''.obs;
  final isLoading = false.obs;
  final box = GetStorage();
  final isOnline = false.obs;

  @override
  void onInit() {
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

  Future<void> _checkInternetConnection() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        isOnline.value = false;
        return;
      }

      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 5));
      isOnline.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      isOnline.value = false;
    } on TimeoutException {
      isOnline.value = false;
    }
  }

  Future<void> _storeOfflineSignup() async {
    final signupData = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(), // Note: In production, use proper hashing
      'role': selectedRole.value,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };

    final pendingSignups = box.read('pendingSignups') ?? [];
    pendingSignups.add(signupData);
    await box.write('pendingSignups', pendingSignups);

    // Also store as local user for offline login
    final localUsers = box.read('localUsers') ?? [];
    localUsers.add({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(), // Note: In production, use proper hashing
      'role': selectedRole.value,
    });
    await box.write('localUsers', localUsers);
  }

  Future<void> _syncPendingSignups() async {
    if (!isOnline.value) return;

    final pendingSignups = box.read('pendingSignups') ?? [];
    if (pendingSignups.isEmpty) return;

    for (var signupData in pendingSignups) {
      if (signupData['synced'] == true) continue;

      try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/auth/signup"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(signupData),
        ).timeout(apiTimeout);

        if (response.statusCode == 201) {
          signupData['synced'] = true;
          await box.write('pendingSignups', pendingSignups);
        }
      } catch (e) {
        print("Failed to sync signup: $e");
      }
    }

    // Remove synced signups
    final remainingSignups = pendingSignups.where((s) => s['synced'] == false).toList();
    await box.write('pendingSignups', remainingSignups);
  }

  Future<void> signupUser() async {
    if (selectedRole.value.isEmpty) {
      _showSnackbar("Error", "Please select a role");
      return;
    }

    if (nameController.text.isEmpty) {
      _showSnackbar("Error", "Please enter your name");
      return;
    }

    if (phoneController.text.isEmpty) {
      _showSnackbar("Error", "Please enter your phone number");
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

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/signup"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "phone": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "role": selectedRole.value,
        }),
      ).timeout(const Duration(seconds: 10));

      final responseBody = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        _showSnackbar("Success", "Account created successfully", isError: false);
        Get.find<LoginController>().emailController.text = emailController.text.trim();
        Get.find<LoginController>().passwordController.text = passwordController.text.trim();
        Get.find<LoginController>().selectedRole.value = selectedRole.value;
        Get.toNamed('/login');
      } else {
        _showSnackbar(
            "Signup Failed",
            responseBody['message'] ?? "Registration failed",
            isError: true
        );
      }
    } on SocketException {
      _showSnackbar("Network Error", "No internet connection", isError: true);
    } on TimeoutException {
      _showSnackbar("Timeout", "Server took too long to respond", isError: true);
    } catch (e) {
      _showSnackbar("Error", "An unexpected error occurred", isError: true);
      print("Signup error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleOfflineSignup() async {
    await _storeOfflineSignup();
    _showSnackbar("Offline Mode", "Account will be created when online", isError: false);
    // Auto-login with offline credentials
    Get.find<LoginController>().emailController.text = emailController.text.trim();
    Get.find<LoginController>().passwordController.text = passwordController.text.trim();
    Get.find<LoginController>().selectedRole.value = selectedRole.value;
    Get.toNamed('/login');
  }

  Future<void> syncPendingSignups() async {
    if (!isOnline.value) return;

    final pendingSignups = box.read('pendingSignups') ?? [];
    if (pendingSignups.isEmpty) return;

    for (var signupData in pendingSignups) {
      if (signupData['synced'] == true) continue;

      try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/auth/signup"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(signupData),
        ).timeout(apiTimeout);

        if (response.statusCode == 201) {
          signupData['synced'] = true;
          await box.write('pendingSignups', pendingSignups);
        }
      } catch (e) {
        print("Failed to sync signup: $e");
      }
    }

    // Remove synced signups
    final remainingSignups = pendingSignups.where((s) => s['synced'] == false).toList();
    await box.write('pendingSignups', remainingSignups);
  }
}