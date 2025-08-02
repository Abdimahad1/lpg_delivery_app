import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class OSMLocationPickerScreen extends StatefulWidget {
  final latlng.LatLng? initialLocation;
  final String? initialAddress;
  final bool show3DBuildings;

  const OSMLocationPickerScreen({
    Key? key,
    this.initialLocation,
    this.initialAddress,
    this.show3DBuildings = true,
  }) : super(key: key);

  @override
  State<OSMLocationPickerScreen> createState() => _EnhancedOSMLocationPickerScreenState();
}

class _EnhancedOSMLocationPickerScreenState extends State<OSMLocationPickerScreen> {
  late final MapController _mapController;
  late latlng.LatLng _pickedLocation;
  String _address = "Searching address...";
  String? _district;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingAddress = false;
  bool _isConfirming = false;
  double _zoomLevel = 16.0;
  bool _showSatelliteView = false;
  bool _show3DBuildings = true;

  // List of all 17 districts in Mogadishu
  final List<String> _mogadishuDistricts = [
    'Abdiaziz',
    'Bondhere',
    'Dayniile',
    'Dharkenley',
    'Hamar-Jajab',
    'Hamar-Weyne',
    'Hodan',
    'Howl-Wadag',
    'Huriwa',
    'Karaan',
    'Shangani',
    'Shibis',
    'Waberi',
    'Wadajir',
    'Wartanabada',
    'Yaqshid',
    'Heliwaa'
  ];

  // Spelling corrections map
  final Map<String, String> _spellingCorrections = {
    'deyniile': 'dayniile',
    'helwa': 'heliwaa',
    'huriwaa': 'huriwa',
    'howlwadag': 'howl-wadag',
    'hamarjajab': 'hamar-jajab',
    'shangaani': 'shangani',
    'wardhiigleey': 'wardhiigley',
    'wadajirr': 'wadajir'
  };

  // Popular locations in Mogadishu
  final List<Map<String, dynamic>> _popularLocations = [
    {
      'name': 'Aden Adde International Airport',
      'lat': 2.0142,
      'lng': 45.3047,
      'icon': Icons.airplanemode_active,
      'color': Colors.blue,
      'district': 'Dayniile'
    },
    {
      'name': 'Liido Beach',
      'lat': 2.0396,
      'lng': 45.3415,
      'icon': Icons.beach_access,
      'color': Colors.teal,
      'district': 'Hamar-Weyne'
    },
    {
      'name': 'Bakara Market',
      'lat': 2.0391,
      'lng': 45.3419,
      'icon': Icons.shopping_cart,
      'color': Colors.orange,
      'district': 'Hodan'
    },
    {
      'name': 'Mogadishu Port',
      'lat': 2.0386,
      'lng': 45.3386,
      'icon': Icons.directions_boat,
      'color': Colors.indigo,
      'district': 'Hamar-Weyne'
    },
    {
      'name': 'KM4 Junction',
      'lat': 2.0428,
      'lng': 45.3264,
      'icon': Icons.traffic,
      'color': Colors.red,
      'district': 'Hodan'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation ?? const latlng.LatLng(2.0469, 45.3182);
    _address = widget.initialAddress ?? "Searching address...";
    _mapController = MapController();
    _show3DBuildings = widget.show3DBuildings;

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
      Get.snackbar(
        "Permission Denied",
        "You can manually select a location or allow access.",
        snackPosition: SnackPosition.BOTTOM,
      );
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
        'addressdetails': '1',
        'accept-language': 'en'
      },
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'lpg-delivery-app'
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        final displayName = data['display_name']?.toString();

        setState(() {
          _address = _formatAddress(data);
          _district = _extractDistrict(address, displayName); // ✅ Use both for full fallback
        });
      } else {
        setState(() {
          _address = "Failed to get address (${response.statusCode})";
          _district = null;
        });
      }
    } catch (e) {
      setState(() {
        _address = "Error: ${e is TimeoutException ? 'Timeout' : e.toString()}";
        _district = null;
      });
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }


  String? _extractDistrict(Map<String, dynamic>? address, [String? displayName]) {
    if (address == null) return null;

    // 1. Try direct OpenStreetMap keys that might contain district names
    final rawDistrict = address['city_district'] ??
        address['suburb'] ??
        address['neighbourhood'] ??
        address['quarter'];

    String? district = rawDistrict?.toString();

    // 2. If not found, extract from display_name by matching known districts
    if ((district == null || district.trim().isEmpty) && displayName != null) {
      final displayLower = displayName.toLowerCase();
      for (final known in _mogadishuDistricts) {
        if (displayLower.contains(known.toLowerCase())) {
          district = known;
          break;
        }
      }
    }

    // 3. Apply spelling corrections (e.g., "deyniile" → "Dayniile")
    if (district != null) {
      final normalized = district.toLowerCase().trim();
      return _spellingCorrections[normalized] ?? _capitalizeWords(district);
    }

    return null;
  }

