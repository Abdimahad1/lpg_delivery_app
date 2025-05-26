import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/cart_controller.dart';
import '../controllers/profile_controller.dart';
import '../config/api_config.dart';
import 'CustomerCartScreen.dart';
import 'PayScreen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String title;
  final double price;
  final String location;
  final String description;
  final String imagePath;
  final String vendorName;
  final String productId;
  final String vendorId;
  final String vendorPhone;

  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.vendorName,
    required this.productId,
    required this.vendorId,
    required this.vendorPhone,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1; // Local quantity for this screen
  bool _isAddingToCart = false;
  final CartController cartController = Get.find();
  final ProfileController profileController = Get.find();

  void _increment() {
    setState(() {
      quantity++;
    });
  }

  void _decrement() {
    setState(() {
      if (quantity > 1) {
        quantity--;
      }
    });
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      // Create a CartItem object with all required fields
      CartItem item = CartItem(
        title: widget.title,
        price: widget.price,
        location: widget.location.isNotEmpty
            ? widget.location
            : profileController.userAddress.value.isNotEmpty
            ? profileController.userAddress.value
            : 'Unknown Location', // ✅ fallback
        imagePath: widget.imagePath,
        quantity: quantity,
        productId: widget.productId,
        vendorId: widget.vendorId,
        vendorPhone: widget.vendorPhone,
      );


      // Add to cart using CartController
      await cartController.addToCart(item);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _buyNow() {
    // Navigate to PayScreen without adding to cart
    Get.to(() => PayScreen(vendorName: widget.vendorName, amount: widget.price.toString(), vendorPhone: widget.vendorPhone));
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.price * quantity;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF3E3EFF),
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                const Text("Product Details", style: TextStyle(color: Colors.white, fontSize: 18)),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildUniversalImage(
                          widget.imagePath,
                          width: width * 0.8,
                          height: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storefront, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(widget.vendorName, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(widget.location, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${widget.price.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _decrement,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.2),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.remove, color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$quantity', style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _increment,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.2),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.add, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Total: \$${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(widget.description, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _addToCart();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                            icon: const Icon(Icons.shopping_cart, color: Colors.black),
                            label: const Text("ADD TO CART", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _buyNow,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            icon: const Icon(Icons.shopping_bag, color: Colors.white),
                            label: const Text("BUY NOW", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildUniversalImage(String imagePath, {double? width, double? height}) {
  try {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, width: width, height: height, fit: BoxFit.contain);
    } else if (imagePath.startsWith('data:image')) {
      final bytes = base64.decode(imagePath.split(',').last);
      return Image.memory(bytes, width: width, height: height, fit: BoxFit.contain);
    } else if (imagePath.isNotEmpty) {
      return Image.asset(imagePath, width: width, height: height, fit: BoxFit.contain);
    } else {
      return _buildErrorImage(width, height);
    }
  } catch (_) {
    return _buildErrorImage(width, height);
  }
}

Widget _buildErrorImage(double? width, double? height) {
  return Container(
    width: width ?? 100,
    height: height ?? 100,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
  );
}
