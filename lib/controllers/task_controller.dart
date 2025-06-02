import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'profile_controller.dart';

class TaskController extends GetxController {
  var tasks = <Map<String, dynamic>>[].obs;

  /// 🟢 Fetch delivery person's assigned tasks
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
        final List<Map<String, dynamic>> fetchedTasks =
        List<Map<String, dynamic>>.from(res['data']);

        // Optional: Preventing frontend-side duplicates
        final uniqueTasks = <Map<String, dynamic>>[];
        final seenOrderIds = <String>{};

        for (var task in fetchedTasks) {
          final orderId = task['orderId']?.toString() ?? '';
          final deliveryPersonId = task['deliveryPersonId']?.toString() ?? '';

          if (!seenOrderIds.contains(orderId + deliveryPersonId)) {
            seenOrderIds.add(orderId + deliveryPersonId);
            uniqueTasks.add(task);
          }
        }

        tasks.value = uniqueTasks;
      } else {
        print("❌ Task fetch failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching tasks: $e");
    }
  }

  /// 🔄 Update the status of a task
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
        await fetchMyTasks(); // Refresh the tasks list
      } else {
        print("❌ Failed to update task: ${response.body}");
      }
    } catch (e) {
      print("❌ Error updating task: $e");
    }
  }
}
