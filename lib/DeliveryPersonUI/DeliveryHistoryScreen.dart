import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> allTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMyTasks();
  }

  /// Back button handler — physical phone button
  Future<bool> _onBackPressed() async {
    Get.back();
    return false; // Prevent default pop
  }

  Future<void> fetchMyTasks() async {
    setState(() => isLoading = true);
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse("${baseUrl}tasks/my-tasks"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        allTasks = List<Map<String, dynamic>>.from(res['data']);
      } else {
        allTasks = [];
      }
    } catch (e) {
      print("❌ Fetch tasks error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredTasks(String status) =>
      allTasks.where((task) => task['status'] == status).toList();

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks available."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final color = task['status'] == 'Delivered' ? Colors.green : Colors.grey;
        final dateStr = task['createdAt'] ?? '';
        final date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr)?.toLocal() : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/cylinder.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task['product'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(task['customer'] ?? '',
                        style: const TextStyle(fontSize: 14)),
                    Text(task['address'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    date != null
                        ? "${date.day}-${date.month}-${date.year}"
                        : 'Unknown Date',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task['status'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(), // UI back arrow goes back instantly
          ),
          title: const Text('Task History', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          elevation: 1,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: 'Delivered'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildTaskList(_getFilteredTasks('Delivered')),
            _buildTaskList(_getFilteredTasks('Rejected')),
          ],
        ),
      ),
    );
  }
}
