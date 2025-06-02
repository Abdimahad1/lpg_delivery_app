import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';
import 'AssignDeliveryScreen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool isAssigned = false;
  String? assignedTo;
  String? taskId;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    preloadAssignmentStatus();
  }

  Future<void> preloadAssignmentStatus() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;
      final orderId = widget.order['_id'];

      final taskResponse = await http.get(
        Uri.parse("${baseUrl}tasks/all"),
        headers: {'Authorization': 'Bearer $token'},
      );

      final userResponse = await http.get(
        Uri.parse("${baseUrl}profile/all-delivery-persons"),
        headers: {'Authorization': 'Bearer $token'},
      );

      Map<String, String> deliveryNames = {};
      if (userResponse.statusCode == 200) {
        final usersData = jsonDecode(userResponse.body)['data'];
        for (var user in usersData) {
          deliveryNames[user['userId']] = user['name'];
        }
      }

      if (taskResponse.statusCode == 200) {
        final res = jsonDecode(taskResponse.body);
        final allTasks = List<Map<String, dynamic>>.from(res['data']);

        final task = allTasks.firstWhere(
              (t) => t['orderId'] == orderId,
          orElse: () => {},
        );

        if (task.isNotEmpty) {
          setState(() {
            isAssigned = true;
            taskId = task['_id'];
            assignedTo = deliveryNames[task['deliveryPersonId']] ?? "Unknown";
          });
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load assignment data");
    } finally {
      setState(() => isLoaded = true);
    }
  }

  Future<void> unassignTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Unassign"),
        content: Text("Are you sure you want to unassign $assignedTo from this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Unassign", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || taskId == null) return;

    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.delete(
        Uri.parse("${baseUrl}tasks/$taskId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          isAssigned = false;
          assignedTo = null;
          taskId = null;
        });
        Get.snackbar("Unassigned", "Successfully unassigned this order.",
            backgroundColor: Colors.green[100], colorText: Colors.black);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignDeliveryScreen(order: widget.order),
          ),
        );
      } else {
        Get.snackbar("Error", "Failed to unassign: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Error", "Unassign failed: $e");
    }
  }

  Widget buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.order['productTitle'] ?? 'No Title';
    final String invoiceId = widget.order['invoiceId'] ?? 'N/A';
    final String location = widget.order['userLocation'] ?? 'Unknown';
    final String date = widget.order['timestamp'] ?? '';
    final String formattedDate = date.isNotEmpty
        ? DateTime.tryParse(date) != null
        ? "${DateTime.parse(date).toLocal().toString().split(' ')[0]}"
        : 'Invalid Date'
        : 'No Date';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F2F2),
      appBar: AppBar(
        title: const Text("Order Detail"),
        backgroundColor: const Color(0xFF3E3EFF),
        centerTitle: true,
      ),
      body: isLoaded
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.order['productImage'] != null &&
                  widget.order['productImage'].toString().contains(',')
                  ? Image.memory(
                base64Decode(widget.order['productImage'].split(',').last),
                height: 140,
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) =>
                const Icon(Icons.image, size: 100),
              )
                  : const Icon(Icons.image, size: 100),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDetailItem("📦 Order No:", invoiceId),
                  buildDetailItem("📅 Date:", formattedDate),
                  buildDetailItem("📍 Location:", location),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1),
                  const SizedBox(height: 12),
                  const Text(
                    "Delivery Assignment",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isAssigned)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Assigned To: $assignedTo",
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: unassignTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text("Unassign",
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignDeliveryScreen(order: widget.order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E3EFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          elevation: 6,
                        ),
                        child: const Text(
                          "Assign",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}