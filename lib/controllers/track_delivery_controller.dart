import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class TrackDeliveryController extends GetxController {
  var deliveryStatus = "Out For Delivery".obs;
  var estTime = "20 min".obs;

  // Sample customer location (Mogadishu)
  var deliveryLocation = const LatLng(2.0469, 45.3182).obs;

  void markAsDelivered() {
    deliveryStatus.value = "Delivered";
    estTime.value = "Completed";
  }
}
