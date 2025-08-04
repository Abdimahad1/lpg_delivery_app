import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'VendorOrdersScreen.dart';
import 'vendor_home_screen.dart';
import 'vendor_delivery_status_screen.dart';
import 'vendor_profile_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    VendorHomeScreen(),
    VendorOrdersScreen(),
    VendorDeliveryStatusScreen(),
    VendorProfileScreen(),
  ];

  final List<IconData> _icons = [
    Iconsax.shop,
    Iconsax.shopping_cart,
    Iconsax.truck,
    Iconsax.profile_circle,
  ];

  final List<String> _labels = [
    "Home",
    "Orders",
    "Delivery",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {

    return AppBar(
      backgroundColor: const Color(0xFF3E3EFF),
      elevation: 0,
      title: Text(
        _getAppBarTitle(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.notification, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return "Orders";
      case 2:
        return "Delivery Status";
      case 3:
        return "Profile";
      default:
        return "";
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isActive = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF3E3EFF).withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icons[index],
                    color: isActive ? const Color(0xFF3E3EFF) : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[index],
                  style: TextStyle(
                    color: isActive ? const Color(0xFF3E3EFF) : Colors.grey,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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