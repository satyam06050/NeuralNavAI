import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../app_res.dart';

class BtService {
  fbp.BluetoothDevice? _device;
  fbp.BluetoothCharacteristic? _rxChar;
  StreamSubscription<List<int>>? _sub;
  StreamSubscription<fbp.BluetoothConnectionState>? _stateSub;
  final _buffer = StringBuffer();

  final _controller = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _controller.stream;

  List<int> latest = [0, 0, 0];
  fbp.BluetoothDevice? _lastDevice;

  // ── Scan ──────────────────────────────────────────────────

  Future<List<fbp.ScanResult>> scanDevices() async {
    final results = <String, fbp.ScanResult>{};

    // Stop any previous scan first
    await fbp.FlutterBluePlus.stopScan();

    final sub = fbp.FlutterBluePlus.onScanResults.listen((list) {
      for (final r in list) {
        results[r.device.remoteId.str] = r;
      }
    });

    await fbp.FlutterBluePlus.startScan(timeout: AppRes.btScanTimeout);
    // Wait for scan to complete (timeout fires automatically)
    await fbp.FlutterBluePlus.isScanning
        .where((scanning) => scanning == false)
        .first;
    await sub.cancel();

    return results.values.toList();
  }

  // ── Connect ───────────────────────────────────────────────

  Future<bool> connect(fbp.BluetoothDevice device) async {
    try {
      _device     = device;
      _lastDevice = device;

      await device.connect(autoConnect: false);

      final services = await device.discoverServices();

      // Try SPP UUID first
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify &&
              (c.uuid.toString().toLowerCase() == AppRes.btSppUuid ||
                  c.serviceUuid.toString().toLowerCase() ==
                      AppRes.btSppUuid)) {
            _rxChar = c;
            break;
          }
        }
        if (_rxChar != null) break;
      }

      // Fallback: first notifiable characteristic
      if (_rxChar == null) {
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.notify) {
              _rxChar = c;
              break;
            }
          }
          if (_rxChar != null) break;
        }
      }

      if (_rxChar == null) return false;

      await _rxChar!.setNotifyValue(true);
      _listenChar();
      _listenState(device);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connectWithRetry(fbp.BluetoothDevice device) =>
      connect(device);

  // ── Characteristic listener ───────────────────────────────

  void _listenChar() {
    _sub = _rxChar!.lastValueStream.listen((data) {
      if (data.isEmpty) return;
      _buffer.write(String.fromCharCodes(data));
      final raw   = _buffer.toString();
      final lines = raw.split('\n');
      _buffer.clear();
      _buffer.write(lines.last);
      for (int i = 0; i < lines.length - 1; i++) {
        _parseLine(lines[i].trim());
      }
    });
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;
    final parts = line.split(AppRes.btParseDelim);
    if (parts.length == 3) {
      final parsed = parts.map((p) => int.tryParse(p.trim()) ?? 0).toList();
      latest = parsed;
      _controller.add(parsed);
    }
  }

  // ── Auto-reconnect ────────────────────────────────────────

  void _listenState(fbp.BluetoothDevice device) {
    _stateSub = device.connectionState.listen((state) async {
      if (state == fbp.BluetoothConnectionState.disconnected &&
          _lastDevice != null) {
        await Future.delayed(AppRes.btReconnectDelay);
        await connect(device);
      }
    });
  }

  // ── Disconnect ────────────────────────────────────────────

  Future<void> disconnect() async {
    _lastDevice = null;
    await _sub?.cancel();
    await _stateSub?.cancel();
    _sub      = null;
    _stateSub = null;
    _rxChar   = null;
    await _device?.disconnect();
    _device = null;
    _buffer.clear();
  }

  bool get isConnected => _device?.isConnected ?? false;

  void dispose() {
    disconnect();
    _controller.close();
  }
}
