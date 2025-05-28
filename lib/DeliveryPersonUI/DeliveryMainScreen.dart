import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'DeliveryHistoryScreen.dart';
import 'DeliveryHomeScreen.dart';
import 'DeliveryProfileScreen.dart';
import 'DeliveryTasksScreen.dart';

class DeliveryMainScreen extends StatefulWidget {
  const DeliveryMainScreen({super.key});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DeliveryHomeScreen(),
    const DeliveryTasksScreen(),
    const DeliveryHistoryScreen(),
    const DeliveryProfileScreen(),
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.delivery_dining,
    Icons.history,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3E3EFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          final isActive = index == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 60 : 50,
              height: isActive ? 60 : 50,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [const BoxShadow(color: Colors.black26, blurRadius: 6)]
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
