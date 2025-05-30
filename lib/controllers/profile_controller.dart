import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/http_service.dart';
import '../config/api_config.dart';

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
  final Rx<File?> profileImage = Rx<File?>(null);

  final RxString userId = ''.obs;
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

  final RxBool isCartInitialized = false.obs;
  final RxList<Map<String, dynamic>> nearbyVendors = <Map<String, dynamic>>[].obs;
  final RxString vendorFetchError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTokenAndFetchProfile();
  }

  Future<void> _loadTokenAndFetchProfile() async {
    try {
      String? token = await storage.read(key: 'authToken');
      final prefs = await SharedPreferences.getInstance();

      // Fallback to shared preferences
      if (token == null || token.isEmpty) {
        token = prefs.getString('authToken');
        if (token != null && token.isNotEmpty) {
          await storage.write(key: 'authToken', value: token);
        }
      }

      if (token != null && token.isNotEmpty) {
        _authToken.value = token;
        fetchProfile();
        isCartInitialized.value = true;
        print("✅ Token loaded: $token");
      }
    } catch (e) {
      print("❌ Error loading token: $e");
    }
  }

  Future<void> setAuthToken(String token) async {
    _authToken.value = token;
    await storage.write(key: 'authToken', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    isCartInitialized.value = true;
    print("✅ Token saved");
  }

  Future<void> clearAuthToken() async {
    _authToken.value = '';
    await storage.delete(key: 'authToken');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    isCartInitialized.value = false;
    print("🔓 Token cleared");
  }

  Future<void> fetchProfile() async {
    if (authToken.isEmpty) {
      showSnackbar("Error", "Not authenticated");
      return;
    }

    isLoading.value = true;
    try {
      final res = await httpService.get('profile');
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          _updateProfileData(json['data']);
        } else {
          showSnackbar("Error", json['message'] ?? "Failed to fetch profile");
        }
      } else if (res.statusCode == 401) {
        await logout();
      } else {
        showSnackbar("Error", "Unexpected error: ${res.statusCode}");
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
    emailController.text = data['email'] ?? '';
    addressController.text = data['address'] ?? '';
    userAddress.value = data['address'] ?? '';
    shopNameController.text = data['shopName'] ?? '';
    profileImageUrl.value = data['profileImage'] ?? '';
    userId.value = data['_id'] ?? '';

    latitude.value = data['coordinates']?['lat']?.toDouble() ?? 0.0;
    longitude.value = data['coordinates']?['lng']?.toDouble() ?? 0.0;

    selectedLocation.value = latlng.LatLng(latitude.value, longitude.value);
    selectedAddress.value = userAddress.value;

    notifications.assignAll({
      "email": data['notifications']?['email'] ?? true,
      "inApp": data['notifications']?['inApp'] ?? true,
      "sms": data['notifications']?['sms'] ?? true,
    });
  }

  Future<void> updateProfile() async {
    if (authToken.isEmpty) {
      showSnackbar("Error", "Not authenticated");
      return;
    }

    isLoading.value = true;
    try {
      final fullAddress = addressController.text.trim();
      final district = fullAddress.split(',').first.trim();

      final body = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': fullAddress,
        'district': district,
        'coordinates': {
          'lat': latitude.value,
          'lng': longitude.value,
        },
        'email': emailController.text.trim(),
        'shopName': shopNameController.text.trim(),
        'notifications': notifications,
      };

      final res = await httpService.put('profile', body: body);
      final json = jsonDecode(res.body);

      if (res.statusCode == 200 && json['success'] == true) {
        _updateProfileData(json['data']);
        showSnackbar("Success", "Profile updated", isError: false);
      } else {
        showSnackbar("Error", json['message'] ?? "Update failed");
      }
    } catch (e) {
      showSnackbar("Error", "Update error: $e");
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
        'profile/upload',
        method: 'POST',
        fields: {},
        fileField: 'image',
        filePath: picked.path,
      );

      final responseBytes = await response.stream.toBytes();
      final responseString = utf8.decode(responseBytes);
      final json = jsonDecode(responseString);

      if (response.statusCode == 200 && json['success'] == true) {
        profileImage.value = File(picked.path);
        profileImageUrl.value = json['imageUrl'];
        showSnackbar("Success", "Image uploaded", isError: false);
      } else {
        showSnackbar("Error", json['message'] ?? "Upload failed");
      }
    } catch (e) {
      showSnackbar("Error", "Upload error: $e");
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
    profileImage.value = null;
    profileImageUrl.value = '';
    latitude.value = 0.0;
    longitude.value = 0.0;
    notifications.assignAll({"email": true, "inApp": true, "sms": true});
  }

  void toggleNotification(String key) {
    notifications[key] = !(notifications[key] ?? true);
  }

  Future<void> fetchNearbyVendors() async {
    try {
      vendorFetchError.value = '';
      final response = await http.get(
        Uri.parse('${baseUrl}profile/nearby'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        nearbyVendors.assignAll(List<Map<String, dynamic>>.from(data['data']));
      } else {
        vendorFetchError.value = 'Failed: ${response.body}';
      }
    } catch (e) {
      vendorFetchError.value = 'Error: $e';
    }
  }

  Future<Map<String, dynamic>?> getVendorProfile(String vendorId) async {
    try {
      final res = await http.get(
        Uri.parse('${baseUrl}profile/$vendorId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching vendor profile: $e');
      return null;
    }
  }

  void setSelectedLocation(double lat, double lng, String address) {
    selectedLocation.value = latlng.LatLng(lat, lng);
    selectedAddress.value = address;
    addressController.text = address;
    userAddress.value = address;
    latitude.value = lat;
    longitude.value = lng;
    fetchNearbyVendors();
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
