import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../controllers/signup_controller.dart';

class SyncController extends GetxController {
  final isSyncing = false.obs;
  final lastSyncTime = Rx<DateTime?>(null);

  Future<void> syncAllData() async {
    isSyncing.value = true;
    try {
      await Get.find<SignupController>().syncPendingSignups();
      await Get.find<LoginController>().syncPendingLogins();
      lastSyncTime.value = DateTime.now();
      Get.snackbar("Success", "Data synchronized", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Sync failed: ${e.toString()}");
    } finally {
      isSyncing.value = false;
    }
  }
}