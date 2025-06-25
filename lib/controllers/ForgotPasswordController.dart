import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';
import '../auth/network_service.dart';

class ForgotPasswordController extends GetxController {
  // Email & OTP fields
  final emailController = TextEditingController();
  final otpControllers = List.generate(6, (index) => TextEditingController());
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // State
  final isLoading = false.obs;
  final isOnline = false.obs;
  final resetToken = ''.obs;

  final String _apiBaseUrl = "${baseUrl}password-reset";

  @override
  void onInit() {
    _checkInternetConnection();
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // Snackbar
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

  // Validate Email
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // Check Internet
  Future<void> _checkInternetConnection() async {
    isOnline.value = await NetworkService.isConnected();
  }

  // Step 1: Send OTP
  Future<bool> sendOtp() async {
    final email = emailController.text.trim();

    if (!_validateEmail(email)) {
      _showSnackbar("Error", "Please enter a valid email");
      return false;
    }

    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      return false;
    }

    isLoading.value = true;

    final uri = Uri.parse("$_apiBaseUrl/send-otp");
    final payload = {"email": email};

    print("📡 Sending OTP...");
    print("➡️ POST: $uri");
    print("📦 Payload: $payload");

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("⬅️ Status: ${response.statusCode}");
      print("⬅️ Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackbar("Success", "OTP sent to your email", isError: false);
        return true;
      } else {
        _showSnackbar("Error", responseBody['message'] ?? "Failed to send OTP");
        return false;
      }
    } on SocketException catch (e) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      print("❌ SocketException: $e");
    } on TimeoutException catch (e) {
      _showSnackbar("Timeout", "Server took too long to respond", isError: true);
      print("❌ TimeoutException: $e");
    } catch (e, stack) {
      _showSnackbar("Error", "An unexpected error occurred", isError: true);
      print("❌ Unexpected Exception: $e");
      print("🪵 Stack Trace:\n$stack");
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Step 2: Verify OTP
  Future<bool> verifyOtp() async {
    final otp = otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showSnackbar("Error", "Please enter the complete 6-digit OTP");
      return false;
    }

    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      return false;
    }

    isLoading.value = true;

    final uri = Uri.parse("$_apiBaseUrl/verify-otp");
    final payload = {
      "email": emailController.text.trim(),
      "otp": otp,
    };

    print("📡 Verifying OTP...");
    print("➡️ POST: $uri");
    print("📦 Payload: $payload");

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("⬅️ Status: ${response.statusCode}");
      print("⬅️ Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        resetToken.value = responseBody['resetToken'] ?? '';
        print("✅ Saved resetToken: ${resetToken.value}");

        _showSnackbar("Success", "OTP verified successfully", isError: false);
        return true;
      } else {
        _showSnackbar("Error", responseBody['message'] ?? "Failed to verify OTP");
        return false;
      }
    } on SocketException catch (e) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      print("❌ SocketException: $e");
    } on TimeoutException catch (e) {
      _showSnackbar("Timeout", "Server took too long to respond", isError: true);
      print("❌ TimeoutException: $e");
    } catch (e, stack) {
      _showSnackbar("Error", "An unexpected error occurred", isError: true);
      print("❌ Unexpected Exception: $e");
      print("🪵 Stack Trace:\n$stack");
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Step 3: Reset Password
  Future<bool> resetPassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showSnackbar("Error", "Password must be at least 6 characters");
      return false;
    }

    if (newPassword != confirmPassword) {
      _showSnackbar("Error", "Passwords do not match");
      return false;
    }

    if (resetToken.value.isEmpty) {
      _showSnackbar("Error", "Reset token missing. Please verify OTP first.");
      print("⚠️ Reset token missing");
      return false;
    }

    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      return false;
    }

    isLoading.value = true;

    final uri = Uri.parse("$_apiBaseUrl/reset-password");
    final payload = {
      "resetToken": resetToken.value,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    };

    print("📡 Resetting Password...");
    print("➡️ POST: $uri");
    print("📦 Payload: $payload");

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      print("⬅️ Status: ${response.statusCode}");
      print("⬅️ Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackbar("Success", "Password reset successfully", isError: false);
        return true;
      } else {
        _showSnackbar("Error", responseBody['message'] ?? "Failed to reset password");
        return false;
      }
    } on SocketException catch (e) {
      _showSnackbar("Network Error", "No internet connection", isError: true);
      print("❌ SocketException: $e");
    } on TimeoutException catch (e) {
      _showSnackbar("Timeout", "Server took too long to respond", isError: true);
      print("❌ TimeoutException: $e");
    } catch (e, stack) {
      _showSnackbar("Error", "An unexpected error occurred", isError: true);
      print("❌ Unexpected Exception: $e");
      print("🪵 Stack Trace:\n$stack");
    } finally {
      isLoading.value = false;
    }
    return false;
  }
}
