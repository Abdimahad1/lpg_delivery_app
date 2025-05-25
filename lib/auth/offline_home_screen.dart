import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sync_controller.dart';

class OfflineHomeScreen extends StatelessWidget {
  final SyncController syncController = Get.put(SyncController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline Mode"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => syncController.syncAllData(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "You're in Offline Mode",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              "Some features may be limited",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Obx(() => syncController.isSyncing.value
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () => syncController.syncAllData(),
              child: const Text("Try to Sync Now"),
            )),
          ],
        ),
      ),
    );
  }
}