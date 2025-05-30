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
    final task = Get.arguments as Map<String, dynamic>;
    controller.initialize(task);

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
      body: Obx(() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: controller.toggleMapVisibility,
                    icon: Icon(controller.showMap.value ? Icons.visibility_off : Icons.visibility),
                    label: Text(controller.showMap.value ? "Hide Map" : "Show Map"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (controller.showMap.value)
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: controller.refreshMap,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (controller.showMap.value)
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: controller.centerMapOnCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text("My Location"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (controller.showMap.value)
            Obx(() => AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Container(
                key: ValueKey(controller.refreshTrigger.value),
                height: MediaQuery.of(context).size.height * 0.45,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: controller.mapCenter.value,
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          if (controller.myLocation.value != null &&
                              controller.customerLocation.value != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [
                                    controller.myLocation.value!,
                                    controller.customerLocation.value!
                                  ],
                                  strokeWidth: 4,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (controller.vendorLocation.value != null)
                                Marker(
                                  point: controller.vendorLocation.value!,
                                  width: 80,
                                  height: 60,
                                  child: Column(
                                    children: const [
                                      Icon(Icons.store, color: Colors.blue, size: 36),
                                      Text("Vendor", style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              if (controller.customerLocation.value != null)
                                Marker(
                                  point: controller.customerLocation.value!,
                                  width: 80,
                                  height: 60,
                                  child: Column(
                                    children: const [
                                      Icon(Icons.location_pin, color: Colors.red, size: 36),
                                      Text("Customer", style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              if (controller.myLocation.value != null)
                                Marker(
                                  point: controller.myLocation.value!,
                                  width: 80,
                                  height: 60,
                                  child: Column(
                                    children: const [
                                      Icon(Icons.person_pin_circle, color: Colors.green, size: 36),
                                      Text("Me", style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (controller.isRefreshing.value)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
            )),
          Expanded(
            child: Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/cylinder.png', width: 35, height: 35),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(task['product'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(task['address'] ?? '',
                            style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        controller.deliveryStatus.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
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
                      Text("EST: ${controller.estTime.value}",
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.social_distance, size: 20),
                      const SizedBox(width: 8),
                      Text("Distance: ${controller.distanceValue.value} km",
                          style: const TextStyle(fontWeight: FontWeight.w500)),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Mark as Delivered",
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    )
                  else
                    const Center(
                      child: Text("\u2705 Delivery Completed",
                          style: TextStyle(fontSize: 16, color: Colors.green)),
                    ),
                ],
              ),
            ),
          )
        ],
      )),
    );
  }
}
