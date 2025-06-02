import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../../controllers/profile_controller.dart';
import '../Location/OSMLocationPickerScreen.dart';

class DeliveryProfileScreen extends StatefulWidget {
  const DeliveryProfileScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryProfileScreen> createState() => _DeliveryProfileScreenState();
}

class _DeliveryProfileScreenState extends State<DeliveryProfileScreen>
    with SingleTickerProviderStateMixin {
  late final ProfileController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isAddress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: ctrl,
        readOnly: isAddress,
        maxLines: isAddress ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: isAddress ? 16 : 0),
          suffixIcon: isAddress ? IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              final result = await Get.to(() => OSMLocationPickerScreen(
                initialLocation: controller.selectedLocation.value,
                initialAddress: controller.selectedAddress.value,
              ));

              if (result != null) {
                controller.setSelectedLocation(
                  result["lat"],
                  result["lng"],
                  result["address"],
                );
              }
            },
          ) : null,
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String label, String key) {
    return Obx(() {
      final val = controller.notifications[key] ?? true;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
          Container(
            decoration: BoxDecoration(
              color: val ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: GestureDetector(
              onTap: () => controller.toggleNotification(key),
              child: Text(
                val ? "ON" : "OFF",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: SafeArea(
        child: Obx(() => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: const BoxDecoration(
                color: Color(0xFF3E3EFF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Obx(() => GestureDetector(
                        onTap: controller.uploadImage,
                        child: ClipOval(
                          child: controller.profileImage.value != null
                              ? Image.file(
                            controller.profileImage.value!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : controller.profileImageUrl.value.isNotEmpty
                              ? FadeInImage(
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: const AssetImage("assets/images/user.png"),
                            image: NetworkImage(controller.profileImageUrl.value),
                            imageErrorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/images/user.png",
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            "assets/images/user.png",
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: controller.uploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Icon(Icons.edit, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Obx(() => Text(
                    controller.userName.value.isEmpty
                        ? "Delivery Person"
                        : controller.userName.value,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  )),
                ],
              ),
            ),

            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorColor: Colors.black,
              tabs: const [
                Tab(text: "Account"),
                Tab(text: "Notification"),
                Tab(text: "Log Out"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTextField("Name", controller.nameController),
                          _buildTextField("Phone", controller.phoneController),
                          _buildTextField("Address", controller.addressController, isAddress: true),
                          _buildTextField("Email", controller.emailController),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: controller.updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E3EFF),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text("Update", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationToggle("Email Notifications", "email"),
                        const SizedBox(height: 16),
                        _buildNotificationToggle("In App Notifications", "inApp"),
                        const SizedBox(height: 16),
                        _buildNotificationToggle("SMS Notifications", "sms"),
                      ],
                    ),
                  ),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text("Log Out"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
