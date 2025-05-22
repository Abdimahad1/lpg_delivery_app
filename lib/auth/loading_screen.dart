import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class LoadingController extends GetxController {
  final RxBool showMainContent = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Delay before showing content
    Timer(const Duration(seconds: 2), () {
      showMainContent.value = true;
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
    // Initialize animation
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
              'LGP DELIVERY',
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
                  'LGP Needs Your Location',
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
                    Get.toNamed('/login');  // GetX navigation
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