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
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchDeliveryPeople();
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
        final list = List<Map<String, dynamic>>.from(res['data']);
        deliveryPeople = list;
        filtered = [...deliveryPeople];
      }
    } catch (e) {
      print("❌ Error fetching delivery people: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void filterList(String value) {
    setState(() {
      searchQuery = value;
      filtered = deliveryPeople
          .where((p) => p['name']
          .toString()
          .toLowerCase()
          .contains(value.toLowerCase()))
          .toList();
    });
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

    final response = await http.post(
      Uri.parse("${baseUrl}tasks/assign"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
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
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("❌ Failed to assign task"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
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
            // 🔍 Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
              ),
              child: TextField(
                onChanged: filterList,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search Delivery Person',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No delivery persons found'))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final person = filtered[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12, blurRadius: 6)
                      ],
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
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                person['name'] ?? 'Unnamed',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Available",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              assignDeliveryPerson(person),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF3E3EFF),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            elevation: 4,
                          ),
                          child: const Text(
                            "Assign",
                            style: TextStyle(color: Colors.white),
                          ),
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
