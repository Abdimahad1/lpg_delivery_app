import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'TrackDeliveryScreen.dart';

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
    return switch (status) {
      'Accepted' => Colors.green,
      'Rejected' => Colors.red,
      _ => Colors.orange,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("New Tasks", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              await controller.fetchMyTasks();
              setState(() {});
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.tasks.isEmpty) {
          return const Center(child: Text("No tasks available"));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchMyTasks();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.tasks.length,
            itemBuilder: (context, index) {
              final task = controller.tasks[index];
              final status = task['status'] ?? 'Pending';
              final taskId = task['_id'];
              final statusColor = getStatusColor(status);

              return Dismissible(
                key: ValueKey(taskId),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (_) async {
                  controller.updateTaskStatus(taskId, 'Accepted');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Task Accepted')),
                  );
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.green,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => const TrackDeliveryScreen(), arguments: task);
                  },
                  child: Container(
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
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
                              Row(
                                children: [
                                  Opacity(
                                    opacity: status == 'Accepted' ? 0.4 : 1.0,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        controller.updateTaskStatus(
                                            taskId, 'Accepted');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                            content: Text(
                                                '✅ Task Accepted')));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text("Accept",
                                          style:
                                          TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Reject Task"),
                                          content: const Text(
                                              "Are you sure you want to reject this task?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("No"),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Yes"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        controller.updateTaskStatus(
                                            taskId, 'Rejected');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                            content: Text(
                                                '❌ Task Rejected')));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text("Reject",
                                        style:
                                        TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
