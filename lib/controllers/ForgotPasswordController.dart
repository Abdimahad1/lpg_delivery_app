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
  // Form controllers
  final emailController = TextEditingController();
  final otpControllers = List.generate(6, (index) => TextEditingController());
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // State variables
  final isLoading = false.obs;
  final isOnline = false.obs;
  final resetToken = ''.obs;
  final serverTimeOffset = Rx<Duration?>(null);

  final String _apiBaseUrl = "${baseUrl}password-reset";

  @override
  void onInit() {
    _checkInternetConnection();
    _checkServerTime();
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

  // Helper to clear all form fields
  void clearAllFields() {
    emailController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    resetToken.value = '';
    for (var controller in otpControllers) {
      controller.clear();
    }
    _log('All form fields cleared', emoji: '🧹');
  }

  // Debug logging helper
  void _log(String message, {String emoji = 'ℹ️', bool isError = false}) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = isError ? '❌ ERROR:' : '$emoji DEBUG:';
    debugPrint('[$timestamp] $prefix $message');
  }

  // Show snackbar
  void _showSnackbar(String title, String message, {bool isError = true}) {
    _log('Showing snackbar: $title - $message', emoji: '📢');
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

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await NetworkService.isConnected();
      isOnline.value = result;
      _log('Internet connection: ${result ? "Online" : "Offline"}',
          emoji: result ? '🌐' : '⚠️');
    } catch (e) {
      _log('Error checking internet: $e', emoji: '❌', isError: true);
      isOnline.value = false;
    }
  }

  Future<void> _checkServerTime() async {
    try {
      _log('Checking server time synchronization...', emoji: '⏱️');
      final uri = Uri.parse("${baseUrl}server-time");
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final serverData = jsonDecode(response.body);
        final serverTime = DateTime.parse(serverData['isoString']);
        final localTime = DateTime.now();
        final offset = localTime.difference(serverTime);

        serverTimeOffset.value = offset;
        _log('Server time: ${serverTime.toIso8601String()}', emoji: '⏱️');
        _log('Local time: ${localTime.toIso8601String()}', emoji: '⏱️');
        _log('Time difference: ${offset.inSeconds} seconds', emoji: '⏱️');

        if (offset.inSeconds.abs() > 30) {
          _log('WARNING: Significant time difference detected!', emoji: '⚠️');
        }
      }
    } catch (e) {
      _log('Could not verify server time: $e', emoji: '⚠️');
    }
  }

  // Step 1: Send OTP
  Future<bool> sendOtp() async {
    final email = emailController.text.trim().toLowerCase();
    _log('Starting sendOtp process for email: $email', emoji: '📧');

    if (!_validateEmail(email)) {
      _log('Invalid email format: $email', emoji: '❌', isError: true);
      _showSnackbar("Error", "Please enter a valid email");
      return false;
    }

    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection");
      return false;
    }

    isLoading.value = true;
    final uri = Uri.parse("$_apiBaseUrl/send-otp");
    final payload = {"email": email};

    try {
      final response = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackbar("Success", "If this email exists in our system, you'll receive an OTP", isError: false);
        _log('OTP sent successfully', emoji: '✅');
        return true;
      } else {
        _showSnackbar("Error", body['message'] ?? "Failed to send OTP");
        _log('OTP send failed: ${body['message']}', emoji: '❌', isError: true);
      }
    } catch (e) {
      _log('Error sending OTP: $e', emoji: '❌', isError: true);
      _showSnackbar("Error", "Could not send OTP");
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Step 2: Verify OTP
  Future<bool> verifyOtp() async {
    final email = emailController.text.trim().toLowerCase();
    final otp = otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      _showSnackbar("Error", "Please enter a 6-digit OTP");
      return false;
    }

    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection");
      return false;
    }

    isLoading.value = true;
    final uri = Uri.parse("$_apiBaseUrl/verify-otp");
    final payload = {"email": email, "otp": otp};

    try {
      final response = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        resetToken.value = body['resetToken'] ?? '';
        _showSnackbar("Success", "OTP verified successfully", isError: false);
        _log('OTP verified successfully. Reset token: ${resetToken.value}', emoji: '✅');
        return true;
      } else {
        _showSnackbar("Error", body['message'] ?? "Invalid OTP");
        _log('OTP verification failed: ${body['message']}', emoji: '❌', isError: true);
      }
    } catch (e) {
      _log('Error verifying OTP: $e', emoji: '❌', isError: true);
      _showSnackbar("Error", "Could not verify OTP");
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // Step 3: Reset password
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
      return false;
    }

    await _checkInternetConnection();
    if (!isOnline.value) {
      _showSnackbar("Network Error", "No internet connection");
      return false;
    }

    isLoading.value = true;
    final uri = Uri.parse("$_apiBaseUrl/reset-password");
    final payload = {
      "resetToken": resetToken.value,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    };

    try {
      final response = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showSnackbar("Success", "Password reset successfully", isError: false);
        _log('Password reset successful', emoji: '✅');
        clearAllFields(); // Clear fields after successful reset
        return true;
      } else {
        _showSnackbar("Error", body['message'] ?? "Failed to reset password");
        _log('Password reset failed: ${body['message']}', emoji: '❌', isError: true);
      }
    } catch (e) {
      _log('Error resetting password: $e', emoji: '❌', isError: true);
      _showSnackbar("Error", "Could not reset password");
    } finally {
      isLoading.value = false;
    }
    return false;
  }
}
