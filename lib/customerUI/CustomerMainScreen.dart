import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/profile_controller.dart';

// Screens
import 'CustomerNotificationsScreen.dart';
import 'CustomerCartScreen.dart';
import 'customer_search_screen.dart';
import 'home.dart';
import 'customer_profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;
  final CartController _cartController = Get.find();
  final ProfileController _profileController = Get.find();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CustomerHomeScreen(onTabSelected: (index) => setState(() => _selectedIndex = index)),
      const CustomerSearchScreen(),
      const CustomerCartScreen(),
      const CustomerNotificationsScreen(),
      const CustomerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFF00),
      appBar: _buildDynamicAppBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget? _buildDynamicAppBar() {
    if (_selectedIndex == 0) return null;

    return AppBar(
      backgroundColor: const Color(0xFF3E3EFF),
      automaticallyImplyLeading: false,
      elevation: 0,
      title: _selectedIndex == 3
          ? const Text("🔔 Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          : Obx(() => SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // Limit width
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _profileController.userAddress.value.isNotEmpty
                    ? _profileController.userAddress.value
                    : "No location set",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Smaller font size
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      )),
      actions: _selectedIndex == 3
          ? []
          : [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () => setState(() => _selectedIndex = 3),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => setState(() => _selectedIndex = 1),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    final List<IconData> _icons = [
      Icons.home,
      Icons.search,
      Icons.shopping_cart,
      Icons.notifications,
      Icons.person,
    ];

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
          final isCart = index == 2;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
                if (isCart) {
                  _screens[2] = const CustomerCartScreen();
                }
              });
            },
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                AnimatedContainer(
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
                if (isCart)
                  Obx(() {
                    final count = _cartController.cartItems.length;
                    if (count == 0) return const SizedBox();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ),
    );
  }
}