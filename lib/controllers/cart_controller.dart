// 📁 cart_controller.dart
import 'package:get/get.dart';

class CartItem {
  final String title;
  final double price;
  final String location;
  final String imagePath;
  final int quantity;

  CartItem({
    required this.title,
    required this.price,
    required this.location,
    required this.imagePath,
    this.quantity = 1,
  });
}

class CartController extends GetxController {
  var cartItems = <CartItem>[].obs;

  void addToCart(CartItem item) {
    int index = cartItems.indexWhere((e) => e.title == item.title);
    if (index >= 0) {
      cartItems[index] = CartItem(
        title: item.title,
        price: item.price,
        location: item.location,
        imagePath: item.imagePath,
        quantity: cartItems[index].quantity + item.quantity,
      );
    } else {
      cartItems.add(item);
    }
  }

  void removeFromCart(CartItem item) {
    cartItems.removeWhere((e) => e.title == item.title);
  }

  void updateQuantity(CartItem item, int newQuantity) {
    int index = cartItems.indexWhere((e) => e.title == item.title);
    if (index >= 0) {
      cartItems[index] = CartItem(
        title: item.title,
        price: item.price,
        location: item.location,
        imagePath: item.imagePath,
        quantity: newQuantity,
      );
    }
  }

  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void clearCart() => cartItems.clear();
}