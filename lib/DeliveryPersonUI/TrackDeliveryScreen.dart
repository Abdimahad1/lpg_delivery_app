import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';
import '../controllers/track_delivery_controller.dart';

class TrackDeliveryScreen extends StatelessWidget {
  const TrackDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackDeliveryController());
    final rawArgs = Get.arguments;
    if (rawArgs == null || rawArgs is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text("❌ No task data provided")),
      );
    }
    final Map<String, dynamic> task = rawArgs;
    controller.initialize(task);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Track Delivery",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: controller.refreshAllData,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Map Section
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  height: controller.showMap.value
                      ? MediaQuery.of(context).size.height * 0.5
                      : 0,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: controller.mapCenter.value,
                            initialZoom: 15,
                          ),

                          children: [
                            TileLayer(
                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.example.app',
                            ),
                            if (controller.myLocation.value != null &&
                                controller.customerLocation.value != null)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      latlng.LatLng(
                                        controller.myLocation.value!.latitude,
                                        controller.myLocation.value!.longitude,
                                      ),
                                      latlng.LatLng(
                                        controller.customerLocation.value!.latitude,
                                        controller.customerLocation.value!.longitude,
                                      ),
                                    ],
                                    strokeWidth: 4,
                                    color: Colors.blue.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                if (controller.vendorLocation.value != null)
                                  Marker(
                                    point: latlng.LatLng(
                                      controller.vendorLocation.value!.latitude,
                                      controller.vendorLocation.value!.longitude,
                                    ),
                                    width: 100,
                                    height: 100,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.store,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "Vendor",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (controller.customerLocation.value != null)
                                  Marker(
                                    point: latlng.LatLng(
                                      controller.customerLocation.value!.latitude,
                                      controller.customerLocation.value!.longitude,
                                    ),
                                    width: 100,
                                    height: 100,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "Customer",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (controller.myLocation.value != null)
                                  Marker(
                                    point: latlng.LatLng(
                                      controller.myLocation.value!.latitude,
                                      controller.myLocation.value!.longitude,
                                    ),
                                    width: 100,
                                    height: 100,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.person_pin_circle,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "You",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: controller.centerMapOnCurrentLocation,
                            child: const Icon(Icons.my_location, color: Colors.blue),
                          ),
                        ),
                        if (controller.isRefreshing.value)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ),

              // Map Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.toggleMapVisibility,
                      icon: Icon(
                        controller.showMap.value
                            ? Icons.map_outlined
                            : Icons.map,
                        size: 20,
                      ),
                      label: Text(
                        controller.showMap.value ? "Hide Map" : "Show Map",
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                    if (controller.showMap.value)
                      ElevatedButton.icon(
                        onPressed: controller.refreshMap,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text("Refresh", style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                  ],
                ),
              ),

              // Delivery Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/cylinder.png',
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['product'] is Map
                                    ? task['product']['name'] ?? '-'
                                    : task['product'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Order #${task['orderId'] ?? 'N/A'}",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24, thickness: 1),

                    // Delivery Details
                    _buildDetailRow(
                      icon: Icons.location_on,
                      title: "Delivery Address",
                      value: task['address'] ?? 'Not specified',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.timer,
                      title: "Estimated Time",
                      value: controller.estTime.value,
                      valueColor: controller.estTime.value == "Calculating..."
                          ? Colors.grey
                          : Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.social_distance,
                      title: "Distance",
                      value: "${controller.distanceValue.value} km",
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.local_shipping,
                      title: "Status",
                      value: controller.deliveryStatus.value,
                      valueColor: controller.deliveryStatus.value == "Delivered"
                          ? Colors.green
                          : Colors.orange,
                    ),

                    const Divider(height: 24, thickness: 1),

                    // Action Buttons
                    if (controller.deliveryStatus.value != "Delivered")
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.markAsDelivered,
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text("Mark Delivered"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: controller.estTime.value != "Calculating..."
                                ? () => _sendNotification(controller)
                                : null,
                            icon: const Icon(Icons.notifications, size: 20),
                            label: const Text("Notify"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Delivery Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendNotification(TrackDeliveryController controller) async {
    try {
      final product = controller.task['product'];
      final productName = product is Map ? product['name'] ?? '' : product.toString();
      final time = controller.estTime.value.replaceAll(" min", " daqiiqo");

      final message =
          "Macamiilkeena sharafta leh $productName waxa uu kuu imaan doona muddo ka yar $time";
      final customerId = controller.task['customerId'];

      final response = await controller.sendNotification(message, customerId);

      if (response['success'] == true) {
        Get.snackbar(
          "✔️ Success",
          "Notification sent successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception(response['message'] ?? "Failed to send notification");
      }
    } catch (e) {
      Get.snackbar(
        "❌ Error",
        "Failed to send notification: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}