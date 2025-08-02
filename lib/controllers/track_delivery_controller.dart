import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' hide PermissionStatus;
import '../config/api_config.dart';
import 'profile_controller.dart';

class TrackDeliveryController extends GetxController {
  final deliveryStatus = "Out For Delivery".obs;
  final estTime = "Calculating...".obs;
  final distanceValue = "0".obs;
  final isLoading = false.obs;

  final vendorLocation = Rx<LatLng?>(null);
  final customerLocation = Rx<LatLng?>(null);
  final myLocation = Rx<LatLng?>(null);
  final mapCenter = Rx<LatLng>(const LatLng(0.0, 0.0));

  final showMap = true.obs;
  final isRefreshing = false.obs;
  final _refreshCounter = 0.obs;

  RxInt get refreshTrigger => _refreshCounter;

  late Map<String, dynamic> task;
  late Location _locationService;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void onInit() {
    super.onInit();
    _locationService = Location();
    _setupLocationUpdates();
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    super.onClose();
  }

  void _setupLocationUpdates() {
    _locationSubscription = _locationService.onLocationChanged.listen((locationData) {
      if (deliveryStatus.value != "Delivered") {
        myLocation.value = LatLng(locationData.latitude!, locationData.longitude!);
        _calculateDistanceAndTime();
        _centerMap();
      }
    });
  }

  Future<void> refreshAllData() async {
    isLoading.value = true;
    await _fetchCurrentLocation();
    if (task['address'] != null) {
      final coords = await geocodeAddress(task['address']);
      if (coords != null) {
        customerLocation.value = coords;
      }
    }
    _calculateDistanceAndTime();
    _centerMap();
    isLoading.value = false;
  }

  void initialize(Map<String, dynamic> taskData) async {
    task = taskData;
    final profileController = Get.find<ProfileController>();

    vendorLocation.value = LatLng(
      profileController.latitude.value,
      profileController.longitude.value,
    );

    if (task['productLocation'] != null &&
        task['productLocation']['lat'] != null &&
        task['productLocation']['lng'] != null) {
      customerLocation.value = LatLng(
        task['productLocation']['lat'].toDouble(),
        task['productLocation']['lng'].toDouble(),
      );
    } else if (task['address'] != null) {
      final coords = await geocodeAddress(task['address']);
      if (coords != null) {
        customerLocation.value = coords;
      } else {
        Get.snackbar("Location Error", "Could not find coordinates for customer's address.");
      }
    }

    await _fetchCurrentLocation();
    _centerMap();
    _calculateDistanceAndTime();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      isRefreshing.value = true;

      PermissionStatus permission = await _locationService.hasPermission();
      if (permission != PermissionStatus.granted) {
        permission = await _locationService.requestPermission();
        if (permission != PermissionStatus.granted) {
          isRefreshing.value = false;
          return;
        }
      }

      final current = await _locationService.getLocation();
      myLocation.value = LatLng(current.latitude!, current.longitude!);
      _calculateDistanceAndTime();
      _centerMap();
    } catch (e) {
      debugPrint("Error fetching location: $e");
      Get.snackbar("Error", "Could not fetch location: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<LatLng?> geocodeAddress(String address) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': address,
      'format': 'json',
      'limit': '1',
    });

    try {
      final response = await http.get(url, headers: {'User-Agent': 'lpg-delivery-app'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']);
          final lon = double.tryParse(data[0]['lon']);
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }

    return null;
  }

  void _calculateDistanceAndTime() {
    if (myLocation.value != null && customerLocation.value != null) {
      final Distance distance = const Distance();
      final double km = distance.as(
        LengthUnit.Kilometer,
        myLocation.value!,
        customerLocation.value!,
      );

      final int minutes = max(2, (km * 12).round());
      estTime.value = "$minutes min";
      distanceValue.value = km.toStringAsFixed(2);
    } else {
      estTime.value = "Calculating...";
      distanceValue.value = "0";
    }
  }

  Future<void> markAsDelivered() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.patch(
        Uri.parse("${baseUrl}tasks/mark-delivered/${task['_id']}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200 && resData['success'] == true) {
        deliveryStatus.value = "Delivered";
        _locationSubscription?.cancel();

        Get.snackbar(
          "✅ Success",
          "Task marked as delivered",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception(resData['message'] ?? "Failed to update status");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to mark as delivered: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  LatLng _getMidpoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  void toggleMapVisibility() {
    showMap.toggle();
  }

  Future<void> refreshMap() async {
    await _fetchCurrentLocation();
    _refreshCounter.value++;
  }

  void _centerMap() {
    if (myLocation.value != null && customerLocation.value != null) {
      mapCenter.value = _getMidpoint(myLocation.value!, customerLocation.value!);
    } else if (customerLocation.value != null) {
      mapCenter.value = customerLocation.value!;
    } else if (myLocation.value != null) {
      mapCenter.value = myLocation.value!;
    }
  }

  void centerMapOnCurrentLocation() {
    if (myLocation.value != null) {
      mapCenter.value = myLocation.value!;
      _refreshCounter.value++;
    }
  }

  Future<Map<String, dynamic>> sendNotification(String message, String customerId) async {
    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken;

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}notifications/send"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "senderName": "DELIVERY MESSAGE",
          "message": message,
          "receiverId": customerId,
        }),
      );

      final res = jsonDecode(response.body);
      return res;
    } catch (e) {
      debugPrint("Notification send error: $e");
      rethrow;
    }
  }
}