import 'package:flutter/material.dart';

class VendorDeliveryStatusScreen extends StatelessWidget {
  const VendorDeliveryStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Status"),
        backgroundColor: const Color(0xFF3E3EFF),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "This is the Delivery Status screen.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
