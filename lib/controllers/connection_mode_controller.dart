import 'package:get/get.dart';
import '../app_res.dart';
import 'bluetooth_controller.dart';
import 'usb_controller.dart';

class ConnectionModeController extends GetxController {
  final mode = AppRes.modeUsb.obs;

  bool get isUsb       => mode.value == AppRes.modeUsb;
  bool get isBluetooth => mode.value == AppRes.modeBluetooth;

  void switchToUsb() {
    if (isUsb) return;
    _disconnectBluetooth();
    mode.value = AppRes.modeUsb;
    Get.snackbar(
      AppRes.labelModeToggle,
      AppRes.modeUsb,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppRes.bgSurface,
      colorText: AppRes.accentSafe,
    );
  }

  void switchToBluetooth() {
    if (isBluetooth) return;
    _disconnectUsb();
    mode.value = AppRes.modeBluetooth;
    Get.snackbar(
      AppRes.labelModeToggle,
      AppRes.modeBluetooth,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: AppRes.bgSurface,
      colorText: AppRes.accentSafe,
    );
  }

  void _disconnectUsb() {
    try {
      Get.find<UsbController>().disconnect();
    } catch (_) {}
  }

  void _disconnectBluetooth() {
    try {
      Get.find<BluetoothController>().disconnect();
    } catch (_) {}
  }
}
