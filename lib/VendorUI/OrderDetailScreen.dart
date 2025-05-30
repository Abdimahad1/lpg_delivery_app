import 'dart:convert';
import 'package:flutter/material.dart';
import 'AssignDeliveryScreen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final String title = order['productTitle'] ?? 'No Title';
    final String invoiceId = order['invoiceId'] ?? 'N/A';
    final String location = order['userLocation'] ?? 'Unknown';
    final String date = order['timestamp'] ?? '';
    final String formattedDate = date.isNotEmpty
        ? DateTime.tryParse(date) != null
        ? "${DateTime.parse(date).toLocal().toString().split(' ')[0]}"
        : 'Invalid Date'
        : 'No Date';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F2F2),
      appBar: AppBar(
        title: const Text("Order Detail"),
        backgroundColor: const Color(0xFF3E3EFF),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: order['productImage'] != null &&
                  order['productImage'].toString().contains(',')
                  ? Image.memory(
                base64Decode(order['productImage'].split(',').last),
                height: 140,
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) =>
                const Icon(Icons.image, size: 100),
              )
                  : const Icon(Icons.image, size: 100),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDetailItem("📦 Order No:", invoiceId),
                  buildDetailItem("📅 Date:", formattedDate),
                  buildDetailItem("📍 Location:", location),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1),
                  const SizedBox(height: 12),
                  const Text(
                    "Assign Delivery Person",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AssignDeliveryScreen(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E3EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        elevation: 6,
                      ),
                      child: const Text(
                        "Assign",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
