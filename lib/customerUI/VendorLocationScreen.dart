import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class VendorLocationScreen extends StatefulWidget {
  final latlng.LatLng vendorLocation;
  final String vendorName;

  const VendorLocationScreen({
    Key? key,
    required this.vendorLocation,
    required this.vendorName,
  }) : super(key: key);

  @override
  State<VendorLocationScreen> createState() => _VendorLocationScreenState();
}

class _VendorLocationScreenState extends State<VendorLocationScreen> {
  late final MapController _mapController;
  late latlng.LatLng _userLocation;
  String _vendorAddress = "Loading address...";
  String _userAddress = "Loading address...";
  bool _isLoading = true;

  final ProfileController profileController = Get.find();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocations();
  }

  Future<void> _initializeLocations() async {
    final userLat = profileController.latitude.value;
    final userLng = profileController.longitude.value;

    if (userLat == 0.0 && userLng == 0.0) {
      _userLocation = const latlng.LatLng(2.0469, 45.3182); // fallback to Mogadishu
    } else {
      _userLocation = latlng.LatLng(userLat, userLng);
    }

    await _fetchAddress(widget.vendorLocation, isVendor: true);
    await _fetchAddress(_userLocation, isVendor: false);

    setState(() => _isLoading = false);
  }

  Future<void> _fetchAddress(latlng.LatLng point, {required bool isVendor}) async {
    final url = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'json',
      },
    );

    try {
      final response = await http.get(url, headers: {'User-Agent': 'lpg-delivery-app'});
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final address = json['display_name'] ?? 'Unknown address';
        setState(() {
          if (isVendor) {
            _vendorAddress = address;
          } else {
            _userAddress = address;
          }
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendorName),
        backgroundColor: const Color(0xFF3E3EFF),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.vendorLocation,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.vendorLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.store_mall_directory, color: Colors.blue, size: 50),
                  ),
                  Marker(
                    point: _userLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 50),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_userLocation, widget.vendorLocation],
                    color: Colors.red,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            ],
          ),

          // Address details
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildAddressBox("Vendor Address", _vendorAddress),
                const SizedBox(height: 10),
                _buildAddressBox("Your Location", _userAddress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBox(String title, String address) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_pin, color: Colors.red[400]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(address, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
