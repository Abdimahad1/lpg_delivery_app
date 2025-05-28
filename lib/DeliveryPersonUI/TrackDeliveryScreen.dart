import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/track_delivery_controller.dart';

class TrackDeliveryScreen extends StatelessWidget {
  const TrackDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackDeliveryController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("Track Delivery", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map takes ~45% of the screen height
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: controller.deliveryLocation.value,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  Obx(() => MarkerLayer(
                    markers: [
                      Marker(
                        width: 60,
                        height: 60,
                        point: controller.deliveryLocation.value,
                        child: const Icon(Icons.location_pin, size: 50, color: Colors.red),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),

          // Details container
          Expanded(
            child: Obx(() => Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/images/cylinder.png', width: 35, height: 35),
                      const SizedBox(width: 10),
                      const Text("6kg Cylinder",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text("Abdi Hussein",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text("Hodan-Taleex-Mog-Som",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        controller.deliveryStatus.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: controller.deliveryStatus.value == "Delivered"
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20),
                      const SizedBox(width: 8),
                      Text("EST Time: ${controller.estTime.value}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Spacer(),
                  if (controller.deliveryStatus.value != "Delivered")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.markAsDelivered,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Mark as Delivered",
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    )
                  else
                    const Center(
                      child: Text("✅ Delivery Completed",
                          style: TextStyle(fontSize: 16, color: Colors.green)),
                    ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }
}
