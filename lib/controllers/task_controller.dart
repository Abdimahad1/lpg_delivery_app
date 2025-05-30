import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'profile_controller.dart';

class TaskController extends GetxController {
  var tasks = <Map<String, dynamic>>[].obs;

  Future<void> fetchMyTasks() async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.get(
        Uri.parse('${baseUrl}tasks/my-tasks'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("🔁 API RESPONSE STATUS: ${response.statusCode}");
      print("📦 API RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        tasks.value = List<Map<String, dynamic>>.from(res['data']);
      } else {
        print("❌ Task fetch failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching tasks: $e");
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final profileController = Get.find<ProfileController>();
      final token = profileController.authToken;

      final response = await http.patch(
        Uri.parse('${baseUrl}tasks/update/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        print("✅ Task updated: $newStatus");
        fetchMyTasks();
      } else {
        print("❌ Failed to update task: ${response.body}");
      }
    } catch (e) {
      print("❌ Error updating task: $e");
    }
  }
}
