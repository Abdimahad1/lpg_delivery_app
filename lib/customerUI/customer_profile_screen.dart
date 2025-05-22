import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> with SingleTickerProviderStateMixin {
  File? _imageFile;
  final picker = ImagePicker();

  final nameController = TextEditingController(text: "Abdi Hussein");
  final phoneController = TextEditingController(text: "+252 613******");
  final addressController = TextEditingController(text: "Digfeer-Mog-Som");
  final emailController = TextEditingController(text: "abdi@gmail.com");

  late TabController _tabController;

  bool emailNotifications = true;
  bool inAppNotifications = true;
  bool smsNotifications = true;

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _saveProfile() {
    // You can add actual saving logic here
    Get.snackbar(
      "Success",
      "Profile updated successfully!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        Container(
          decoration: BoxDecoration(
            color: value ? Colors.green : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              value ? "ON" : "OFF",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Profile Image and Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: const BoxDecoration(
                color: Color(0xFF3E3EFF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      _imageFile != null ? FileImage(_imageFile!) : const AssetImage("assets/images/user.png") as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Abdi", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Tabs
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

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Account Tab
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTextField("Name", nameController),
                          _buildTextField("Phone", phoneController),
                          _buildTextField("Address", addressController),
                          _buildTextField("Email", emailController),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E3EFF),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: const Text(
                              "Update",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notification Tab
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationToggle("Email Notifications", emailNotifications, (val) {
                          setState(() => emailNotifications = val);
                        }),
                        const SizedBox(height: 16),
                        _buildNotificationToggle("In App Notifications", inAppNotifications, (val) {
                          setState(() => inAppNotifications = val);
                        }),
                        const SizedBox(height: 16),
                        _buildNotificationToggle("SMS Notifications", smsNotifications, (val) {
                          setState(() => smsNotifications = val);
                        }),
                      ],
                    ),
                  ),

                  // Log Out Tab
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Confirm Logout",
                          content: const Text("Are you sure you want to log out?"),
                          confirm: ElevatedButton(
                            onPressed: () => Get.offAllNamed('/login'),
                            child: const Text("Yes"),
                          ),
                          cancel: TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Cancel"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Log Out"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
