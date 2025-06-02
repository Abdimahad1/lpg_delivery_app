import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'TrackDeliveryScreen.dart';
import 'DeliveryMainScreen.dart';

class DeliveryTasksScreen extends StatefulWidget {
  final int? returnTabIndex;

  const DeliveryTasksScreen({super.key, this.returnTabIndex});

  @override
  State<DeliveryTasksScreen> createState() => _DeliveryTasksScreenState();
}

class _DeliveryTasksScreenState extends State<DeliveryTasksScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Delivery Tasks", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (widget.returnTabIndex != null) {
              Get.offAll(() => DeliveryMainScreen(initialTabIndex: widget.returnTabIndex!));
            } else {
              Get.back();
            }
          },
        ),
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
        final tasks = controller.tasks;

        if (tasks.isEmpty) {
          return const Center(child: Text("No delivery tasks found."));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchMyTasks();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final status = task['status'] ?? 'Pending';
              final statusColor = getStatusColor(status);
              final isAccepted = status == 'Accepted';

              return GestureDetector(
                onTap: isAccepted
                    ? () async {
                  await Get.to(() => const TrackDeliveryScreen(), arguments: task);
                  await controller.fetchMyTasks(); // 🔁 Refresh after return
                  setState(() {});
                }
                    : null,
                child: Opacity(
                  opacity: isAccepted ? 1.0 : 0.6,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border(left: BorderSide(color: statusColor, width: 5)),
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
                              Text(task['product']?.toString() ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(task['customer']?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
                              Text(task['address']?.toString() ?? '-',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                                  if (status == 'Delivered') ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle, color: Colors.green),
                                  ],
                                ],
                              ),

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
