import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'profile_controller.dart';

class CartItem {
  final String? id;  // MongoDB _id
  final String title;
  final double price;
  final String location;
  final String imagePath;
  final int quantity;
  final String productId;
  final String vendorId;

  CartItem({
    this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imagePath,
    this.quantity = 1,
    required this.productId,
    required this.vendorId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'],
      title: json['title'],
      price: json['price'].toDouble(),
      location: json['location'],
      imagePath: json['imagePath'],
      quantity: json['quantity'],
      productId: json['productId'],
      vendorId: json['vendorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'price': price,
      'location': location,
      'imagePath': imagePath,
      'quantity': quantity,
      'productId': productId,
      'vendorId': vendorId,
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

    ever(profileController.isCartInitialized, (initialized) {
      if (initialized && profileController.authToken.isNotEmpty) {
        fetchCartFromBackend();
      } else {
        clearCart();
      }
    });

    ever<String>(profileController.rxAuthToken, (token) {
      if (token.isNotEmpty) {
        fetchCartFromBackend();
      } else {
        clearCart();
      }
    });
  }

  void updateCartItems(List<CartItem> items) {
    cartItems.assignAll(items);
  }

  Future<void> fetchCartFromBackend() async {
    if (profileController.authToken.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cart'),
        headers: {
          'Authorization': 'Bearer ${profileController.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> backendItems = data['data'];

        cartItems.value = backendItems
            .map((item) => CartItem.fromJson(item))
            .toList();
      } else {
        print('❌ Error fetching cart: ${response.body}');
        Get.snackbar('Error', 'Failed to load cart items',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('❌ Exception fetching cart: $e');
      Get.snackbar('Error', 'Failed to connect to server',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void clearCart() {
    cartItems.clear();
  }

  Future<void> addToCart(CartItem item) async {
    if (profileController.authToken.isEmpty) {
      Get.snackbar('Error', 'Please login to add items to cart',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final existingItemIndex = cartItems.indexWhere((i) => i.productId == item.productId);
    if (existingItemIndex >= 0) {
      final updatedItem = cartItems[existingItemIndex];
      cartItems[existingItemIndex] = CartItem(
        id: updatedItem.id,
        title: updatedItem.title,
        price: updatedItem.price,
        location: updatedItem.location,
        imagePath: updatedItem.imagePath,
        quantity: updatedItem.quantity + item.quantity,
        productId: updatedItem.productId,
        vendorId: updatedItem.vendorId,
      );
    } else {
      cartItems.add(item);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${profileController.authToken}',
        },
        body: jsonEncode(item.toJson()),
      );

      if (response.statusCode != 200) {
        fetchCartFromBackend();
        throw Exception('Failed to add item to cart');
      }
    } catch (e) {
      print('❌ Error adding to cart: $e');
      Get.snackbar('Error', 'Failed to add item to cart',
          backgroundColor: Colors.red, colorText: Colors.white);
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    if (profileController.authToken.isEmpty) {
      Get.snackbar('Error', 'Please login to modify cart',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/remove-by-product/$productId'),
        headers: {
          'Authorization': 'Bearer ${profileController.authToken}',
        },
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Remove from local list
        cartItems.removeWhere((item) => item.productId == productId);

        Get.snackbar('Success', responseData['message'] ?? 'Item removed from cart',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to remove item');
      }
    } catch (e) {
      print('❌ Error removing from cart: $e');
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (profileController.authToken.isEmpty) return;

    try {
      final item = cartItems.firstWhere((item) => item.productId == productId);
      final updatedItem = CartItem(
        id: item.id,
        title: item.title,
        price: item.price,
        location: item.location,
        imagePath: item.imagePath,
        quantity: newQuantity,
        productId: item.productId,
        vendorId: item.vendorId,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${profileController.authToken}',
        },
        body: jsonEncode(updatedItem.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchCartFromBackend();
      } else {
        throw Exception('Failed to update quantity');
      }
    } catch (e) {
      print('❌ Error updating quantity: $e');
      Get.snackbar('Error', 'Failed to update quantity',
          backgroundColor: Colors.red, colorText: Colors.white);
      rethrow;
    }
  }

  Future<void> clearCartOnServer() async {
    if (profileController.authToken.isEmpty) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/clear'),
        headers: {
          'Authorization': 'Bearer ${profileController.authToken}',
        },
      );

      if (response.statusCode == 200) {
        clearCart();
      } else {
        throw Exception('Failed to clear cart');
      }
    } catch (e) {
      print('❌ Error clearing cart: $e');
      Get.snackbar('Error', 'Failed to clear cart',
          backgroundColor: Colors.red, colorText: Colors.white);
      rethrow;
    }
  }

  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
}