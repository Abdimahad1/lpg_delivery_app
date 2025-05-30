import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class OSMLocationPickerScreen extends StatefulWidget {
  final latlng.LatLng? initialLocation;
  final String? initialAddress;

  const OSMLocationPickerScreen({
    Key? key,
    this.initialLocation,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<OSMLocationPickerScreen> createState() => _OSMLocationPickerScreenState();
}

class _OSMLocationPickerScreenState extends State<OSMLocationPickerScreen> {
  late final MapController _mapController;
  late latlng.LatLng _pickedLocation;
  String _address = "Searching address...";
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingAddress = false;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation ?? const latlng.LatLng(2.0469, 45.3182);
    _address = widget.initialAddress ?? "Searching address...";
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askLocationPermissionAndFetch();
    });
  }

  Future<void> _askLocationPermissionAndFetch() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      final location = Location();
      final currentLocation = await location.getLocation();

      final userLatLng = latlng.LatLng(currentLocation.latitude!, currentLocation.longitude!);
      setState(() {
        _pickedLocation = userLatLng;
        _address = "Fetching your current address...";
      });
      _mapController.move(userLatLng, 19);
      _fetchAddressFromCoordinates(userLatLng);
    } else {
      _fetchAddressFromCoordinates(_pickedLocation);
      Get.snackbar("Permission Denied", "You can manually select a location or allow access.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _fetchAddressFromCoordinates(latlng.LatLng latLng) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);

    final url = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': latLng.latitude.toString(),
        'lon': latLng.longitude.toString(),
        'format': 'json',
        'zoom': '19',
        'addressdetails': '1'
      },
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'lpg-delivery-app'
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _address = _formatAddress(data);
        });
      } else {
        setState(() {
          _address = "Failed to get address (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Error: ${e is TimeoutException ? 'Timeout' : e.toString()}";
      });
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  String _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;

    if (address == null || address.isEmpty) {
      return data['display_name'] ?? 'Address not found';
    }

    final components = [
      address['house_number'],
      address['road'],
      address['neighbourhood'],
      address['suburb'],
      address['city'] ?? address['town'],
      address['state'],
      address['country'],
    ].where((c) => c != null).join(', ');

    return components.isNotEmpty ? components : data['display_name'] ?? 'Address not found';
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    final url = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'limit': '1'
      },
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'lpg-delivery-app'
      });

      final results = json.decode(response.body) as List<dynamic>;

      if (results.isNotEmpty) {
        final result = results[0];
        final lat = double.tryParse(result['lat']);
        final lon = double.tryParse(result['lon']);

        if (lat != null && lon != null) {
          final newLocation = latlng.LatLng(lat, lon);
          setState(() {
            _pickedLocation = newLocation;
            _address = "Searching address...";
          });
          _mapController.move(newLocation, 19);
          _fetchAddressFromCoordinates(newLocation);
        }
      } else {
        Get.snackbar("Not Found", "No location found for '$query'",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to search location",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _onTapMap(TapPosition tapPosition, latlng.LatLng point) {
    setState(() {
      _pickedLocation = point;
      _address = "Searching address...";
    });
    _mapController.move(point, 19);
    _fetchAddressFromCoordinates(point);
  }

  Future<void> _confirmLocation() async {
    if (_isLoadingAddress) return;

    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Get.back(result: {
      "lat": _pickedLocation.latitude,
      "lng": _pickedLocation.longitude,
      "address": _address,
    });
  }

  void _centerMap() {
    _mapController.move(_pickedLocation, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Your Location"),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMap,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onTap: _onTapMap,
              initialCenter: _pickedLocation,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 60,
                    height: 60,
                    point: _pickedLocation,
                    child: const Icon(Icons.location_pin, size: 60, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📍 Selected Address", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _isLoadingAddress
                      ? Row(
                    children: const [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text("Loading address...")
                    ],
                  )
                      : Text(
                    _address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingAddress ? null : _confirmLocation,
        icon: _isConfirming
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Icon(Icons.check),
        label: Text(_isConfirming ? "Confirming..." : "Use this location"),
        backgroundColor: _isLoadingAddress ? Colors.grey : theme.colorScheme.primary,
      ),
    );
  }
}
