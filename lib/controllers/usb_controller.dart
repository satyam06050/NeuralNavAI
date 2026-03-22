import 'package:get/get.dart';
import '../app_res.dart';
import 'nav_controller.dart';

class MockUsbDevice {
  final String name;
  final int vid;
  MockUsbDevice(this.name, this.vid);
}

class UsbController extends GetxController {
  final isScanning       = false.obs;
  final permissionDenied = false.obs;
  final connectedIndex   = (-1).obs;
  final statusText       = AppRes.labelUsbNoDevices.obs;

  final devices = <MockUsbDevice>[
    MockUsbDevice('Arduino Uno',   AppRes.vendorArduino),
    MockUsbDevice('CH340 Module',  AppRes.vendorCH340),
    MockUsbDevice('CP2102 Dongle', AppRes.vendorCP2102),
  ].obs;

  String chipLabel(int vid) {
    switch (vid) {
      case AppRes.vendorCH340:   return 'CH340';
      case AppRes.vendorCP2102:  return 'CP2102';
      case AppRes.vendorArduino: return 'Arduino';
      case AppRes.vendorFTDI:    return 'FTDI';
      default:                   return 'Unknown';
    }
  }

  Future<void> scan() async {
    isScanning.value = true;
    statusText.value = AppRes.labelUsbSearching;
    await Future.delayed(const Duration(seconds: 2));
    isScanning.value = false;
    statusText.value = 'Found ${devices.length} devices';
  }

  void connect(int index) {
    connectedIndex.value = index;
    statusText.value     = AppRes.labelConnected;
    Get.find<NavController>().isConnected.value = true;
  }
}
