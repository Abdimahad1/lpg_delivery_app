import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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

  Future<bool> _onBackPressed() async {
    bool? exitApp = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit App", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to exit the system?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    return exitApp ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildDynamicAppBar(),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  PreferredSizeWidget? _buildDynamicAppBar() {
    if (_selectedIndex == 0) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Obx(() => SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Row(
            children: [
              Icon(
                Iconsax.location,
                color: const Color(0xFF3E3EFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Delivery to",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _profileController.userAddress.value.isNotEmpty
                          ? _profileController.userAddress.value
                          : "Add delivery address",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible:
              _profileController.unreadNotificationCount.value > 0,
              label: Text(
                  _profileController.unreadNotificationCount.value.toString()),
              child: const Icon(Iconsax.notification, color: Colors.black),
            ),
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: const Color(0xFF3E3EFF),
      automaticallyImplyLeading: false,
      elevation: 0,
      title: _selectedIndex == 3
          ? const Text(
        "Notifications",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      )
          : Obx(() => SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Row(
          children: [
            const Icon(Iconsax.location, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _profileController.userAddress.value.isNotEmpty
                    ? _profileController.userAddress.value
                    : "No location set",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
        Obx(() {
          final unreadCount =
              _profileController.unreadNotificationCount.value;
          return Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: IconButton(
              icon: const Icon(Iconsax.notification, color: Colors.white),
              onPressed: () => setState(() => _selectedIndex = 3),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Iconsax.search_normal, color: Colors.white),
          onPressed: () => setState(() => _selectedIndex = 1),
        ),
      ],
    );
  }


  Widget _buildBottomNavBar() {
    final List<IconData> _icons = [
      Iconsax.home,
      Iconsax.search_normal,
      Iconsax.shopping_cart,
      Iconsax.notification,
      Iconsax.profile_circle,
    ];

    final List<String> _labels = [
      "Home",
      "Search",
      "Cart",
      "Notifications",
      "Profile",
    ];

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isActive = _selectedIndex == index;
          final isCart = index == 2;
          final isNotification = index == 3;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
                if (isCart) {
                  _screens[2] = const CustomerCartScreen();
                }
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
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
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    if (isNotification)
                      Obx(() {
                        final count = _profileController.unreadNotificationCount.value;
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
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[index],
                  style: TextStyle(
                    color: isActive ? const Color(0xFF3E3EFF) : Colors.grey,
                    fontSize: 10,
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