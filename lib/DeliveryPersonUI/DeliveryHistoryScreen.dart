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

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      status: 'Delivered',
    ),
    Task(
      product: '6kg Cylinder',
      customer: 'Abdi Ali',
      address: 'Hodan-Taleex-Mog-Som',
      date: 'May-18-2025',
      status: 'Cancelled',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Task> _getFilteredTasks(String status) =>
      allTasks.where((task) => task.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_getFilteredTasks('Delivered')),
          _buildTaskList(_getFilteredTasks('Cancelled')),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks available."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final color = task.status == 'Delivered' ? Colors.green : Colors.grey;

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
                            fontWeight: FontWeight.bold, fontSize: 16)),
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
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
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
}
