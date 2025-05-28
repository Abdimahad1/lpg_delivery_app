import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  DateTimeRange? selectedDateRange;
  String searchQuery = '';
  String selectedAmountFilter = 'All';

  @override
  void initState() {
    super.initState();
    allTransactions = getMockTransactions();
    filteredTransactions = List.from(allTransactions);
  }

  List<Map<String, dynamic>> getMockTransactions() {
    return [
      {
        "referenceId": "ref-1748420131525",
        "invoiceId": "INV-1748420128067",
        "accountNo": "252613797852",
        "amount": 0.02,
        "description": "Test payment for Gas",
        "timestamp": "2025-05-28T08:15:31.525Z",
        "status": "completed"
      },
      {
        "referenceId": "ref-1748419129494",
        "invoiceId": "INV-1748419120001",
        "accountNo": "252618827482",
        "amount": 1.00,
        "description": "LPG Purchase",
        "timestamp": "2025-05-27T18:10:44.525Z",
        "status": "completed"
      },
      {
        "referenceId": "ref-1748418120001",
        "invoiceId": "INV-1748418120001",
        "accountNo": "252612345678",
        "amount": 2.50,
        "description": "Cooking Gas Refill",
        "timestamp": "2025-05-26T12:30:00.000Z",
        "status": "failed"
      },
      {
        "referenceId": "ref-1748417120001",
        "invoiceId": "INV-1748417120001",
        "accountNo": "252698765432",
        "amount": 3.00,
        "description": "Industrial Gas Cylinder",
        "timestamp": "2025-05-25T09:45:00.000Z",
        "status": "pending"
      },
    ];
  }

  void filterTransactions() {
    setState(() {
      filteredTransactions = allTransactions.where((tx) {
        final date = DateTime.parse(tx['timestamp']);

        final matchesDate = selectedDateRange == null ||
            (date.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                date.isBefore(selectedDateRange!.end.add(const Duration(days: 1))));

        final matchesSearch = searchQuery.isEmpty ||
            tx['invoiceId'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            tx['description'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            tx['accountNo'].toLowerCase().contains(searchQuery.toLowerCase());

        final matchesAmount = selectedAmountFilter == 'All' ||
            (selectedAmountFilter == '< \$1' && tx['amount'] < 1) ||
            (selectedAmountFilter == '\$1 - \$5' && tx['amount'] >= 1 && tx['amount'] <= 5) ||
            (selectedAmountFilter == '> \$5' && tx['amount'] > 5);

        return matchesDate && matchesSearch && matchesAmount;
      }).toList();
    });
  }

  void showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      selectedDateRange = picked;
      filterTransactions();
    }
  }

  Widget buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = 'COMPLETED';
        break;
      case 'failed':
        color = Colors.red;
        text = 'FAILED';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'PENDING';
        break;
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E3EFF),
        title: const Text("Transaction History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: showDateFilter,
          )
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      searchQuery = val;
                      filterTransactions();
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search invoice, description, or number...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedAmountFilter,
                  items: ['All', '< \$1', '\$1 - \$5', '> \$5']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      selectedAmountFilter = val;
                      filterTransactions();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text("No transactions found"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final date = DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(tx['timestamp']));
                final status = tx['status'] ?? 'pending';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Color(0xFF3E3EFF)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text("Invoice: ${tx['invoiceId']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            "\$${tx['amount'].toStringAsFixed(2)}",
                            style: TextStyle(
                              color: status == 'failed'
                                  ? Colors.red
                                  : status == 'pending'
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(tx['accountNo'], style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(tx['description'], style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
