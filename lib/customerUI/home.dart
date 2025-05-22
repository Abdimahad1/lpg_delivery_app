import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/favorites_controller.dart';
import 'ProductDetailScreen.dart';

class CustomerHomeScreen extends StatelessWidget {
  final Function(int)? onTabSelected; // Passed from main screen for tab switching

  const CustomerHomeScreen({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF00),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Top bar is handled by CustomerMainScreen

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFFFF1F5),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vendors Section
                      _buildSectionHeader("Vendors Near You", "View more"),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(
                            child: VendorCard(
                              name: "HASS GAS",
                              imagePath: "assets/images/vendor.png",
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: VendorCard(
                              name: "HASS GAS",
                              imagePath: "assets/images/vendor.png",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Quick Actions
                      _buildSectionHeader("Getting Started Today", ""),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          QuickActionCard(
                            icon: Icons.propane_tank,
                            label: "Buy Cooking Gas",
                            onTap: () => onTabSelected?.call(1),
                          ),
                          const QuickActionCard(
                            icon: Icons.location_on,
                            label: "Locate Vendors",
                          ),
                          const QuickActionCard(
                            icon: Icons.history,
                            label: "Transaction History",
                          ),
                          QuickActionCard(
                            icon: Icons.person,
                            label: "My profile",
                            onTap: () => onTabSelected?.call(4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Products Section
                      _buildSectionHeader("Products", ""),
                      const SizedBox(height: 12),
                      ProductCard(
                        title: "6kg Cooking Gas Cylinder",
                        location: "Taleex-mog-somalia",
                        price: 24,
                        imagePath: "assets/images/cylinder.png",
                        description: "6kg cylinder is a wonderful Gas which will hold you 1 month and 5 days",
                      ),
                      ProductCard(
                        title: "12kg Cooking Gas Cylinder",
                        location: "Bakara-Mogadishu",
                        price: 38,
                        imagePath: "assets/images/cylinder.png",
                        description: "Premium 12kg cylinder for larger families or commercial use",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
}

// Vendor Card Widget
class VendorCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const VendorCard({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 60),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_pin, size: 16, color: Colors.red),
              SizedBox(width: 4),
              Text("Digfeer-Mog", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

// Quick Action Card Widget
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
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Product Card Widget
class ProductCard extends StatelessWidget {
  final String title;
  final String location;
  final double price;
  final String imagePath;
  final String description;

  final CartController cartController = Get.find();
  final FavoritesController favoritesController = Get.find();

  ProductCard({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.imagePath,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final item = FavoriteItem(
      title: title,
      price: price,
      location: location,
      imagePath: imagePath,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              title: title,
              price: price,
              location: location,
              imagePath: imagePath,
              description: description,
            ),
          ),
        );
      },
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
            Image.asset(imagePath, width: 50, height: 50),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Icon(Icons.location_pin, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                      onPressed: () {
                        cartController.addToCart(CartItem(
                          title: title,
                          price: price,
                          location: location,
                          imagePath: imagePath,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$title added to cart')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Price:  \$${price.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
