import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var selectedRole = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    final args = Get.arguments;
    if (args != null && args is Map) {
      emailController.text = args["email"] ?? '';
      passwordController.text = args["password"] ?? '';
      selectedRole.value = args["role"] ?? '';
    }
    super.onInit();
  }

  void _showSnackbar(String title, String message, {bool isError = true}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
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

  Future<void> loginUser() async {
    if (selectedRole.value.isEmpty) {
      _showSnackbar("Error", "Please select a role");
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final role = _formatRole(selectedRole.value);

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar("Error", "Email and password are required");
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final result = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final roleFromServer = result['user']['role'];

          _showSnackbar("Success", "Welcome, ${result['user']['name']}", isError: false);

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
        } else {
          _showSnackbar("Login Failed", result['message'] ?? "Unknown error");
        }
      } else {
        _showSnackbar("Error", "Unexpected response: ${response.body}");
      }
    } catch (e) {
      _showSnackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
