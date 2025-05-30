// 📦 cart_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'profile_controller.dart';

class CartItem {
  final String? id; // MongoDB _id
  final String title;
  final double price;
  final String location;
  final String imagePath;
  final int quantity;
  final String productId;
  final String vendorId;
  final String vendorPhone;
  final String vendorName;


  CartItem({
    this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imagePath,
    this.quantity = 1,
    required this.productId,
    required this.vendorId,
    required this.vendorPhone,
    required this.vendorName,

  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'],
      title: json['title'] ?? '',
      price: (json['price'] as num).toDouble(),
      location: json['location'] ?? 'Unknown',
      imagePath: json['imagePath'] ?? '',
      quantity: json['quantity'] ?? 1,
      productId: json['productId'] ?? '',
      vendorId: json['vendorId'] ?? '',
      vendorPhone: json['vendorPhone'] ?? '',
      vendorName: json['vendorName'] ?? 'Unknown Vendor', // ✅ FIX
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'vendorId': vendorId,
      'title': title,
      'imagePath': imagePath,
      'price': price,
      'quantity': quantity,
      'location': location,
      'vendorPhone': vendorPhone,
    };
  }
}

class CartController extends GetxController {
  var cartItems = <CartItem>[].obs;
  final profileController = Get.find<ProfileController>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCartFromBackend();
  }

  Future<void> fetchCartFromBackend() async {
    if (profileController.authToken.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}cart'),
        headers: {
          'Authorization': 'Bearer ${profileController.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          cartItems.value = (data['data'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      print('❌ Error fetching cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart(CartItem item) async {
    if (profileController.authToken.isEmpty) {
      Get.snackbar('Error', 'Please login to add items to cart',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ DEBUG LOGGING
    print('📦 [ADD TO CART]');
    print('productId: ${item.productId}');
    print('vendorId: ${item.vendorId}');
    print('title: ${item.title}');
    print('imagePath: ${item.imagePath}');
    print('price: ${item.price}');
    print('quantity: ${item.quantity}');
    print('location: ${item.location}');
    print('vendorPhone: ${item.vendorPhone}');

    // ✅ SAFETY CHECK
    if (item.productId.isEmpty ||
        item.vendorId.isEmpty ||
        item.title.isEmpty ||
        item.imagePath.isEmpty ||
        item.location.isEmpty ||
        item.vendorPhone.isEmpty) {
      Get.snackbar('Error', 'Missing required fields',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${profileController.authToken}',
        },
        body: jsonEncode(item.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Item added to cart.');
        await fetchCartFromBackend();
      } else {
        print('❌ Backend rejected the request: ${response.body}');
        throw Exception(responseData['message'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      print('❌ Exception while adding to cart: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}cart/remove-by-product/$productId'),
        headers: {
          'Authorization': 'Bearer ${profileController.authToken}',
        },
      );
      if (response.statusCode == 200) {
        await fetchCartFromBackend();
      }
    } catch (e) {
      print('❌ Error removing from cart: $e');
    }
  }

  Future<void> clearCartOnServer() async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}cart/clear'),
        headers: {
          'Authorization': 'Bearer ${profileController.authToken}',
        },
      );
      if (response.statusCode == 200) {
        cartItems.clear();
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
    }
  }

  double get totalPrice => cartItems.fold(
      0, (sum, item) => sum + (item.price * item.quantity));
}
