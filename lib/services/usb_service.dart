import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../app_res.dart';

class UsbService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _sub;
  final _buffer = StringBuffer();

  final _controller = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _controller.stream;

  List<int> latest = [0, 0, 0];

  // ── Device discovery ──────────────────────────────────────

  Future<List<UsbDevice>> listDevices() => UsbSerial.listDevices();

  bool isKnownVendor(int? vid) => vid != null && [
        AppRes.vendorCH340,
        AppRes.vendorCP2102,
        AppRes.vendorArduino,
        AppRes.vendorFTDI,
      ].contains(vid);

  // ── Connect ───────────────────────────────────────────────

  Future<bool> connect(UsbDevice device) async {
    try {
      _port = await device.create();
      if (_port == null) return false;

      final opened = await _port!.open();
      if (!opened) return false;

      await _port!.setPortParameters(
        AppRes.usbBaudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _listen();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Stream listener ───────────────────────────────────────

  void _listen() {
    _sub = _port!.inputStream!.listen((Uint8List data) {
      _buffer.write(String.fromCharCodes(data));
      final raw = _buffer.toString();
      final lines = raw.split('\n');
      _buffer.clear();
      _buffer.write(lines.last); // keep incomplete chunk
      for (int i = 0; i < lines.length - 1; i++) {
        _parseLine(lines[i].trim());
      }
    });
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;
    final parts = line.split(AppRes.usbParseDelim);
    if (parts.length == 3) {
      final parsed = parts.map((p) => int.tryParse(p.trim()) ?? 0).toList();
      latest = parsed;
      _controller.add(parsed);
    }
  }

  // ── Disconnect ────────────────────────────────────────────

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _port?.close();
    _port = null;
    _buffer.clear();
  }

  bool get isConnected => _port != null;

  void dispose() {
    disconnect();
    _controller.close();
  }
}
