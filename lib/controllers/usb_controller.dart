import 'dart:async';
import 'package:get/get.dart';
import 'package:usb_serial/usb_serial.dart' as usb;
import '../app_res.dart';
import '../services/usb_service.dart';
import 'nav_controller.dart';
import '../models/radar_reading.dart';

class UsbController extends GetxController {
  final _service = Get.find<UsbService>();

  final isScanning = false.obs;
  final connectedIndex = (-1).obs;
  final statusText = AppRes.labelUsbNoDevices.obs;
  final devices = <usb.UsbDevice>[].obs;

  StreamSubscription<List<int>>? _dataSub;
  StreamSubscription<dynamic>? _eventSub;

  // ── Chip label helper ─────────────────────────────────────

  String chipLabel(int? vid) {
    switch (vid) {
      case AppRes.vendorCH340:
        return 'CH340';
      case AppRes.vendorCP2102:
        return 'CP2102';
      case AppRes.vendorArduino:
        return 'Arduino';
      case AppRes.vendorFTDI:
        return 'FTDI';
      default:
        return 'Unknown';
    }
  }

  // ── Scan ──────────────────────────────────────────────────

  Future<void> scan() async {
    isScanning.value = true;
    statusText.value = AppRes.labelUsbSearching;
    connectedIndex.value = -1;

    final found = await _service.listDevices();
    devices.value = found;
    isScanning.value = false;

    if (found.isEmpty) {
      statusText.value = AppRes.labelUsbNoDevices;
    } else {
      statusText.value = found.length == 1
          ? AppRes.labelUsbFoundOne
          : 'Found ${found.length} devices';
    }
  }

  // ── Connect ───────────────────────────────────────────────

  Future<void> connect(int index) async {
    final device = devices[index];
    statusText.value = AppRes.labelUsbSearching;

    final ok = await _service.connect(device);
    if (!ok) {
      statusText.value = AppRes.labelUsbConnFailed;
      return;
    }

    connectedIndex.value = index;
    statusText.value = AppRes.labelConnected;
    Get.find<NavController>().isConnected.value = true;

    _listenData();
    _listenEvents();
  }

  // ── Data stream → NavController ───────────────────────────

  void _listenData() {
    _dataSub?.cancel();
    _dataSub = _service.dataStream.listen((distances) {
      Get.find<NavController>().updateDistances(distances);
    });

    // Listen to radar readings
    _radarSub?.cancel();
    _radarSub = _service.radarReadingStream.listen((reading) {
      Get.find<NavController>().onRadarReading(reading);
    });

    // Listen to object detections
    _objectSub?.cancel();
    _objectSub = _service.objectDetectedStream.listen((objectNum) {
      Get.find<NavController>().onObjectDetected(objectNum);
    });

    // Listen to sweep completions
    _sweepSub?.cancel();
    _sweepSub = _service.sweepCompleteStream.listen((total) {
      Get.find<NavController>().onSweepComplete(total);
    });
  }

  StreamSubscription<RadarReading>? _radarSub;
  StreamSubscription<int>? _objectSub;
  StreamSubscription<int>? _sweepSub;

  // ── USB attach/detach events ──────────────────────────────

  void _listenEvents() {
    _eventSub?.cancel();
    _eventSub = usb.UsbSerial.usbEventStream?.listen((event) {
      if (event.event == usb.UsbEvent.ACTION_USB_DETACHED) {
        _onDisconnected();
      }
    });
  }

  void _onDisconnected() {
    _dataSub?.cancel();
    connectedIndex.value = -1;
    statusText.value = AppRes.labelDisconnected;
    Get.find<NavController>().isConnected.value = false;
    _service.disconnect();
  }

  // ── Manual disconnect ─────────────────────────────────────

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    await _eventSub?.cancel();
    await _service.disconnect();
    connectedIndex.value = -1;
    statusText.value = AppRes.labelDisconnected;
    Get.find<NavController>().isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
