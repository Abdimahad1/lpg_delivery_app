import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/profile_controller.dart';
import '../config/api_config.dart';

class HttpService extends GetxService {
  Future<http.Response> get(String endpoint) async {
    final profileController = Get.find<ProfileController>();
    return await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _getHeaders(profileController),
    );
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    final profileController = Get.find<ProfileController>();
    return await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _getHeaders(profileController),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    final profileController = Get.find<ProfileController>();
    return await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _getHeaders(profileController),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final profileController = Get.find<ProfileController>();
    return await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _getHeaders(profileController),
    );
  }

  Future<http.StreamedResponse> multipartRequest(
      String endpoint, {
        required String method,
        required Map<String, String> fields,
        required String fileField,
        required String filePath,
      }) async {
    final profileController = Get.find<ProfileController>();
    var request = http.MultipartRequest(
      method,
      Uri.parse('$baseUrl/$endpoint'),
    );
    request.headers.addAll(_getHeaders(profileController));
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return await request.send();
  }

  Map<String, String> _getHeaders(ProfileController profileController) {
    return {
      if (profileController.authToken.isNotEmpty)
        'Authorization': 'Bearer ${profileController.authToken}',
      'Content-Type': 'application/json',
    };
  }
}