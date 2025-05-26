import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/profile_controller.dart';
import '../config/api_config.dart';

class HttpService extends GetxService {
  Future<http.Response> get(String endpoint) async {
    final profileController = Get.find<ProfileController>();
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] GET $uri');
    return await http.get(
      uri,
      headers: _getHeaders(profileController),
    );
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    final profileController = Get.find<ProfileController>();
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] POST $uri');
    return await http.post(
      uri,
      headers: _getHeaders(profileController),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    final profileController = Get.find<ProfileController>();
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] PUT $uri');
    return await http.put(
      uri,
      headers: _getHeaders(profileController),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final profileController = Get.find<ProfileController>();
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] DELETE $uri');
    return await http.delete(
      uri,
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
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] $method (multipart) $uri');

    var request = http.MultipartRequest(method, uri);
    request.headers.addAll(_getHeaders(profileController));
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    return await request.send();
  }

  Map<String, String> _getHeaders(ProfileController profileController) {
    return {
      'Content-Type': 'application/json',
      if (profileController.authToken.isNotEmpty)
        'Authorization': 'Bearer ${profileController.authToken}',
    };
  }
}
