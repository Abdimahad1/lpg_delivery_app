import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../controllers/cart_controller.dart';
import '../controllers/profile_controller.dart';
import 'ProductDetailScreen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CartController _cartController = Get.find();
  final ProfileController _profileController = Get.find();

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _vendors = [];

  String _selectedVendor = 'All';
  String _sortOption = 'Default';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAllProducts();
  }

  Future<void> _fetchAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}products/all'),
        headers: {
          'Authorization': 'Bearer ${_profileController.authToken}'
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'];

        final products = data.map<Map<String, dynamic>>((item) {
          return {
            'title': item['name'],
            'price': item['price'].toDouble(),
            'description': item['description'] ?? '',
            'imagePath': item['image'],
            'location': item['vendorAddress'] ?? '',
            'vendorName': item['vendorName'] ?? '',
            'vendorPhone': item['vendorPhone'] ?? '', // ✅ NEW
            'productId': item['_id'],
            'vendorId': item['vendorId'],
          };
        }).toList();

        final vendors = {'All', ...products.map((e) => e['vendorName'] as String)};

        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _vendors = vendors.toList();
        });
      } else {
        print("❌ Failed to fetch products: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error fetching all products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    List<Map<String, dynamic>> results = _allProducts.where((product) {
      final title = product['title'].toLowerCase();
      final location = product['location'].toLowerCase();
      final vendor = product['vendorName'];

      final matchesSearch = title.contains(query) || location.contains(query);
      final matchesVendor = _selectedVendor == 'All' || vendor == _selectedVendor;

      return matchesSearch && matchesVendor;
    }).toList();

    if (_sortOption == 'Price ↑') {
      results.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (_sortOption == 'Price ↓') {
      results.sort((a, b) => b['price'].compareTo(a['price']));
    } else if (_sortOption == 'A-Z') {
      results.sort((a, b) => a['title'].compareTo(b['title']));
    } else if (_sortOption == 'Z-A') {
      results.sort((a, b) => b['title'].compareTo(a['title']));
    }

    setState(() {
      _filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration.collapsed(
                hintText: "Search gas products...",
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortOption,
              decoration: const InputDecoration(border: InputBorder.none),
              items: ['Default', 'Price ↑', 'Price ↓', 'A-Z', 'Z-A']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                  .toList(),
              onChanged: (value) {
                _sortOption = value!;
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedVendor,
              decoration: const InputDecoration(border: InputBorder.none),
              items: _vendors
                  .map((v) => DropdownMenuItem(
                value: v,
                child: Text(v, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: (value) {
                _selectedVendor = value!;
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text("No products found", style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text("Try a different search term", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_filteredProducts[index]);
        },
      );
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Get.to(() => ProductDetailScreen(
            title: product['title'],
            price: product['price'],
            location: product['location'],
            description: product['description'],
            imagePath: product['imagePath'],
            vendorName: product['vendorName'],
            productId: product['productId'],
            vendorId: product['vendorId'],
            vendorPhone:product['vendorPhone']
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: buildUniversalImage(product['imagePath'], width: 70, height: 70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(product['location'],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("\$${product['price'].toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Utility image renderer
Widget buildUniversalImage(String imagePath, {double? width, double? height}) {
  try {
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, width: width, height: height, fit: BoxFit.cover);
    } else if (imagePath.startsWith('data:image')) {
      final bytes = base64.decode(imagePath.split(',').last);
      return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
    } else {
      return Image.asset(imagePath, width: width, height: height, fit: BoxFit.cover);
    }
  } catch (_) {
    return _buildErrorImage(width, height);
  }
}

Widget _buildErrorImage(double? width, double? height) {
  return Container(
    width: width ?? 70,
    height: height ?? 70,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
  );
}
