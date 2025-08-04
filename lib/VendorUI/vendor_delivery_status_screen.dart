import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';

class VendorDeliveryStatusScreen extends StatefulWidget {
  const VendorDeliveryStatusScreen({super.key});

  @override
  State<VendorDeliveryStatusScreen> createState() =>
      _VendorDeliveryStatusScreenState();
}

class _VendorDeliveryStatusScreenState
    extends State<VendorDeliveryStatusScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  String selectedFilter = 'Today';
  final List<String> filters = ['Today', 'This Week', 'All'];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<bool> _onBackPressed() async {
    Get.back(); // Return to previous screen
    return false; // Prevent default back action
  }

  Future<void> fetchTasks() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse("${baseUrl}tasks/all"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final raw = List<Map<String, dynamic>>.from(res['data']);

        final usersRes = await http.get(
          Uri.parse("${baseUrl}profile/all-delivery-persons"),
          headers: {'Authorization': 'Bearer $token'},
        );

        Map<String, String> deliveryNames = {};
        if (usersRes.statusCode == 200) {
          final usersData = jsonDecode(usersRes.body)['data'];
          for (var user in usersData) {
            deliveryNames[user['userId']] = user['name'];
          }
        }

        allTasks = raw.map((task) {
          return {
            "product": task['product'] ?? '',
            "name": deliveryNames[task['deliveryPersonId']] ?? "Unknown",
            "status": _mapStatus(task['status']),
            "createdAt": task['createdAt'],
          };
        }).toList();

        applyFilter();
      }
    } catch (e) {
      print("❌ Error fetching tasks: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    filteredTasks = allTasks.where((task) {
      final created = DateTime.tryParse(task['createdAt'] ?? '') ?? now;

      if (selectedFilter == 'Today') {
        return created.isAfter(today);
      } else if (selectedFilter == 'This Week') {
        return created.isAfter(startOfWeek);
      } else {
        return true;
      }
    }).toList();

    setState(() {});
  }

  String _mapStatus(String? status) {
    switch (status) {
      case 'Accepted':
        return 'Out For Delivery';
      case 'Rejected':
        return 'Rejected';
      case 'Delivered':
        return 'Delivered';
      default:
        return 'Pending';
    }
  }

  String _generateReference(int index) =>
      'ORD-${(index + 1).toString().padLeft(4, '0')}';

  Widget _buildStatusDot(String status) {
    final color = {
      "Pending": Colors.grey,
      "Accepted": Colors.blue,
      "Rejected": Colors.red,
      "Out For Delivery": Colors.orange,
      "Delivered": Colors.green,
    }[status] ?? Colors.black;

    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 4),
        Text(status,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget buildDeliveryTab() {
    return filteredTasks.isEmpty
        ? const Center(child: Text("No deliveries found"))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/cylinder.png',
                      width: 30, height: 30),
                  const SizedBox(width: 10),
                  Text(task['product'],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text("Order: ${_generateReference(index)}",
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Image.asset('assets/images/bike.png',
                      width: 26, height: 26),
                  const SizedBox(width: 8),
                  const Text("Assigned To:",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text(task['name']),
                ],
              ),
              const SizedBox(height: 10),
              _buildStatusDot(task['status']),
            ],
          ),
        );
      },
    );
  }

  Widget buildStarRating(int count) {
    double rating = (count / 10.0).clamp(1.0, 5.0);
    int fullStars = rating.floor();
    bool hasHalfStar = rating - fullStars >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  Widget buildPersonalTab() {
    final Map<String, int> deliveryCounts = {};
    for (var task in filteredTasks) {
      if (task['status'] == 'Delivered') {
        deliveryCounts[task['name']] = (deliveryCounts[task['name']] ?? 0) + 1;
      }
    }

    final entries = deliveryCounts.entries.toList();

    return entries.isEmpty
        ? const Center(child: Text("No delivered tasks found"))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4)
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blueAccent,
                child: Text(entry.key[0],
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("${entry.value} Deliveries"),
                    const SizedBox(height: 4),
                    buildStarRating(entry.value),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFE5EC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF3E3EFF),
            foregroundColor: Colors.white,
            centerTitle: true,
            title: const Text("Delivery & Personal Status"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(), // ✅ return to previous screen
            ),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: "Delivery Status"),
                Tab(text: "Personal Status"),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  items: filters
                      .map((f) => DropdownMenuItem(
                      value: f, child: Text("Filter: $f")))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedFilter = val;
                        applyFilter();
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                  children: [
                    buildDeliveryTab(),
                    buildPersonalTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
