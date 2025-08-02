// ✅ Enhanced AssignDeliveryScreen with retry-safe error handling and snackbar feedback
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';

class AssignDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const AssignDeliveryScreen({super.key, required this.order});

  @override
  State<AssignDeliveryScreen> createState() => _AssignDeliveryScreenState();
}

class _AssignDeliveryScreenState extends State<AssignDeliveryScreen> {
  List<Map<String, dynamic>> deliveryPeople = [];
  List<Map<String, dynamic>> filtered = [];

  Set<String> assignedToThisOrder = {};
  Map<String, Map<String, dynamic>> activeTaskDetails = {};

  bool isLoading = true;
  bool showOnlyAvailable = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      await fetchAllAssignedTasks();
      await fetchDeliveryPeople();
    } catch (e) {
      showError("Initial load failed. Please check your internet or ngrok tunnel.");
    }
  }

  Future<void> fetchAllAssignedTasks() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse('${baseUrl}tasks/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final allTasks = List<Map<String, dynamic>>.from(res['data']);
        final orderId = widget.order['_id'];

        // Clear previous data
        assignedToThisOrder.clear();
        activeTaskDetails.clear();

        for (final task in allTasks) {
          final personId = task['deliveryPersonId']?.toString();
          if (personId == null) continue;

          if (task['orderId'] == orderId) {
            assignedToThisOrder.add(personId);
          }

          // Only consider Pending or Accepted tasks as active
          if (task['status'] == 'Pending' || task['status'] == 'Accepted') {
            activeTaskDetails[personId] = task;
          }
        }
      } else {
        showError("Failed to load tasks: ${response.statusCode}");
      }
    } catch (e) {
      showError("❌ Error fetching assigned tasks: $e");
    }
  }

  Future<void> fetchDeliveryPeople() async {
    setState(() => isLoading = true);
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse('${baseUrl}profile/all-delivery-persons'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        deliveryPeople = List<Map<String, dynamic>>.from(res['data']);
        applyFilters();
      } else {
        showError("Failed to load delivery people: ${response.statusCode}");
      }
    } catch (e) {
      showError("❌ Error fetching delivery people: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    filtered = deliveryPeople.where((person) {
      final name = person['name']?.toString().toLowerCase() ?? '';
      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final personId = person['userId'].toString();
      final hasTask = activeTaskDetails.containsKey(personId);

      return matchesSearch && (!showOnlyAvailable || !hasTask);
    }).toList();
    setState(() {});
  }

  void assignDeliveryPerson(Map<String, dynamic> person) async {
    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;

    final payload = {
      "deliveryPersonId": person['userId'],
      "order": {
        "orderId": widget.order['_id'],
        "product": widget.order['productTitle'],
        "customer": profileController.userName.value,
        "address": widget.order['userLocation']
      }
    };

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}tasks/assign"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        await fetchAllAssignedTasks();
        applyFilters();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Assigned!"),
            content: Text("✅ Successfully assigned to ${person['name']}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFF3E3EFF))),
              ),
            ],
          ),
        );
      } else {
        showError("Failed to assign task: ${response.body}");
      }
    } catch (e) {
      showError("❌ Assign failed: $e");
    }
  }

  void showError(String msg) {
    Get.snackbar("Error", msg, backgroundColor: Colors.red[100], colorText: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDECEC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E3EFF),
        title: const Text('Assign Delivery Person'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      searchQuery = val;
                      applyFilters();
                    },
                    decoration: const InputDecoration(
                      hintText: "Search Delivery Person",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    const Text("Available Only", style: TextStyle(fontSize: 12)),
                    Switch(
                      value: showOnlyAvailable,
                      onChanged: (val) {
                        setState(() => showOnlyAvailable = val);
                        applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("No delivery persons found"))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final person = filtered[index];
                  final personId = person['userId'].toString();
                  final task = activeTaskDetails[personId];
                  final isAssigned = assignedToThisOrder.contains(personId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/bike.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    person['name'] ?? 'Unnamed',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (task != null) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Current Task"),
                                            content: Text(
                                              "📦 Product: ${task['product']}\n📍 Address: ${task['address']}",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Close"),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              task != null
                                  ? const Text(
                                "Busy on another task",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                                  : const Text(
                                "Available",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        isAssigned
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text("Assigned", style: TextStyle(color: Colors.black54)),
                        )
                            : task != null
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text("Busy", style: TextStyle(color: Colors.orange)),
                        )
                            : ElevatedButton(
                          onPressed: () => assignDeliveryPerson(person),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E3EFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            elevation: 4,
                          ),
                          child: const Text("Assign", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
