import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../controllers/signup_controller.dart';

class SyncController extends GetxController {
  final isSyncing = false.obs;
  final lastSyncTime = Rx<DateTime?>(null);

  Future<void> syncAllData() async {
    isSyncing.value = true;
    try {
      print("🔄 Syncing pending signups...");
      await Get.find<SignupController>().syncPendingSignups();

      print("🔄 Syncing pending logins...");
      await Get.find<LoginController>().syncPendingLogins();

      lastSyncTime.value = DateTime.now();
      Get.snackbar("✅ Sync Success", "Data synchronized successfully", snackPosition: SnackPosition.BOTTOM);
    } catch (e, stack) {
      print("❌ Sync error: $e");
      print("🪵 Stack Trace:\n$stack");
      Get.snackbar("❌ Sync Error", "Failed to sync data: $e");
    } finally {
      isSyncing.value = false;
    }
  }
}
