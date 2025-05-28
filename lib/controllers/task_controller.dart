import 'package:get/get.dart';

class TaskController extends GetxController {
  var tasks = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMockTasks();
  }

  void fetchMockTasks() {
    tasks.value = [
      {
        'product': '6kg Cylinder',
        'customer': 'Abdi Hussein',
        'address': 'Hodan-Taleex-Mog-Som',
        'status': 'Pending'
      },
      {
        'product': '6kg Cylinder',
        'customer': 'Ahmed Ali',
        'address': 'Km4-Waberi-Mog-Som',
        'status': 'Pending'
      },
      {
        'product': '6kg Cylinder',
        'customer': 'Fatima Noor',
        'address': 'Hodan-Digfer-Mog-Som',
        'status': 'Pending'
      },
    ];
  }

  void acceptTask(int index) {
    tasks[index]['status'] = 'Accepted';
    tasks.refresh();
  }

  void rejectTask(int index) {
    tasks[index]['status'] = 'Rejected';
    tasks.refresh();
  }
}
