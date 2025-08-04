import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'DeliveryMainScreen.dart';

class NewTasksScreen extends StatefulWidget {
  const NewTasksScreen({super.key});

  @override
  State<NewTasksScreen> createState() => _NewTasksScreenState();
}

class _NewTasksScreenState extends State<NewTasksScreen> {
  final TaskController controller = Get.put(TaskController());

  @override
  void initState() {
    super.initState();
    controller.fetchMyTasks();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Delivered':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  bool isToday(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _onBackPressed() async {
    Get.back();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("New Tasks", style: TextStyle(color: Colors.black)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () async {
                await controller.fetchMyTasks();
              },
            ),
          ],
        ),
        body: Obx(() {
          final todayTasks = controller.tasks.where((task) {
            final createdAt = task['createdAt'] ?? '';
            return isToday(createdAt);
          }).toList();

          if (todayTasks.isEmpty) {
            return const Center(child: Text("No tasks available for today"));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.fetchMyTasks();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: todayTasks.length,
              itemBuilder: (context, index) {
                final task = todayTasks[index];
                final status = task['status'] ?? 'Pending';
                final taskId = task['_id'];
                final statusColor = getStatusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border(
                      left: BorderSide(color: statusColor, width: 5),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/cylinder.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['product'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                )),
                            const SizedBox(height: 4),
                            Text(task['customer'] ?? '',
                                style: const TextStyle(fontSize: 14)),
                            Text(task['address'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text("Status: ",
                                    style: TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (status == 'Pending')
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      await controller.updateTaskStatus(taskId, 'Accepted');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✅ Task Accepted')),
                                      );
                                      Get.to(() => DeliveryMainScreen(initialTabIndex: 1));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text("Accept",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await controller.updateTaskStatus(taskId, 'Rejected');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('❌ Task Rejected')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text("Reject",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                            else if (status == 'Delivered')
                              const Text("✅ Marked as Delivered",
                                  style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
