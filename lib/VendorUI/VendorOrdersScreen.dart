import 'package:flutter/material.dart';

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Orders"),
        backgroundColor: const Color(0xFF3E3EFF),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "This is the Vendor Orders screen.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
