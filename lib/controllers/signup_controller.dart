import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SignUpController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  var selectedRole = ''.obs;
  final isLoading = false.obs;

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

  Future<void> signUpUser() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final role = _formatRole(selectedRole.value);

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar("Error", "All fields are required");
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar("Error", "Passwords do not match");
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "phone": phone,
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final result = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackbar("Success", "Account created successfully!", isError: false);
          Get.offAllNamed('/login', arguments: {
            "email": email,
            "password": password,
            "role": role
          });
        } else {
          _showSnackbar("Sign Up Failed", result['message'] ?? "Unknown error");
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
