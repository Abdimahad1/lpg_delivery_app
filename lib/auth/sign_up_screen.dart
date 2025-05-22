import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({Key? key}) : super(key: key);

  final SignUpController controller = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E3EFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
              Image.asset('assets/images/delivery.png', height: 100),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "SIGN UP",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(),
                    const SizedBox(height: 15),
                    _buildInputField(controller.nameController, "Enter your Name"),
                    const SizedBox(height: 15),
                    _buildInputField(controller.phoneController, "Enter your Phone Number"),
                    const SizedBox(height: 15),
                    _buildInputField(controller.emailController, "Enter your Email"),
                    const SizedBox(height: 15),
                    _buildInputField(controller.passwordController, "Enter your Password", obscure: true),
                    const SizedBox(height: 15),
                    _buildInputField(controller.confirmPasswordController, "Confirm Password", obscure: true),
                    const SizedBox(height: 20),
                    Obx(() => controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: () async {
                        if (_validateFields()) {
                          FocusScope.of(context).unfocus();
                          await controller.signUpUser();
                          _clearFields();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("SIGN UP", style: TextStyle(color: Colors.white)),
                    )),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed('/login');
                        },
                        child: const Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            children: [
                              TextSpan(
                                text: "LOG IN",
                                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateFields() {
    if (controller.nameController.text.isEmpty) {
      Get.snackbar("Error", "Name is required");
      return false;
    }
    if (controller.phoneController.text.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(controller.phoneController.text)) {
      Get.snackbar("Error", "Valid phone number is required");
      return false;
    }
    if (controller.emailController.text.isEmpty || !GetUtils.isEmail(controller.emailController.text)) {
      Get.snackbar("Error", "Valid email is required");
      return false;
    }
    if (controller.passwordController.text.isEmpty) {
      Get.snackbar("Error", "Password is required");
      return false;
    }
    if (controller.confirmPasswordController.text.isEmpty ||
        controller.confirmPasswordController.text != controller.passwordController.text) {
      Get.snackbar("Error", "Passwords must match");
      return false;
    }
    return true;
  }

  void _clearFields() {
    controller.nameController.clear();
    controller.phoneController.clear();
    controller.emailController.clear();
    controller.passwordController.clear();
    controller.confirmPasswordController.clear();
  }

  Widget _buildInputField(TextEditingController controller, String hint, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Obx(() => DropdownButtonFormField<String>(
        value: controller.selectedRole.value.isEmpty ? null : controller.selectedRole.value,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: const Text("Role"),
        items: const [
          DropdownMenuItem(value: "Customer", child: Text("Customer")),
          DropdownMenuItem(value: "Vendor", child: Text("Vendor")),
          DropdownMenuItem(value: "DeliveryPerson", child: Text("Delivery Person")),
        ],
        onChanged: (value) {
          controller.selectedRole.value = value!;
        },
      )),
    );
  }
}
