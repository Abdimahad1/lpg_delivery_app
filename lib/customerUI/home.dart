import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;
import '../config/api_config.dart';
import '../controllers/cart_controller.dart';
import '../controllers/profile_controller.dart';
import 'ProductDetailScreen.dart';
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

  void _onSearchChanged() {
    // Implement search functionality if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search Bar
          Container(
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
                      hintText: "Search gas products and vendors...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Getting Started Today", ""),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.0,  // Square cards
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          QuickActionCard(
                            icon: Icons.propane_tank,
                            label: "Buy Cooking Gas",
                            onTap: () => widget.onTabSelected?.call(1),
                          ),
                          QuickActionCard(
                            icon: Icons.location_on,
                            label: "Locate Vendors",
                            onTap: () {
                              Get.to(() => SearchVendorsScreen());
                            },
                          ),
                          const QuickActionCard(
                            icon: Icons.history,
                            label: "Transaction History",
                          ),
                          QuickActionCard(
                            icon: Icons.person,
                            label: "My profile",
                            onTap: () => widget.onTabSelected?.call(4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Products", ""),
                      const SizedBox(height: 12),
                      _randomProducts.isEmpty
                          ? const Center(
                        child: Text("No products found",
                            style: TextStyle(color: Colors.grey)),
                      )
                          : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _randomProducts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = _randomProducts[index];
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
                              ));
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (action.isNotEmpty)
          Text(action, style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
    );
  }
}

class VendorCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final String location;
  final String vendorId;

  const VendorCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.location,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to vendor details screen if needed
      },
      child: Container(
        width: 150,  // Fixed width
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: imagePath.startsWith('http')
                  ? NetworkImage(imagePath)
                  : AssetImage(imagePath) as ImageProvider,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_pin, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 100,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red, size: 35),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

  ProductCard({
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildProductImage(imagePath),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(vendorName,
                      style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  if (description.isNotEmpty)
                    Text(description,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      const Icon(Icons.location_pin, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  )
                ],
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
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imagePath.startsWith('data:image')) {
        return Image.memory(
          base64.decode(imagePath.split(',').last),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      } else if (imagePath.isNotEmpty) {
        return Image.asset(
          imagePath,
          width: 60,
          height: 60,
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
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
    );
  }
}