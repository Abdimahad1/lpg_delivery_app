import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart' as http;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/http_service.dart';
import '../config/api_config.dart';
import '../customerUI/home.dart';

class ProfileController extends GetxController {
  final storage = const FlutterSecureStorage();
  final HttpService httpService = Get.find();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final shopNameController = TextEditingController();

  final isLoading = false.obs;
  final picker = ImagePicker();
  File? profileImage;

  final RxString profileImageUrl = ''.obs;
  final RxString userName = ''.obs;
  final RxString userAddress = ''.obs;

  final RxString _authToken = ''.obs;
  String get authToken => _authToken.value;
  RxString get rxAuthToken => _authToken;


  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;


  final Rx<latlng.LatLng?> selectedLocation = Rx<latlng.LatLng?>(null);
  final RxString selectedAddress = "".obs;

  final notifications = <String, bool>{
    "email": true,
    "inApp": true,
    "sms": true,
  }.obs;

  // Add this for cart persistence
  final RxBool isCartInitialized = false.obs;

  // Observable list for nearby vendors
  final RxList<Map<String, dynamic>> nearbyVendors = <Map<String, dynamic>>[].obs;

  final RxString vendorFetchError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTokenAndFetchProfile();
  }

  Future<void> _loadTokenAndFetchProfile() async {
    try {
      // Try secure storage first
      final token = await storage.read(key: 'authToken');

      // Fallback to shared preferences if not found
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final fallbackToken = prefs.getString('authToken');
        if (fallbackToken != null && fallbackToken.isNotEmpty) {
          await storage.write(key: 'authToken', value: fallbackToken);
        }
      }

      final finalToken = await storage.read(key: 'authToken');
      if (finalToken != null && finalToken.isNotEmpty) {
        _authToken.value = finalToken;
        fetchProfile();
        // Notify cart controller to initialize
        isCartInitialized.value = true;
      }
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> setAuthToken(String token) async {
    _authToken.value = token;
    await storage.write(key: 'authToken', value: token);
    // Also store in shared preferences as fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    // Notify cart controller to initialize
    isCartInitialized.value = true;
  }

  Future<void> clearAuthToken() async {
    _authToken.value = '';
    await storage.delete(key: 'authToken');
    // Also remove from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    // Notify cart controller to clear
    isCartInitialized.value = false;
  }

  void showSnackbar(String title, String message, {bool isError = true}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> fetchProfile() async {
    if (authToken.isEmpty) {
      showSnackbar("Error", "Not authenticated");
      return;
    }

    isLoading.value = true;
    try {
      final res = await httpService.get('api/profile');

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          _updateProfileData(body['data']);
        } else {
          showSnackbar("Error", body['message'] ?? "Profile fetch failed");
        }
      } else if (res.statusCode == 401) {
        await logout();
      } else {
        showSnackbar("Error", "Unexpected response: ${res.statusCode}");
      }
    } catch (e) {
      showSnackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _updateProfileData(Map<String, dynamic> data) {
    nameController.text = data['name'] ?? '';
    userName.value = data['name'] ?? '';
    phoneController.text = data['phone'] ?? '';
    addressController.text = data['address'] ?? '';
    userAddress.value = data['address'] ?? '';
    emailController.text = data['email'] ?? '';
    profileImageUrl.value = data['profileImage'] ?? '';
    shopNameController.text = data['shopName'] ?? '';

    final coord = data['coordinates'];
    latitude.value = coord?['lat']?.toDouble() ?? 0.0;
    longitude.value = coord?['lng']?.toDouble() ?? 0.0;

    final notif = data['notifications'] ?? {};
    notifications.assignAll({
      "email": notif['email'] ?? true,
      "inApp": notif['inApp'] ?? true,
      "sms": notif['sms'] ?? true,
    });
  }

  Future<void> updateProfile() async {
    if (authToken.isEmpty) {
      showSnackbar("Error", "Not authenticated");
      return;
    }

    isLoading.value = true;
    try {
      final body = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'coordinates': {
          'lat': latitude.value,
          'lng': longitude.value,
        },
        'email': emailController.text.trim(),
        'shopName': shopNameController.text.trim(),
        'notifications': notifications,
      };

      final res = await httpService.put('api/profile', body: body);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200 && json['success'] == true) {
        userName.value = nameController.text.trim();
        userAddress.value = addressController.text.trim();
        showSnackbar("Success", "Profile updated successfully", isError: false);
      } else {
        showSnackbar("Error", json['message'] ?? "Update failed");
      }
    } catch (e) {
      showSnackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadImage() async {
    if (authToken.isEmpty) {
      showSnackbar("Error", "Not authenticated");
      return;
    }

    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    isLoading.value = true;
    try {
      final response = await httpService.multipartRequest(
        'api/profile/upload',
        method: 'POST',
        fields: {},
        fileField: 'image',
        filePath: picked.path,
      );

      // Get the response as bytes first
      final responseBytes = await response.stream.toBytes();
      // Convert to string
      final responseString = utf8.decode(responseBytes);
      // Parse the JSON
      final json = jsonDecode(responseString);

      if (response.statusCode == 200) {
        if (json['success'] == true) {
          profileImage = File(picked.path);
          profileImageUrl.value = json['imageUrl'];
          showSnackbar("Success", "Image uploaded", isError: false);
        } else {
          showSnackbar("Error", json['message'] ?? "Upload failed");
        }
      } else {
        showSnackbar("Error", "Image upload failed");
      }
    } catch (e) {
      showSnackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await clearAuthToken();
    resetProfileData();
    Get.offAllNamed('/login');
  }

  void resetProfileData() {
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    emailController.clear();
    shopNameController.clear();
    userName.value = '';
    userAddress.value = '';
    latitude.value = 0.0;
    longitude.value = 0.0;
    profileImage = null;
    profileImageUrl.value = '';
    notifications.assignAll({"email": true, "inApp": true, "sms": true});
  }

  void toggleNotification(String key) {
    notifications[key] = !(notifications[key] ?? true);
  }

  Future<void> fetchNearbyVendors() async {
    try {
      print('Fetching nearby vendors...'); // Debugging statement
      vendorFetchError.value = ''; // Reset error message
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/nearby'), // ✅ correct route
        headers: {'Authorization': 'Bearer $authToken'},
      );


      print('Response status: ${response.statusCode}'); // Debugging statement

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched vendors: ${data['data']}'); // Debugging statement
        nearbyVendors.assignAll(List<Map<String, dynamic>>.from(data['data']));
      } else {
        vendorFetchError.value = 'Failed to fetch vendors: ${response.body}'; // Set error message
        print('Failed to fetch vendors: ${response.body}'); // Debugging statement
      }
    } catch (e) {
      vendorFetchError.value = 'Error fetching nearby vendors: $e'; // Set error message
      print('Error fetching nearby vendors: $e'); // Debugging statement
    }
  }

  void setSelectedLocation(double lat, double lng, String address) {
    selectedLocation.value = latlng.LatLng(lat, lng);
    selectedAddress.value = address;
    addressController.text = address;
    userAddress.value = address;
    fetchNearbyVendors(); // Call the new method
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    shopNameController.dispose();
    super.onClose();
  }
}