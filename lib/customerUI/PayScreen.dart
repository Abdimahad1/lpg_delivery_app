import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';
import 'TransactionHistoryScreen.dart';

class PayScreen extends StatefulWidget {
  final String vendorName;
  final String amount;
  final String productId;
  final String vendorId;
  final String productTitle;
  final String productImage;
  final double productPrice;
  final String userLocation;
  final String userId;

  const PayScreen({
    super.key,
    required this.vendorName,
    required this.amount,
    required this.productId,
    required this.vendorId,
    required this.productTitle,
    required this.productImage,
    required this.productPrice,
    required this.userLocation,
    required this.userId,
  });

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final TextEditingController _accountNoController = TextEditingController();
  bool _hasTriedPayment = false;

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(10, 30, 10, 0),
      ),
    );
  }

  void _showPhonePopup(BuildContext context) {
    if (_hasTriedPayment) return; // ⛔ Prevent showing if already in progress

    _accountNoController.clear();
    setState(() => _hasTriedPayment = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Enter Your Phone Number", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountNoController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "e.g. 2526xxxxxxx",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_hasTriedPayment) return;
                      setState(() => _hasTriedPayment = true);
                      _sendPayment(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E3EFF),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Send Money", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _hasTriedPayment = false);
                    Navigator.pop(dialogContext);
                  },
                  child: const Icon(Icons.cancel, color: Colors.grey, size: 28),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendPayment(BuildContext dialogContext) async {
    final phone = _accountNoController.text.trim();
    if (phone.isEmpty) {
      _showSnack("❗ Please enter your phone number", Colors.orange);
      return;
    }

    Navigator.pop(dialogContext); // Close the phone input dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final invoiceId = "INV-${DateTime.now().millisecondsSinceEpoch}";

      final paymentPayload = {
        "accountNo": phone,
        "amount": widget.amount,
        "invoiceId": invoiceId,
        "description": "Payment for ${widget.productTitle}",
        "productId": widget.productId,
        "vendorId": widget.vendorId,
        "productTitle": widget.productTitle,
        "productImage": widget.productImage,
        "productPrice": widget.productPrice,
        "userLocation": widget.userLocation,
      };

      final response = await http.post(
        Uri.parse("${baseUrl}payment/pay"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(paymentPayload),
      );

      if (context.mounted) Navigator.pop(context); // Close loading spinner

      final res = jsonDecode(response.body);
      final success = res['success'] == true;

      _showSnack(
        success ? "✅ Payment successful" : "❌ ${res['message'] ?? 'Payment failed'}",
        success ? Colors.green : Colors.red,
      );

      setState(() => _hasTriedPayment = false);

      // Redirect regardless of result
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Get.off(() => const TransactionHistoryScreen());
        }
      });

    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showSnack("❌ Error: ${e.toString()}", Colors.red);
      print("Payment error details: $e");
      setState(() => _hasTriedPayment = false);

      // Redirect on error too
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Get.off(() => const TransactionHistoryScreen());
        }
      });
    }
  }


  Widget _buildPaymentOption(BuildContext context, String imagePath, String label) {
    return InkWell(
      onTap: () {
        if (!_hasTriedPayment) {
          _showPhonePopup(context);
        }
      },
      child: Container(
        height: 160,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(imagePath, width: 120, height: 120, fit: BoxFit.contain),
            ),
            const SizedBox(width: 20),
            Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 77),
      decoration: const BoxDecoration(
        color: Color(0xFFE4E4F4),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _hasTriedPayment = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E4F4),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    const Text("Pay The Gas Payment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("Vendor: ${widget.vendorName}"),
                    const SizedBox(height: 8),
                    Text("Amount: \$${widget.amount}", style: const TextStyle(color: Colors.green, fontSize: 18)),
                    const SizedBox(height: 40),
                    const Text("SELECT PAYMENT OPTION", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    _buildPaymentOption(context, "assets/images/evcplus.png", "EVC Plus"),
                    const SizedBox(height: 20),
                    _buildPaymentOption(context, "assets/images/edahab.png", "Edahab"),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
