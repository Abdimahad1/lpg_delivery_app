import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';

class NotificationItem {
  final String senderName;
  final String message;
  final bool isRead;
  final String id;
  final DateTime createdAt;

  NotificationItem({
    required this.senderName,
    required this.message,
    required this.isRead,
    required this.id,
    required this.createdAt,
  });
}

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final RxList<NotificationItem> _notifications = <NotificationItem>[].obs;
  bool isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse("${baseUrl}notifications/my"),
        headers: {"Authorization": "Bearer $token"},
      );

      final res = jsonDecode(response.body);
      if (res['success'] == true && res['data'] != null) {
        _notifications.value = List<NotificationItem>.from(res['data'].map((n) => NotificationItem(
          senderName: n['senderName'],
          message: n['message'],
          isRead: n['isRead'],
          id: n['_id'],
          createdAt: DateTime.parse(n['createdAt']),
        )));
      }
    } catch (e) {
      print("❌ Notification Fetch Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void markAllAsRead() async {
    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    await http.patch(Uri.parse("${baseUrl}notifications/mark-all-read"), headers: {
      "Authorization": "Bearer $token",
    });
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();

  }

  void deleteAll() async {
    final confirmed = await _showConfirmation("Are you sure you want to delete all notifications?");
    if (!confirmed) return;

    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    await http.delete(Uri.parse("${baseUrl}notifications/delete-all"), headers: {
      "Authorization": "Bearer $token",
    });
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();

  }

  void markAsRead(int index) async {
    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    final id = _notifications[index].id;

    await http.patch(Uri.parse("${baseUrl}notifications/mark-read/$id"), headers: {
      "Authorization": "Bearer $token",
    });
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();

  }

  void deleteNotification(int index) async {
    final confirmed = await _showConfirmation("Are you sure you want to delete this notification?");
    if (!confirmed) return;

    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    final id = _notifications[index].id;

    await http.delete(Uri.parse("${baseUrl}notifications/$id"), headers: {
      "Authorization": "Bearer $token",
    });
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();

  }

  Future<bool> _showConfirmation(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _notifications
        : _notifications.where((n) => n.isRead == (_filter == 'Read')).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF3E3EFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _globalActionButton("Read All", Colors.black, Colors.white, onTap: markAllAsRead),
                  const SizedBox(width: 8),
                  _globalActionButton("Filter", Colors.orange, Colors.black, onTap: () => _showFilterDialog()),
                  const SizedBox(width: 8),
                  _globalActionButton("Delete All", Colors.red, Colors.white, onTap: deleteAll),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Obx(() => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final notification = filtered[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          radius: 24,
                          child: Icon(Icons.notifications, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(notification.senderName,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (!notification.isRead)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: CircleAvatar(radius: 5, backgroundColor: Colors.red),
                                    )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notification.message,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM d, h:mm a').format(notification.createdAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _actionButton("Delete", Colors.red, () => deleteNotification(index)),
                                  const SizedBox(width: 8),
                                  if (!notification.isRead)
                                    _actionButton("Mark Read", Colors.green, () => markAsRead(index)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text("All"), onTap: () => _setFilter("All")),
          ListTile(title: const Text("Unread"), onTap: () => _setFilter("Unread")),
          ListTile(title: const Text("Read"), onTap: () => _setFilter("Read")),
        ],
      ),
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
    Navigator.pop(context);
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _globalActionButton(String label, Color bg, Color text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
