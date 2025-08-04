import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';
import 'OrderDetailScreen.dart';
import 'package:intl/intl.dart';
import 'vendor_home_screen.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> unassignedOrders = [];
  List<Map<String, dynamic>> acceptedOrders = [];
  List<Map<String, dynamic>> deliveredOrders = [];

  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> acceptedTasks = [];
  List<Map<String, dynamic>> deliveredTasks = [];

  bool isLoading = true;
  late TabController _tabController;
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Today', 'This Week'];

  Future<bool> _onBackPressed() async {
    Get.off(() => const VendorHomeScreen());
    return false; // prevent default pop
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      }

      await fetchAllTasks();
      applyFilter();
    } catch (e) {
      print("❌ Vendor Orders Fetch Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAllTasks() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse("${baseUrl}tasks/all"),
        headers: {"Authorization": "Bearer $token"},
      );

      final res = jsonDecode(response.body);
      if (res['success'] == true && res['data'] != null) {
        allTasks = List<Map<String, dynamic>>.from(res['data']);
        acceptedTasks =
            allTasks.where((task) => task['status'] == 'Accepted').toList();
        deliveredTasks =
            allTasks.where((task) => task['status'] == 'Delivered').toList();
      }
    } catch (e) {
      print("❌ Fetch all tasks error: $e");
    }
  }

  void applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    List<Map<String, dynamic>> filtered = [];
    if (selectedFilter == 'Today') {
      filtered = allOrders.where((order) {
        final ts =
            DateTime.tryParse(order['timestamp'] ?? '') ?? DateTime(2000);
        return ts.year == today.year &&
            ts.month == today.month &&
            ts.day == today.day;
      }).toList();
    } else if (selectedFilter == 'This Week') {
      filtered = allOrders.where((order) {
        final ts =
            DateTime.tryParse(order['timestamp'] ?? '') ?? DateTime(2000);
        return ts.isAfter(startOfWeek);
      }).toList();
    } else {
      filtered = [...allOrders];
    }

    unassignedOrders = filtered.where((order) {
      final orderId = order['_id'];
      final assignedStatus = allTasks
          .firstWhereOrNull((task) => task['orderId'] == orderId)?['status'] ??
          '';
      return assignedStatus == '' || assignedStatus == 'Pending';
    }).toList();

    acceptedOrders = filtered.where((order) {
      return acceptedTasks.any((task) => task['orderId'] == order['_id']);
    }).toList();

    deliveredOrders = filtered.where((order) {
      return deliveredTasks.any((task) => task['orderId'] == order['_id']);
    }).toList();

    setState(() {});
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedFilter,
        items: filters
            .map((f) => DropdownMenuItem(value: f, child: Text("Filter: $f")))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            selectedFilter = value;
            applyFilter();
          }
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildTabView(List<Map<String, dynamic>> orders) {
    return orders.isEmpty
        ? const Center(child: Text("No orders found"))
        : RefreshIndicator(
      onRefresh: fetchVendorOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    String formattedDate = 'Unknown date';
    bool isTodayOrder = false;

    try {
      if (order['timestamp'] != null) {
        final ts = DateTime.parse(order['timestamp']);
        formattedDate = DateFormat('MMM d, yyyy').format(ts);

        final today = DateTime.now();
        isTodayOrder = ts.year == today.year &&
            ts.month == today.month &&
            ts.day == today.day;
      }
    } catch (_) {}

    final paymentStatus =
    order['waafiResponse']?['responseMsg']?.toString().toUpperCase() ==
        'RCS_SUCCESS'
        ? 'RC Success'
        : 'Success';

    final amount = (order['amount'] ?? 0).toDouble();

    final deliveryTask = allTasks.firstWhereOrNull(
          (task) => task['orderId'] == order['_id'],
    );

    final deliveryPersonName = deliveryTask?['deliveryPersonName'] ?? 'Not assigned';

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
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
          ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order['productTitle'] ?? 'No Title',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isTodayOrder)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "NEW",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (order['userLocation'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order['userLocation'],
                            style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text("Delivery By: $deliveryPersonName",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16,
                          color: paymentStatus == 'RC Success'
                              ? Colors.orange
                              : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        paymentStatus,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: paymentStatus == 'RC Success'
                              ? Colors.orange
                              : Colors.green,
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
                const Icon(Icons.monetization_on,
                    color: Colors.deepPurple, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(); // or Navigator.pop(context)
        return false; // prevent default system back
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF3E3EFF),
          title: const Text("Orders", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(), // ✅ returns to prev screen
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Unassigned (${unassignedOrders.length})"),
              Tab(text: "Accepted (${acceptedOrders.length})"),
              Tab(text: "Delivered (${deliveredOrders.length})"),
            ],
          ),
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
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildTabView(unassignedOrders),
                  buildTabView(acceptedOrders),
                  buildTabView(deliveredOrders),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
