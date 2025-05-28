import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class LoadingController extends GetxController {
  final RxBool showMainContent = false.obs;
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();

    // Show animation after 2 seconds
    Timer(const Duration(seconds: 2), () {
      showMainContent.value = true;
    });

    // Redirect after 3 seconds based on saved user role
    Timer(const Duration(seconds: 3), () {
      final token = box.read('token');
      final role = box.read('role');

      if (token != null && role != null) {
        switch (role) {
          case "Customer":
            Get.offAllNamed('/customer-home');
            break;
          case "Vendor":
            Get.offAllNamed('/vendor-home');
            break;
          case "DeliveryPerson":
            Get.offAllNamed('/delivery-home');
            break;
          default:
            Get.offAllNamed('/login');
        }
      } else {
        Get.offAllNamed('/login');
      }
    });
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> bounceAnimation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoadingController());

    return Scaffold(
      backgroundColor: const Color(0xFF3E3EFF),
      body: Obx(() => controller.showMainContent.value
          ? Column(
        children: [
          const SizedBox(height: 100),
          const Center(
            child: Text(
              'LPG DELIVERY',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                ScaleTransition(
                  scale: bounceAnimation,
                  child: Image.asset(
                    'assets/images/delivery.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, size: 100, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  'LPG Needs Your Location',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Get.toNamed('/login');
                  },
                  child: const Text(
                    'NEXT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator(color: Colors.white))),
    );
  }
}
