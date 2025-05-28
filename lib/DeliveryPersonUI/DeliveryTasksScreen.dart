import 'package:flutter/material.dart';

class Task {
  final String product;
  final String customer;
  final String address;
  final String date;
  final String status;

  const Task({
    required this.product,
    required this.customer,
    required this.address,
    required this.date,
    required this.status,
  });
}

class DeliveryTasksScreen extends StatelessWidget {
  const DeliveryTasksScreen({Key? key}) : super(key: key);

  static const List<Task> allTasks = [
    Task(
      product: '6kg Cylinder',
      customer: 'Abdi Hussein',
      address: 'Hodan-Taleex-Mog-Som',
      date: 'May-21-2025',
      status: 'Pending',
    ),
    Task(
      product: '6kg Cylinder',
      customer: 'Abdi Hassan',
      address: 'Hodan-Taleex-Mog-Som',
      date: 'May-19-2025',
      status: 'Pending',
    ),
    Task(
      product: '6kg Cylinder',
      customer: 'Abdi Ali',
      address: 'Hodan-Taleex-Mog-Som',
      date: 'May-18-2025',
      status: 'Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Task> pendingTasks =
    allTasks.where((t) => t.status == 'Pending').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Tasks",
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: pendingTasks.isEmpty
          ? const Center(child: Text("No pending tasks."))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: pendingTasks.length,
        itemBuilder: (context, index) {
          final task = pendingTasks[index];
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
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.product,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(task.customer,
                          style: const TextStyle(fontSize: 14)),
                      Text(task.address,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(task.date,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              offset: Offset(2, 2),
                              blurRadius: 4)
                        ],
                      ),
                      child: const Text(
                        "Pending",
                        style:
                        TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
