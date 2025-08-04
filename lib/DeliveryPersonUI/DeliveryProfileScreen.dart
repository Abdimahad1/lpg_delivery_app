import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        readOnly: isAddress,
        maxLines: isAddress ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isAddress
              ? IconButton(
            icon: const Icon(Iconsax.location, color: Color(0xFF3E3EFF)),
            onPressed: () async {
              final result = await Get.to(() => OSMLocationPickerScreen(
                initialLocation: controller.selectedLocation.value,
                initialAddress: controller.addressController.text,
              ));

              if (result != null) {
                controller.setSelectedLocation(
                  result["lat"],
                  result["lng"],
                  result["address"],
                );
              }
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      value: controller.notifications[key] ?? true,
      activeColor: const Color(0xFF3E3EFF),
      onChanged: (_) => controller.toggleNotification(key),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out of your account?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GetX<ProfileController>(
        builder: (ctrl) {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40, bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3EFF).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: ctrl.uploadImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: ctrl.profileImage.value != null
                                ? FileImage(ctrl.profileImage.value!)
                                : ctrl.profileImageUrl.value.isNotEmpty
                                ? NetworkImage(ctrl.profileImageUrl.value)
                                : const AssetImage("assets/images/user.png") as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: ctrl.uploadImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3E3EFF),
                              ),
                              child: const Icon(Iconsax.camera, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ctrl.userName.value.isEmpty ? "Delivery Person" : ctrl.userName.value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ctrl.emailController.text,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF3E3EFF),
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  indicatorColor: const Color(0xFF3E3EFF),
                  tabs: const [
                    Tab(text: "Profile"),
                    Tab(text: "Notifications"),
                    Tab(text: "Account"),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Profile Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildTextField("Full Name", ctrl.nameController),
                          _buildTextField("Phone Number", ctrl.phoneController),
                          _buildTextField("Address", ctrl.addressController, isAddress: true),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: ctrl.updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF90CDDC),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Update Profile",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notifications Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("NOTIFICATION SETTINGS",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          _buildNotificationSwitch("App Notifications", "inApp"),
                          const Divider(height: 32),
                        ],
                      ),
                    ),

                    // Account Tab
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Divider(),
                          ListTile(
                            leading: const Icon(Iconsax.logout, color: Colors.red),
                            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
                            onTap: _showLogoutDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
