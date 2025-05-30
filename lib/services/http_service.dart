import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/profile_controller.dart';
import '../config/api_config.dart';

class HttpService extends GetxService {
  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] GET $uri');
    return await http.get(uri, headers: _getHeaders());
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] POST $uri');
    return await http
        .post(
      uri,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    )
        .timeout(apiTimeout);
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] PUT $uri');
    return await http.put(
      uri,
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] DELETE $uri');
    return await http.delete(uri, headers: _getHeaders());
  }

  Future<http.StreamedResponse> multipartRequest(
      String endpoint, {
        required String method,
        required Map<String, String> fields,
        required String fileField,
        required String filePath,
      }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    print('[HTTP] $method (multipart) $uri');

    var request = http.MultipartRequest(method, uri);
    request.headers.addAll(_getHeaders());
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    return await request.send();
  }

  Map<String, String> _getHeaders() {
    final profileController = Get.find<ProfileController>();
    final token = profileController.authToken; // ✅ already a string, no .value needed

    final headers = {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    print('[HTTP] Headers: $headers');
    return headers;
  }

}
