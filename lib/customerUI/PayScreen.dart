import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PayScreen extends StatelessWidget {
  final String vendorName;
  final String vendorPhone;
  final String amount;

  const PayScreen({
    super.key,
    required this.vendorName,
    required this.vendorPhone,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E3EFF),
      body: Column(
        children: [
          // Back button
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF3E3EFF),
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),

          // Main payment content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white38,
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
                    Text(
                      "Pay to $vendorName",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Phone: $vendorPhone", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      "Amount: \$$amount",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "PAY BY",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          _buildLargePaymentCard("assets/images/evcplus.png"),
                          const SizedBox(height: 30),
                          _buildLargePaymentCard("assets/images/edahab.png"),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargePaymentCard(String imagePath) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background shadow
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 180,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        // Image card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 180,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
