import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/ForgotPasswordController.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ForgotPasswordController _controller = Get.put(ForgotPasswordController());
  int _currentStep = 1; // 1: email, 2: OTP, 3: new password
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleOtpChange(String value, int index) {
    if (value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
      _controller.otpControllers[index].text = '';
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
  }

  void _handleOtpBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: const Color(0xFF4A90E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4A90E2),
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 20),

                // Step Content
                _buildCurrentStepContent(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: _currentStep > index ? Colors.green : Colors.grey,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildOtpStep();
      case 3:
        return _buildNewPasswordStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reset Password",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Enter your email to receive a verification code",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        // Email input
        TextField(
          controller: _controller.emailController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email, color: Colors.grey),
            hintText: "Your email address",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 15,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 25),
        // Send OTP button
        ElevatedButton(
          onPressed: () async {
            try {
              bool result = await _controller.sendOtp();
              if (result) {
                setState(() {
                  _currentStep = 2;
                });
              }
            } catch (e) {
              debugPrint('Error in sendOtp: $e');
            }
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "SEND OTP",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter OTP",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We sent a 6-digit code to ${_controller.emailController.text}",
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        // OTP input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
                (index) => SizedBox(
              width: 50,
              child: TextField(
                controller: _controller.otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A90E2),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) => _handleOtpChange(value, index),
                onSubmitted: (value) {
                  if (index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else {
                    _verifyOtpAndProceed();
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Verify OTP button
        ElevatedButton(
          onPressed: _verifyOtpAndProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "VERIFY OTP",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Resend OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive code?",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () async {
                try {
                  await _controller.sendOtp();
                } catch (e) {
                  debugPrint('Error in resend OTP: $e');
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF4A90E2),
                  ),
                  SizedBox(width: 5),
                  Text(
                    "Resend OTP",
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _verifyOtpAndProceed() async {
    try {
      bool result = await _controller.verifyOtp();
      if (result) {
        setState(() {
          _currentStep = 3;
        });
      }
    } catch (e) {
      debugPrint('Error in verifyOtp: $e');
    }
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "New Password",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Create a new secure password (minimum 6 characters)",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        // New password
        TextField(
          controller: _controller.newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.grey),
            hintText: "New password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 15,
            ),
          ),
        ),
        const SizedBox(height: 25),
        // Confirm password
        TextField(
          controller: _controller.confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.grey),
            hintText: "Confirm new password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 15,
            ),
          ),
        ),
        const SizedBox(height: 25),
        // Change password button
        ElevatedButton(
          onPressed: () async {
            try {
              bool result = await _controller.resetPassword();
              if (result) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              debugPrint('Error in resetPassword: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "CHANGE PASSWORD",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}