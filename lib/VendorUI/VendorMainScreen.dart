import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  final List<IconData> _icons = const [
    Icons.inventory_2_rounded,
    Icons.shopping_cart,
    Icons.delivery_dining,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3E3EFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isActive = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 60 : 50,
              height: isActive ? 60 : 50,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Icon(
                _icons[index],
                color: isActive ? Colors.yellow : Colors.white,
                size: isActive ? 30 : 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}
