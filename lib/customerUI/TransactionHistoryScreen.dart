import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final Widget? backRoute;

  const TransactionHistoryScreen({super.key, this.backRoute});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> allTransactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  bool isLoading = true;

  DateTimeRange? selectedDateRange;
  String searchQuery = '';
  String selectedAmountFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() => isLoading = true);
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse("${baseUrl}payment/history"),
        headers: {"Authorization": "Bearer $token"},
      );

      final res = jsonDecode(response.body);
      if (res['success'] == true && res['transactions'] != null) {
        allTransactions = List<Map<String, dynamic>>.from(res['transactions']);
        filterTransactions();
      } else {
        allTransactions = [];
        filteredTransactions = [];
      }
    } catch (e) {
      print("\u274c Error fetching transactions: $e");
      allTransactions = [];
      filteredTransactions = [];
    } finally {
      setState(() => isLoading = false);
    }
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

  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Transaction Receipt')),
          ...filteredTransactions.map((tx) {
            final timestamp = DateTime.parse(tx['timestamp']);
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Invoice: ${tx['invoiceId']}"),
                  pw.Text("Amount: \$${tx['amount'].toStringAsFixed(2)}"),
                  pw.Text("Status: ${tx['status']}"),
                  pw.Text("Account No: ${tx['accountNo']}"),
                  pw.Text("Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)}"),
                  pw.Text("Description: ${tx['description']}"),
                  pw.Divider(),
                ],
              ),
            );
          }).toList()
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  String normalizeStatus(String? raw) => (raw ?? 'pending').toLowerCase();

  Widget buildStatusChip(String? status) {
    final normalized = normalizeStatus(status);
    Color color;
    String text;

    switch (normalized) {
      case 'success':
        color = Colors.green;
        text = 'SUCCESS';
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
        text = normalized.toUpperCase();
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

  Icon getStatusIcon(String? status) {
    final normalized = normalizeStatus(status);
    switch (normalized) {
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'failed':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'pending':
        return const Icon(Icons.hourglass_bottom, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E3EFF),
        title: const Text("Transaction History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.backRoute != null) {
              Get.off(widget.backRoute!);
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: exportToPDF),
          IconButton(icon: const Icon(Icons.filter_alt, color: Colors.white), onPressed: showDateFilter),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: fetchTransactions),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                final date = DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(DateTime.parse(tx['timestamp']));
                final status = tx['status'];

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
                          getStatusIcon(status),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Invoice: ${tx['invoiceId']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            "\$${tx['amount'].toStringAsFixed(2)}",
                            style: TextStyle(
                              color: normalizeStatus(status) == 'failed'
                                  ? Colors.red
                                  : normalizeStatus(status) == 'pending'
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
