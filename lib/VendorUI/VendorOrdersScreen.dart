import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';
import 'OrderDetailScreen.dart';
import 'package:intl/intl.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;
  String filterOption = 'All';

  @override
  void initState() {
    super.initState();
    fetchVendorOrders();
  }

  Future<void> fetchVendorOrders() async {
    setState(() => isLoading = true);

    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse("${baseUrl}payment/vendor-orders"),
        headers: {"Authorization": "Bearer $token"},
      );

      final res = jsonDecode(response.body);
      if (res['success'] == true && res['transactions'] != null) {
        allOrders = List<Map<String, dynamic>>.from(res['transactions'] ?? []);
        applyFilter();
      } else {
        allOrders = [];
        filteredOrders = [];
      }
    } catch (e) {
      print("❌ Vendor Orders Fetch Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    setState(() {
      if (filterOption == 'Today') {
        filteredOrders = allOrders.where((order) {
          final ts = DateTime.tryParse(order['timestamp'] ?? '') ?? DateTime(2000);
          return ts.year == today.year && ts.month == today.month && ts.day == today.day;
        }).toList();
      } else if (filterOption == 'This Week') {
        filteredOrders = allOrders.where((order) {
          final ts = DateTime.tryParse(order['timestamp'] ?? '') ?? DateTime(2000);
          return ts.isAfter(startOfWeek);
        }).toList();
      } else {
        filteredOrders = [...allOrders];
      }
    });
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String formattedDate = 'Unknown date';
    try {
      if (order['timestamp'] != null) {
        formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(order['timestamp']));
      }
    } catch (_) {}

    final paymentStatus = order['waafiResponse']?['responseMsg']?.toString().toUpperCase() == 'RCS_SUCCESS'
        ? 'RC Success'
        : 'Success';

    final amount = (order['amount'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: order['productImage'] != null &&
                  order['productImage'].toString().contains(',')
                  ? Image.memory(
                base64Decode(order['productImage'].split(',').last),
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, size: 70, color: Colors.grey),
              )
                  : const Icon(Icons.image, size: 70, color: Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['productTitle'] ?? 'No Title',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (order['userLocation'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order['userLocation'],
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16,
                          color: paymentStatus == 'RC Success' ? Colors.orange : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        paymentStatus,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: paymentStatus == 'RC Success' ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  "\$${amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.monetization_on, color: Colors.deepPurple, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: filterOption,
        items: const [
          DropdownMenuItem(value: 'All', child: Text('All Orders')),
          DropdownMenuItem(value: 'Today', child: Text("Today's Orders")),
          DropdownMenuItem(value: 'This Week', child: Text("This Week")),
        ],
        onChanged: (value) {
          if (value != null) {
            filterOption = value;
            applyFilter();
          }
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E3EFF),
        title: const Text("Orders", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: fetchVendorOrders,
            icon: const Icon(Icons.refresh, color: Colors.white),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildFilterDropdown(),
          Expanded(
            child: filteredOrders.isEmpty
                ? const Center(child: Text("No orders found for selected filter"))
                : RefreshIndicator(
              onRefresh: fetchVendorOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(filteredOrders[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
