import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class PayScreen extends StatelessWidget {
  final String vendorName;
  final String amount;

  PayScreen({
    super.key,
    required this.vendorName,
    required this.amount,
  });

  final TextEditingController _accountNoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E4F4),
      body: Column(
        children: [
          // Top bar with back button
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE4E4F4),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 77),
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "Pay The Gas Payment",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vendor: $vendorName",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Amount: \$$amount",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "SELECT PAYMENT OPTION",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Payment options
                    _buildPaymentOption(context, "assets/images/evcplus.png", "EVC Plus"),
                    const SizedBox(height: 20),
                    _buildPaymentOption(context, "assets/images/edahab.png", "Edahab"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, String imagePath, String label) {
    return InkWell(
      onTap: () {
        _showPhoneInputPopup(context, label);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  void _showPhoneInputPopup(BuildContext context, String label) {
    _accountNoController.clear();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enter Your Phone Number",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accountNoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "e.g. 2526xxxxxxx",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final phone = _accountNoController.text.trim();
                        if (phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter your phone number")),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close dialog

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final response = await http.post(
                            Uri.parse("${baseUrl}pay"),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              "accountNo": phone,
                              "amount": amount,
                              "invoiceId": "INV-${DateTime.now().millisecondsSinceEpoch}",
                              "description": "Test payment for Gas",
                            }),
                          );



                          Navigator.pop(context); // Remove loading indicator
                          final resData = jsonDecode(response.body);

                          if (resData['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Payment successful")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("❌ ${resData['message']}")),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context); // Remove loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Failed: ${e.toString()}")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E3EFF),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Send Money",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),

                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.cancel, color: Colors.grey, size: 28),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
