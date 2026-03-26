import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:get/get.dart';
import '../app_res.dart';
import '../services/bluetooth_service.dart';
import 'nav_controller.dart';

class BluetoothController extends GetxController {
  final _service = Get.find<BtService>();

  final isConnected = false.obs;
  final isScanning  = false.obs;
  final statusText  = AppRes.labelBtNoDevices.obs;
  final devices     = <fbp.ScanResult>[].obs;
  final connectedId = ''.obs;

  StreamSubscription<List<int>>? _dataSub;

  // ── Scan ──────────────────────────────────────────────────

  Future<void> scan() async {
    isScanning.value = true;
    statusText.value = AppRes.labelBtSearching;
    devices.clear(); // clear stale results before new scan

    final found = await _service.scanDevices();
    final seen  = <String>{};
    devices.value =
        found.where((r) => seen.add(r.device.remoteId.str)).toList();
    isScanning.value = false;

    if (devices.isEmpty) {
      statusText.value = AppRes.labelBtNoDevices;
    } else {
      statusText.value = devices.length == 1
          ? AppRes.labelBtFoundOne
          : AppRes.labelBtFoundMany.replaceFirst('{n}', '${devices.length}');
    }
  }

  // ── Connect ───────────────────────────────────────────────

  Future<void> connect(fbp.BluetoothDevice device) async {
    statusText.value = AppRes.labelBtSearching;

    final ok = await _service.connectWithRetry(device);
    if (!ok) {
      statusText.value = AppRes.labelBtConnFailed;
      return;
    }

    connectedId.value = device.remoteId.str;
    isConnected.value = true;
    statusText.value  = AppRes.labelBtConnected;
    Get.find<NavController>().isConnected.value = true;

    _listenData();
  }

  // ── Data stream → NavController ───────────────────────────

  void _listenData() {
    _dataSub?.cancel();
    _dataSub = _service.dataStream.listen((distances) {
      Get.find<NavController>().updateDistances(distances);
    });
  }

  // ── Disconnect ────────────────────────────────────────────

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    _dataSub = null;
    await _service.disconnect();
    connectedId.value = '';
    isConnected.value = false;
    statusText.value  = AppRes.labelBtDisconnected;
    Get.find<NavController>().isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
