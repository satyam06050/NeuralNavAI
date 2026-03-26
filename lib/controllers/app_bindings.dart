import 'package:get/get.dart';
import '../services/usb_service.dart';
import 'nav_controller.dart';
import 'settings_controller.dart';
import 'usb_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(UsbService());
    Get.put(NavController());
    Get.put(SettingsController());
    Get.put(UsbController());
  }
}
