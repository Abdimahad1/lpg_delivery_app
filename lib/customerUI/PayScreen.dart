import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PayScreen extends StatelessWidget {
  const PayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E3EFF), // Blue background for outer area
      body: Column(
        children: [
          // 🔙 Back button section (blue curved top)
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

          // 🧾 Payment options (rounded container with white background)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.yellow, // White background for card area
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  // Larger payment cards in a centered column
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLargePaymentCard("assets/images/evcplus.png"),
                        const SizedBox(height: 30),
                        _buildLargePaymentCard("assets/images/edahab.png"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargePaymentCard(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // Rounded corners for full card
      child: Container(
        height: 180,
        width: 250,
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover, // Fill the card with the image
        ),
      ),
    );
  }
}
