import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;
import '../config/api_config.dart';
import '../controllers/profile_controller.dart';
import 'VendorLocationScreen.dart';

class SearchVendorsScreen extends StatefulWidget {
  const SearchVendorsScreen({super.key});

  @override
  State<SearchVendorsScreen> createState() => _SearchVendorsScreenState();
}

class _SearchVendorsScreenState extends State<SearchVendorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProfileController profileController = Get.find();
  List<Map<String, dynamic>> filteredVendors = [];

  @override
  void initState() {
    super.initState();
    fetchAllVendors();
    _searchController.addListener(_filterVendors);
  }

  Future<void> fetchAllVendors() async {
    try {
      final res = await http.get(
        Uri.parse('${baseUrl}profile/all-vendors'),
        headers: {'Authorization': 'Bearer ${profileController.authToken}'},
      );
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        profileController.nearbyVendors.value =
        List<Map<String, dynamic>>.from(json['data']);
        filteredVendors = profileController.nearbyVendors.toList();
        setState(() {});
      }
    } catch (e) {
      print('Error fetching vendors: $e');
    }
  }

  void _filterVendors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredVendors = profileController.nearbyVendors
          .where((vendor) =>
      vendor['shopName']?.toLowerCase().contains(query) == true ||
          vendor['name']?.toLowerCase().contains(query) == true)
          .toList();
    });
  }

  Future<void> _navigateToVendorLocation(Map<String, dynamic> vendor) async {
    final name = vendor['shopName'] ?? vendor['name'] ?? 'Vendor';
    final address = vendor['address'] ?? '';

    final lat = vendor['coordinates']?['lat']?.toDouble();
    final lng = vendor['coordinates']?['lng']?.toDouble();

    if (lat != null && lng != null) {
      Get.to(() => VendorLocationScreen(
        vendorLocation: latlng.LatLng(lat, lng),
        vendorName: name,
      ));
      return;
    }

    if (address.isEmpty) {
      Get.snackbar("No location", "Vendor address is missing");
      return;
    }

    try {
      final url = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address,
        'format': 'json',
        'limit': '1',
      });

      final response = await http.get(url, headers: {
        'User-Agent': 'lpg-delivery-app'
      });

      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        final lat = double.tryParse(data[0]['lat']);
        final lon = double.tryParse(data[0]['lon']);
        if (lat != null && lon != null) {
          Get.to(() => VendorLocationScreen(
            vendorLocation: latlng.LatLng(lat, lon),
            vendorName: name,
          ));
        } else {
          Get.snackbar("Location Error", "Invalid coordinates from address");
        }
      } else {
        Get.snackbar("Not Found", "Could not locate vendor address");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to get location from address");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      appBar: AppBar(
        title: const Text("Search Vendors"),
        backgroundColor: const Color(0xFF3E3EFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                icon: Icon(Icons.search),
                hintText: 'Search vendors by name...',
                border: InputBorder.none,
              ),
            ),
          ),
          Expanded(
            child: filteredVendors.isEmpty
                ? const Center(child: Text("No vendors found"))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredVendors.length,
              itemBuilder: (context, index) {
                final vendor = filteredVendors[index];
                return GestureDetector(
                  onTap: () => _navigateToVendorLocation(vendor),
                  child: VendorCard(
                    name: vendor['shopName'] ?? vendor['name'] ?? 'Vendor',
                    location: vendor['address'] ?? 'No location',
                    imageUrl: vendor['profileImage'] ?? '',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VendorCard extends StatelessWidget {
  final String name;
  final String location;
  final String imageUrl;
  final double? price; // optional price (e.g. starting price)

  const VendorCard({
    super.key,
    required this.name,
    required this.location,
    required this.imageUrl,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: imageUrl.startsWith("http")
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/images/vendor.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Price: \$${price! < 0.01 ? price!.toStringAsFixed(3) : price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


