import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  File? _selectedImage;
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        imageController.clear(); // Clear URL field when selecting from gallery
      });
    }
  }

  Future<String> _convertImageToBase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> addProduct() async {
    isAdding.value = true;
    final token = Get.find<ProfileController>().authToken;
    String imageData = '';

    // Handle image from gallery
    if (_selectedImage != null) {
      try {
        imageData = 'data:image/jpeg;base64,${await _convertImageToBase64(_selectedImage!)}';
      } catch (e) {
        Get.snackbar("Error", "Failed to process image");
        isAdding.value = false;
        return;
      }
    }
    // Handle image from URL or base64
    else {
      imageData = imageController.text.trim();
      if (imageData.isEmpty) {
        Get.snackbar("Error", "Please provide an image");
        isAdding.value = false;
        return;
      }

      if (!imageData.startsWith('data:image/') &&
          !(Uri.tryParse(imageData)?.hasAbsolutePath ?? false) &&
          !imageData.contains('gstatic.com')) {
        Get.snackbar("Error", "Enter a valid image URL or select from gallery");
        isAdding.value = false;
        return;
      }
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
    String imageData = '';

    // Handle image from gallery
    if (_selectedImage != null) {
      try {
        imageData = 'data:image/jpeg;base64,${await _convertImageToBase64(_selectedImage!)}';
      } catch (e) {
        Get.snackbar("Error", "Failed to process image");
        isUpdating.value = false;
        return;
      }
    }
    // Handle image from URL or base64
    else {
      imageData = imageController.text.trim();
      if (imageData.isEmpty) {
        Get.snackbar("Error", "Please provide an image");
        isUpdating.value = false;
        return;
      }

      if (!imageData.startsWith('data:image/') &&
          !(Uri.tryParse(imageData)?.hasAbsolutePath ?? false) &&
          !imageData.contains('gstatic.com')) {
        Get.snackbar("Error", "Enter a valid image URL or select from gallery");
        isUpdating.value = false;
        return;
      }
    }

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
    _selectedImage = null;
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
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 10),
              const Text("Image Source", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: "Image URL",
                        hintText: "Paste image URL...",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: _pickImage,
                    tooltip: "Pick from gallery",
                  ),
                ],
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 10),
                Text(
                  "Selected image from gallery",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedImage = null),
                  child: const Text("Remove image", style: TextStyle(color: Colors.red)),
                ),
              ],
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
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Obx(() => AlertDialog(
            title: const Text("Update Product"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 10),
                  const Text("Image Source", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: "Image URL",
                            hintText: "Paste image URL...",
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() => _selectedImage = null);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: () async {
                          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              _selectedImage = File(pickedFile.path);
                              imageController.clear();
                            });
                          }
                        },
                        tooltip: "Pick from gallery",
                      ),
                    ],
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      "New image from gallery",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      child: const Text("Remove image", style: TextStyle(color: Colors.red)),
                    ),
                  ] else if (product['image']?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(
                      "Current product image",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildImagePreview(product['image']),
                    ),
                  ],
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
          ));
        },
      ),
    );
  }

  Widget _buildImagePreview(String imageData) {
    try {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imageData.startsWith('data:image')) {
        return Image.memory(
          base64.decode(imageData.split(',').last),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      }
      return _buildErrorImage();
    } catch (e) {
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return const Center(
      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
      color: Colors.white, // ✅ White background
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
                    Positioned.fill(child: _buildProductImage()),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.withOpacity(0.9),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                          onPressed: onUpdate,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.withOpacity(0.9),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete, size: 18, color: Colors.white),
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
