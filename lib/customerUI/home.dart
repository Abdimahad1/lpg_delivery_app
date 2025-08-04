import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import '../config/api_config.dart';
import '../controllers/cart_controller.dart';
import '../controllers/profile_controller.dart';
import 'ProductDetailScreen.dart';
import 'TransactionHistoryScreen.dart';
import 'search_vendors_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final Function(int)? onTabSelected;

  const CustomerHomeScreen({super.key, this.onTabSelected});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileController profileController = Get.find<ProfileController>();
  final CartController cartController = Get.find<CartController>();

  List<Map<String, dynamic>> _randomProducts = [];
  bool _isLoading = true;
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchRandomProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRandomProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}products/random?limit=7'),
        headers: {'Authorization': 'Bearer ${profileController.authToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _randomProducts = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      print('Error fetching random products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}products/search?query=$query'),
        headers: {'Authorization': 'Bearer ${profileController.authToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data['data']);
          _showSearchResults = true;
        });
      }
    } catch (e) {
      print('Error searching products: $e');
    }
  }

  void _onSearchChanged() {
    _searchProducts(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

            ),
          ),

          // Main Content
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults()
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Quick Actions", ""),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      QuickActionCard(
                        icon: Iconsax.gas_station,
                        label: "Buy Cooking Gas",
                        color: const Color(0xFF3E3EFF),
                        onTap: () => widget.onTabSelected?.call(1),
                      ),
                      QuickActionCard(
                        icon: Iconsax.location,
                        label: "Locate Vendors",
                        color: Colors.orange,
                        onTap: () {
                          Get.to(() => SearchVendorsScreen());
                        },
                      ),
                      QuickActionCard(
                        icon: Iconsax.receipt,
                        label: "Transaction History",
                        color: Colors.green,
                        onTap: () {
                          Get.to(() => TransactionHistoryScreen());
                        },
                      ),
                      QuickActionCard(
                        icon: Iconsax.profile_circle,
                        label: "My Profile",
                        color: Colors.purple,
                        onTap: () => widget.onTabSelected?.call(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildSectionHeader("Featured Products", " "),
                  _randomProducts.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "No products available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _randomProducts.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = _randomProducts[index];
                      return ProductCard(
                        title: product['name'],
                        description:
                        product['description'] ?? 'No description',
                        vendorName:
                        product['vendorName'] ?? 'Unknown Vendor',
                        location:
                        product['vendorAddress'] ?? '',
                        price: product['price']?.toDouble() ?? 0.0,
                        imagePath:
                        product['image'] ?? 'assets/images/cylinder.png',
                        productId: product['_id'],
                        vendorId: product['vendorId'],
                        onTap: () {
                          Get.to(() => ProductDetailScreen(
                            title: product['name'],
                            price: product['price']?.toDouble() ?? 0.0,
                            location:
                            product['vendorAddress'] ?? '',
                            description: product['description'] ??
                                'No description',
                            imagePath: product['image'] ??
                                'assets/images/cylinder.png',
                            vendorName: product['vendorName'] ??
                                'Unknown Vendor',
                            productId: product['_id'],
                            vendorId: product['vendorId'],
                            vendorPhone: product['vendorPhone'],
                          ));
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text("No results found", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
          title: product['name'],
          description: product['description'] ?? 'No description',
          vendorName: product['vendorName'] ?? 'Unknown Vendor',
          location: product['vendorAddress'] ?? '',
          price: product['price']?.toDouble() ?? 0.0,
          imagePath: product['image'] ?? 'assets/images/cylinder.png',
          productId: product['_id'],
          vendorId: product['vendorId'],
          onTap: () {
            Get.to(() => ProductDetailScreen(
              title: product['name'],
              price: product['price']?.toDouble() ?? 0.0,
              location: product['vendorAddress'] ?? '',
              description: product['description'] ?? 'No description',
              imagePath: product['image'] ?? 'assets/images/cylinder.png',
              vendorName: product['vendorName'] ?? 'Unknown Vendor',
              productId: product['_id'],
              vendorId: product['vendorId'],
              vendorPhone: product['vendorPhone'],
            ));
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        if (action.isNotEmpty)
          TextButton(
            onPressed: () {},
            child: Text(
              action,
              style: const TextStyle(
                color: Color(0xFF3E3EFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String title;
  final String description;
  final String vendorName;
  final String location;
  final double price;
  final String imagePath;
  final String productId;
  final String vendorId;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.vendorName,
    required this.location,
    required this.price,
    required this.imagePath,
    required this.productId,
    required this.vendorId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: _buildProductImage(imagePath),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendorName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Iconsax.location, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    try {
      if (imagePath.startsWith('http')) {
        return Image.network(
          imagePath,
          width: 100,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imagePath.startsWith('data:image')) {
        return Image.memory(
          base64.decode(imagePath.split(',').last),
          width: 100,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imagePath.isNotEmpty) {
        return Image.asset(
          imagePath,
          width: 100,
          height: 120,
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
    return Container(
      width: 100,
      height: 120,
      color: Colors.grey[100],
      child: Center(
        child: Icon(Iconsax.gas_station, size: 40, color: Colors.grey[400]),
      ),
    );
  }
}