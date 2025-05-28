import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'NewTasksScreen.dart';

class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Home", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Icon(Icons.notifications_active, color: Colors.orange, size: 28),
                ],
              ),
              const SizedBox(height: 30),

              // Delivery image
              Center(
                child: Image.asset(
                  "assets/images/delivery.png", // Replace with your own image
                  height: 150,
                ),
              ),
              const SizedBox(height: 20),

              // Welcome
              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "View and manage your delivery tasks",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Buttons
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildActionButton(
                    color: Colors.green,
                    icon: Icons.assignment_turned_in,
                    label: "New Tasks",
                    onTap: () {
                      Get.to(() => const NewTasksScreen()); // ✅ Navigate to New Tasks
                    },
                  ),
                  _buildActionButton(
                    color: Colors.blue,
                    icon: Icons.my_location,
                    label: "Track Delivery",
                    onTap: () {
                      // Replace with your actual screen
                    //  Get.to(() => const TrackDeliveryScreen());
                    },
                  ),
                  _buildActionButton(
                    color: Colors.purple,
                    icon: Icons.history,
                    label: "History",
                    onTap: () {
                      // Replace with your actual screen
                    //  Get.to(() => const DeliveryHistoryScreen());
                    },
                  ),
                ],
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
