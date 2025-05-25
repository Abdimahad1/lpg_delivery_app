import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationItem {
  final String senderName;
  final String message;
  final bool isRead;

  NotificationItem({
    required this.senderName,
    required this.message,
    this.isRead = false,
  });
}

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final RxList<NotificationItem> _notifications = <NotificationItem>[
    NotificationItem(senderName: "MOG Gas", message: "Macmiilkeenna sharafta leh Gaaska waxa uu kuu imaan doona muddo ka yar 20 daqiiqo"),
    NotificationItem(senderName: "MOG Gas", message: "Macmiilkeenna sharafta leh Gaaska waxa uu kuu imaan doona muddo ka yar 20 daqiiqo"),
    NotificationItem(senderName: "MOG Gas", message: "Macmiilkeenna sharafta leh Gaaska waxa uu kuu imaan doona muddo ka yar 20 daqiiqo"),
    NotificationItem(senderName: "MOG Gas", message: "Macmiilkeenna sharafta leh Gaaska waxa uu kuu imaan doona muddo ka yar 20 daqiiqo"),
  ].obs;

  void markAllAsRead() {
    _notifications.value = _notifications.map((n) => NotificationItem(senderName: n.senderName, message: n.message, isRead: true)).toList();
  }

  void deleteAll() {
    _notifications.clear();
  }

  void markAsRead(int index) {
    _notifications[index] = NotificationItem(
      senderName: _notifications[index].senderName,
      message: _notifications[index].message,
      isRead: true,
    );
  }

  void deleteNotification(int index) {
    _notifications.removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E3EFF),
      body: SafeArea(
        child: Column(
          children: [


            // 🔘 Global Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _globalActionButton("Read All", Colors.black, Colors.white, onTap: markAllAsRead),
                  const SizedBox(width: 8),
                  _globalActionButton("Filter By", Colors.yellow, Colors.black),
                  const SizedBox(width: 8),
                  _globalActionButton("Delete all", Colors.red, Colors.white, onTap: deleteAll),
                ],
              ),
            ),

            // 🔔 Notification List
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
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
                          // Sender Avatar
                          const CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 24,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          // Content
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
                                        child: CircleAvatar(
                                          radius: 5,
                                          backgroundColor: Colors.red,
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(notification.message,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _actionButton("Delete", Colors.red, () => deleteNotification(index)),
                                    const SizedBox(width: 8),
                                    if (!notification.isRead)
                                      _actionButton("Read", Colors.blue, () => markAsRead(index)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
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
