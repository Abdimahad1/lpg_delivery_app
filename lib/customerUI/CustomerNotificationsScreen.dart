import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
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
        _notifications.value = List<NotificationItem>.from(
          res['data'].map(
                (n) => NotificationItem(
              senderName: n['senderName'],
              message: n['message'],
              isRead: n['isRead'],
              id: n['_id'],
              createdAt: DateTime.parse(n['createdAt']),
            ),
          ),
        );
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
    await http.patch(
      Uri.parse("${baseUrl}notifications/mark-all-read"),
      headers: {"Authorization": "Bearer $token"},
    );
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();
  }

  void deleteAll() async {
    final confirmed = await _showConfirmationDialog(
      "Delete All Notifications",
      "Are you sure you want to delete all notifications?",
    );
    if (!confirmed) return;

    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    await http.delete(
      Uri.parse("${baseUrl}notifications/delete-all"),
      headers: {"Authorization": "Bearer $token"},
    );
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();
  }

  void markAsRead(int index) async {
    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    final id = _notifications[index].id;

    await http.patch(
      Uri.parse("${baseUrl}notifications/mark-read/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();
  }

  void deleteNotification(int index) async {
    final confirmed = await _showConfirmationDialog(
      "Delete Notification",
      "Are you sure you want to delete this notification?",
    );
    if (!confirmed) return;

    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;
    final id = _notifications[index].id;

    await http.delete(
      Uri.parse("${baseUrl}notifications/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    await fetchNotifications();
    Get.find<ProfileController>().fetchNotificationCount();
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _notifications
        : _notifications.where((n) => n.isRead == (_filter == 'Read')).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.filter, color: Colors.black),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Notifications')),
              const PopupMenuItem(value: 'Unread', child: Text('Unread Only')),
              const PopupMenuItem(value: 'Read', child: Text('Read Only')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.tick_circle,
                    label: 'Mark All Read',
                    color: const Color(0xFF3E3EFF),
                    onTap: markAllAsRead,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Iconsax.trash,
                    label: 'Delete All',
                    color: Colors.red,
                    onTap: deleteAll,
                  ),
                ),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3E3EFF)),
              ),
            )
                : Obx(() => filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 'All'
                        ? "No notifications yet"
                        : "No ${_filter.toLowerCase()} notifications",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: fetchNotifications,
              color: const Color(0xFF3E3EFF),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final notification = filtered[index];
                  return _buildNotificationCard(notification, index);
                },
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: notification.isRead ? Colors.grey[50] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => markAsRead(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3EFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.notification,
                      color: const Color(0xFF3E3EFF),
                      size: 20,
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
                              notification.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM d, h:mm a').format(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Iconsax.trash,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => deleteNotification(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}