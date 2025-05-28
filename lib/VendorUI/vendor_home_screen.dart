import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../controllers/profile_controller.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final List<Map<String, dynamic>> _products = [];
  final isLoading = false.obs;
  final isAdding = false.obs;
  final isUpdating = false.obs;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final imageController = TextEditingController();

  String? _currentProductId;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    imageController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    final token = Get.find<ProfileController>().authToken;

    try {
      final res = await http.get(
        Uri.parse('${baseUrl}products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          setState(() {
            _products.clear();
            _products.addAll((body['data'] as List).map((item) => {
              "id": item['_id'],
              "name": item['name'],
              "description": item['description'] ?? '',
              "quantity": item['quantity'],
              "price": double.parse(item['price'].toString()),
              "image": item['image'] ?? '',
            }).toList());
          });
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load products");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct() async {
    isAdding.value = true;
    final token = Get.find<ProfileController>().authToken;
    final imageData = imageController.text.trim();

    if (!imageData.startsWith('data:image/') &&
        !(Uri.tryParse(imageData)?.hasAbsolutePath ?? false) &&
        !imageData.contains('gstatic.com')) {
      Get.snackbar("Error", "Enter a valid image URL or Base64 image data");
      isAdding.value = false;
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "description": descriptionController.text.trim(),
          "quantity": int.parse(quantityController.text),
          "price": double.parse(priceController.text),
          "image": imageData,
        }),
      );

      if (response.statusCode == 201) {
        await fetchProducts();
        Get.back();
        Get.snackbar("Success", "Product added");
        clearForm();
      } else {
        Get.snackbar("Error", "Failed to add product");
      }
    } catch (e) {
      Get.snackbar("Error", "Exception: $e");
    } finally {
      isAdding.value = false;
    }
  }

  Future<void> updateProduct() async {
    isUpdating.value = true;
    final token = Get.find<ProfileController>().authToken;
    final imageData = imageController.text.trim();

    try {
      final response = await http.put(
        Uri.parse('${baseUrl}products/$_currentProductId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "description": descriptionController.text.trim(),
          "quantity": int.parse(quantityController.text),
          "price": double.parse(priceController.text),
          "image": imageData,
        }),
      );

      if (response.statusCode == 200) {
        await fetchProducts();
        Get.back();
        Get.snackbar("Success", "Product updated");
        clearForm();
      } else {
        Get.snackbar("Error", "Failed to update product");
      }
    } catch (e) {
      Get.snackbar("Error", "Exception: $e");
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final token = Get.find<ProfileController>().authToken;

    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchProducts();
        Get.snackbar("Success", "Product deleted");
      } else {
        Get.snackbar("Error", "Failed to delete product");
      }
    } catch (e) {
      Get.snackbar("Error", "Exception: $e");
    }
  }

  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    quantityController.clear();
    imageController.clear();
    _currentProductId = null;
  }

  void showAddProductPopup() {
    clearForm();
    showDialog(
      context: context,
      builder: (_) => Obx(() => AlertDialog(
        title: const Text("Add Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL or Base64",
                  hintText: "Paste a valid image URL or Base64 data...",
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isAdding.value ? null : () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isAdding.value ? null : addProduct,
            child: isAdding.value
                ? const CircularProgressIndicator()
                : const Text("Add"),
          ),
        ],
      )),
    );
  }

  void showUpdateProductPopup(Map<String, dynamic> product) {
    _currentProductId = product['id'];
    nameController.text = product['name'];
    descriptionController.text = product['description'] ?? '';
    quantityController.text = product['quantity'].toString();
    priceController.text = product['price'].toString();
    imageController.text = product['image'];

    showDialog(
      context: context,
      builder: (_) => Obx(() => AlertDialog(
        title: const Text("Update Product"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: "Image URL or Base64",
                  hintText: "Paste a valid image URL or Base64 data...",
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isUpdating.value ? null : () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isUpdating.value ? null : updateProduct,
            child: isUpdating.value
                ? const CircularProgressIndicator()
                : const Text("Update"),
          ),
        ],
      )),
    );
  }

  void showDeleteConfirmation(String productId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteProduct(productId);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      body: SafeArea(
        child: Obx(() {
          if (isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: showAddProductPopup,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _products.isEmpty
                      ? const Center(child: Text("No products available"))
                      : GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ProductCard(
                        name: product['name'],
                        description: product['description'],
                        price: product['price'],
                        quantity: product['quantity'],
                        imageData: product['image'],
                        onUpdate: () => showUpdateProductPopup(product),
                        onDelete: () => showDeleteConfirmation(product['id']),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String imageData;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const ProductCard({
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    required this.imageData,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildProductImage(),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: onUpdate,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: onDelete,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          description!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Chip(
                            label: Text('Qty: $quantity'),
                            backgroundColor: Colors.blue[100],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Chip(
                            backgroundColor: Colors.green[100],
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '\$${price < 0.01 ? price.toStringAsFixed(3) : price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),


                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    try {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imageData.startsWith('data:image')) {
        return Image.memory(
          base64.decode(imageData.split(',').last),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imageData.isNotEmpty) {
        return Image.asset(
          imageData,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      }
      return _buildErrorImage();
    } catch (e) {
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
}

class PlaceholderImage extends StatelessWidget {
  final double size;

  const PlaceholderImage({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Icon(Icons.image, size: size * 0.6, color: Colors.grey),
    );
  }
}