import 'package:get/get.dart';
import '../services/bluetooth_service.dart';
import '../services/usb_service.dart';
import 'bluetooth_controller.dart';
import 'connection_mode_controller.dart';
import 'nav_controller.dart';
import 'settings_controller.dart';
import 'usb_controller.dart';
import 'camera_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(UsbService());
    Get.put(BtService());
    Get.put(NavController());
    Get.put(SettingsController());
    Get.put(UsbController());
    Get.put(BluetoothController());
    Get.put(ConnectionModeController());
    Get.put(CameraController());
  }
}