// Optional helper to make district names look nice (e.g., "dayniile" => "Dayniile")
  String _capitalizeWords(String input) {
    return input
        .split(' ')
        .map((word) => word.isNotEmpty
        ? word[0].toUpperCase() + word.substring(1).toLowerCase()
        : word)
        .join(' ');
  }



  String _formatAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null || address.isEmpty) {
      return data['display_name'] ?? 'Address not found';
    }

    // Extract and normalize district name directly from address or display name
    final extractedDistrict = _extractDistrict(address, data['display_name']);

    final components = [
      address['road'],
      if (address['house_number'] != null) 'House ${address['house_number']}',
      if (extractedDistrict != null) 'District: $extractedDistrict',
      address['city'] ?? address['town'] ?? address['village'],
      'Banaadir',
      'Somalia',
    ].where((c) => c != null && c.toString().trim().isNotEmpty).join(', ');

    return components.isNotEmpty
        ? components
        : data['display_name'] ?? 'Address not found';
  }


  Future<List<String>> _getDistrictSuggestions(String query) async {
    if (query.isEmpty) return [];

    // Apply spelling corrections
    final correctedQuery = _spellingCorrections[query.toLowerCase()] ?? query;

    return _mogadishuDistricts.where((district) {
      return district.toLowerCase().contains(correctedQuery.toLowerCase());
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _searchLocation(String query) async {
    if (query.isEmpty) return [];

    // First check if it's a district name
    final districtMatches = _mogadishuDistricts.where(
            (d) => d.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (districtMatches.isNotEmpty) {
      return districtMatches.map((d) => {
        'display_name': 'District: $d',
        'lat': 2.0469, // Approximate Mogadishu center
        'lon': 45.3182,
        'type': 'district'
      }).toList();
    }

    // Search OSM if no district match
    final url = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'limit': '5',
        'countrycodes': 'so',
        'viewbox': '45.20,1.90,45.50,2.20', // Mogadishu bounding box
        'bounded': '1',
        'accept-language': 'en'
      },
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'lpg-delivery-app'
      });

      final results = json.decode(response.body) as List<dynamic>;
      return results.map((r) => r as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  void _moveToLocation(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');

    if (lat != null && lon != null) {
      final newLocation = latlng.LatLng(lat, lon);
      setState(() {
        _pickedLocation = newLocation;
        _address = "Searching address...";
        _district = null;
      });
      _mapController.move(newLocation, result['type'] == 'district' ? 14 : 18);
      _fetchAddressFromCoordinates(newLocation);
    }
  }

  void _onTapMap(TapPosition tapPosition, latlng.LatLng point) {
    setState(() {
      _pickedLocation = point;
      _address = "Searching address...";
      _district = null;
    });
    _mapController.move(point, _mapController.camera.zoom);
    _fetchAddressFromCoordinates(point);
  }

  void _onMapEvent(MapEvent mapEvent) {
    if (mapEvent is MapEventMove) {
      setState(() {
        _zoomLevel = mapEvent.camera.zoom;
      });
    }
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
      "district": _district,
    });
  }

  void _centerMap() {
    _mapController.move(_pickedLocation, _mapController.camera.zoom);
  }

  void _toggleMapStyle() {
    setState(() {
      _showSatelliteView = !_showSatelliteView;
    });
  }

  void _toggle3DBuildings() {
    setState(() {
      _show3DBuildings = !_show3DBuildings;
    });
  }

  Widget _buildPopularLocationsButton() {
    return FloatingActionButton(
      heroTag: 'popular_locations',
      mini: true,
      onPressed: () => _showPopularLocationsDialog(),
      child: const Icon(Icons.star),
      tooltip: 'Popular Locations',
    );
  }

  Future<void> _showPopularLocationsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Popular Locations in Mogadishu"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _popularLocations.length,
            itemBuilder: (context, index) {
              final location = _popularLocations[index];
              return ListTile(
                leading: Icon(location['icon'], color: location['color']),
                title: Text(location['name']),
                subtitle: Text(location['district']),
                onTap: () {
                  Navigator.pop(context);
                  final latLng = latlng.LatLng(location['lat'], location['lng']);
                  setState(() {
                    _pickedLocation = latLng;
                    _address = "Searching address...";
                  });
                  _mapController.move(latLng, 18);
                  _fetchAddressFromCoordinates(latLng);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TypeAheadField<Map<String, dynamic>>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search district or location...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
              ),
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: () {}, // Placeholder for voice search
                tooltip: 'Voice Search',
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      suggestionsCallback: (pattern) async {
        // First check district matches
        final districtMatches = await _getDistrictSuggestions(pattern);
        if (districtMatches.isNotEmpty) {
          return districtMatches.map((d) => {
            'display_name': 'District: $d',
            'type': 'district'
          }).toList();
        }
        // Fall back to OSM search
        return await _searchLocation(pattern);
      },
      itemBuilder: (context, suggestion) {
        final isDistrict = suggestion['type'] == 'district';
        return ListTile(
          leading: Icon(isDistrict ? Icons.map : Icons.location_on),
          title: Text(
            suggestion['display_name'],
            style: TextStyle(
              fontWeight: isDistrict ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: isDistrict ? null : Text('Tap to view location'),
        );
      },
      onSuggestionSelected: (suggestion) {
        _moveToLocation(suggestion);
        _searchController.text = suggestion['display_name'];
      },
      noItemsFoundBuilder: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No locations found. Try a district name like "Hodan" or "Dayniile"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
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
            icon: const Icon(Icons.satellite),
            onPressed: _toggleMapStyle,
            tooltip: 'Toggle Satellite View',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_map),
            onPressed: _centerMap,
            tooltip: 'Center Map',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onTap: _onTapMap,
              onMapEvent: _onMapEvent,
              initialCenter: _pickedLocation,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Base map layer - switch between OSM and Satellite
              TileLayer(
                urlTemplate: _showSatelliteView
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
                tileBuilder: (context, widget, tile) {
                  return ColorFiltered(
                    colorFilter: _showSatelliteView
                        ? const ColorFilter.mode(Colors.white, BlendMode.modulate)
                        : const ColorFilter.mode(Colors.white, BlendMode.modulate),
                    child: widget,
                  );
                },
              ),

              // 3D Buildings layer (when zoomed in)
              if (_show3DBuildings && _zoomLevel > 15)
                TileLayer(
                  urlTemplate: 'https://tiles.3dbuildings.org/3dbuildings/tiles/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),

              // Popular locations markers
              MarkerLayer(
                markers: _popularLocations.map((location) {
                  return Marker(
                    point: latlng.LatLng(location['lat'], location['lng']),
                    width: 40,
                    height: 40,
                    child: Icon(
                      location['icon'],
                      color: location['color'],
                      size: 30,
                    ),
                  );
                }).toList(),
              ),

              // Selected location marker
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

          // Search bar with typeahead
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: _buildSearchBar(),
            ),
          ),

          // Address display
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
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue[900]),
                      const SizedBox(width: 8),
                      Text(
                        "Selected Location",
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingAddress
                      ? Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text("Loading address...")
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_district != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'District: $_district',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      Text(
                        _address,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Row(
                    children: [
                      const Icon(Icons.zoom_in, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Zoom: ${_zoomLevel.toStringAsFixed(1)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        _showSatelliteView ? 'Satellite View' : 'Map View',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'toggle_3d',
            mini: true,
            onPressed: _toggle3DBuildings,
            child: Icon(
              _show3DBuildings ? Icons.landscape : Icons.landscape_outlined,
            ),
            tooltip: 'Toggle 3D Buildings',
          ),
          const SizedBox(height: 8),
          _buildPopularLocationsButton(),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
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
        ],
      ),
    );
  }
}