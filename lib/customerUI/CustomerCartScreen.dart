import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/profile_controller.dart';
import 'PayScreen.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find();

    Future<void> refreshCart() async {
      await cartController.fetchCartFromBackend();
    }

    Future<bool> _onBackPressed() async {
      Navigator.pop(context); // Go to previous screen
      return false; // Prevent default pop
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Your Cart"),
          backgroundColor: const Color(0xFF3E3EFF),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: refreshCart,
              tooltip: 'Refresh Cart',
            ),
            Obx(() {
              return cartController.cartItems.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => _confirmClearCart(context),
                tooltip: 'Clear Cart',
              )
                  : const SizedBox.shrink();
            }),
          ],
        ),
        body: Obx(() {
          if (cartController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: refreshCart,
            child: cartController.cartItems.isEmpty
                ? ListView(
              children: const [
                SizedBox(height: 150),
                Center(
                  child: Text(
                    "Your cart is empty.\nPlease refresh or add items.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartController.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartController.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _loadImage(item.imagePath),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text("Vendor: ${item.vendorName}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.location,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "\$${item.price.toStringAsFixed(2)} x ${item.quantity} = \$${(item.price * item.quantity).toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, item.productId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "\$${cartController.totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (cartController.cartItems.isEmpty) {
                        Get.snackbar("Cart Empty", "Please add items before checkout.",
                            backgroundColor: Colors.red.shade100, colorText: Colors.black);
                        return;
                      }
                      final firstItem = cartController.cartItems.first;
                      final amount = cartController.totalPrice.toStringAsFixed(2);
                      final profileController = Get.find<ProfileController>();

                      Get.to(() => PayScreen(
                        vendorName: firstItem.vendorName,
                        amount: amount,
                        productId: firstItem.productId,
                        vendorId: firstItem.vendorId,
                        productTitle: firstItem.title,
                        productImage: firstItem.imagePath,
                        productPrice: firstItem.price,
                        userLocation: firstItem.location,
                        userId: profileController.userId.value,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E3EFF),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text(
                      "Proceed to Checkout",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _loadImage(String imagePath) {
    try {
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        return Image.network(imagePath, width: 80, height: 80, fit: BoxFit.cover);
      } else if (imagePath.startsWith('data:image')) {
        final bytes = base64.decode(imagePath.split(',').last);
        return Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover);
      } else {
        return Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.cover);
      }
    } catch (_) {
      return const Icon(Icons.broken_image, size: 80);
    }
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item"),
        content: const Text("Are you sure you want to remove this item from your cart?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final cartController = Get.find<CartController>();
              await cartController.removeFromCart(productId);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Cart"),
        content: const Text("Are you sure you want to remove all items from your cart?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final cartController = Get.find<CartController>();
              await cartController.clearCartOnServer();
            },
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
