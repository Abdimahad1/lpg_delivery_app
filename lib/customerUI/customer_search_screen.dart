import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import 'ProductDetailScreen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CartController _cartController = Get.find();
  final List<Map<String, dynamic>> _allProducts = [
    {
      'title': '6kg Cooking Gas Cylinder',
      'location': 'Taleex-mog-somalia',
      'price': 24.0,
      'imagePath': 'assets/images/cylinder.png',
      'description': '6kg cylinder is a wonderful Gas which will hold you 1 month and 5 days',
    },
    {
      'title': '12kg Gas Cylinder - Deluxe',
      'location': 'Bakara-Mogadishu',
      'price': 38.0,
      'imagePath': 'assets/images/cylinder.png',
      'description': 'Premium 12kg cylinder for larger families or commercial use',
    },
    {
      'title': '3kg Mini Cooking Cylinder',
      'location': 'Hodan-Mogadishu',
      'price': 18.0,
      'imagePath': 'assets/images/cylinder.png',
      'description': 'Compact 3kg cylinder perfect for small households or camping',
    },
    {
      'title': 'Refill - 6kg Cylinder',
      'location': 'Taleex-mog-somalia',
      'price': 12.0,
      'imagePath': 'assets/images/cylinder.png',
      'description': 'Gas refill service for your existing 6kg cylinder',
    },
  ];

  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = _allProducts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final title = product['title'].toLowerCase();
        final location = product['location'].toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    _cartController.addToCart(CartItem(
      title: product['title'],
      price: product['price'],
      location: product['location'],
      imagePath: product['imagePath'],
    ));

    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text('${product['title']} added to cart'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          title: product['title'],
          price: product['price'],
          location: product['location'],
          description: product['description'],
          imagePath: product['imagePath'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF00),
      body: Column(
        children: [
          // Header with Search (cart icon removed)
          Container(
            color: const Color(0xFF3E3EFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.location_on, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      "Taleex-mog-somalia",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search Bar
                Container(
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
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: Container(
              color: const Color(0xFFFFF1F5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _filteredProducts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search_off, size: 50, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No products found", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    Text("Try a different search term", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(product);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(product['imagePath']),
                    fit: BoxFit.cover,
                  ),
                ),
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
                        Text(product['location'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "\$${product['price'].toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    color: Colors.red,
                    onPressed: () => _addToCart(product),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
