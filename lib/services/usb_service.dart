import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../app_res.dart';
import '../models/radar_reading.dart';

class UsbService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _sub;
  final _buffer = StringBuffer();

  final _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  // New radar data streams
  final _radarReadingController = StreamController<RadarReading>.broadcast();
  Stream<RadarReading> get radarReadingStream => _radarReadingController.stream;

  final _objectDetectedController = StreamController<int>.broadcast();
  Stream<int> get objectDetectedStream => _objectDetectedController.stream;

  final _sweepCompleteController = StreamController<int>.broadcast();
  Stream<int> get sweepCompleteStream => _sweepCompleteController.stream;

  List<int> latest = [0, 0, 0];

  // Track current sweep data
  final Map<int, RadarReading> _currentSweepData = {};

  // ── Device discovery ──────────────────────────────────────

  Future<List<UsbDevice>> listDevices() => UsbSerial.listDevices();

  bool isKnownVendor(int? vid) =>
      vid != null &&
      [
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

    // Message Type 1: Startup Header - "SMART RADAR SYSTEM — ONLINE"
    if (line.contains('SMART RADAR SYSTEM')) {
      print('Arduino connected and initialized!');
      return;
    }

    // Skip separator lines and config info
    if (line.contains('----') ||
        line.contains('====') ||
        line.contains('Detection threshold') ||
        line.contains('Close-alert range') ||
        line.contains('Angle step')) {
      return;
    }

    // Message Type 2: Per-Angle Status - "Angle: 45  | Distance: 32.5 cm  | Status: WARNING"
    if (line.startsWith('Angle:')) {
      _parseAngleLine(line);
      return;
    }

    // Message Type 3: Object Detection Event - "*** OBJECT #1 DETECTED! ***"
    if (line.contains('*** OBJECT #') && line.contains('DETECTED! ***')) {
      _parseObjectDetection(line);
      return;
    }

    // Message Type 4: End-of-Sweep Summary - ">>> Total Objects Detected: 2"
    if (line.startsWith('>>> Total Objects Detected:')) {
      _parseSweepSummary(line);
      return;
    }

    // Legacy format: comma-separated distances (backward compatibility)
    final parts = line.split(AppRes.usbParseDelim);
    if (parts.length == 3) {
      final parsed = parts.map((p) => int.tryParse(p.trim()) ?? 0).toList();
      latest = parsed;
      _dataController.add(parsed);
    }
  }

  void _parseAngleLine(String line) {
    // Format: "Angle: 45  | Distance: 32.5 cm  | Status: WARNING"
    try {
      final parts = line.split('|');
      if (parts.length != 3) return;

      // Extract angle
      final anglePart = parts[0].trim(); // "Angle: 45"
      final angle =
          int.tryParse(anglePart.replaceAll('Angle:', '').trim()) ?? 0;

      // Extract distance
      final distPart = parts[1].trim(); // "Distance: 32.5 cm"
      final distStr = distPart
          .replaceAll('Distance:', '')
          .replaceAll('cm', '')
          .trim();
      double? distance = distStr == '---' ? null : double.tryParse(distStr);

      // Extract status
      final statusPart = parts[2].trim(); // "Status: WARNING"
      final statusStr = statusPart
          .replaceAll('Status:', '')
          .trim()
          .toUpperCase();

      RadarStatus status;
      if (statusStr == 'WARNING') {
        status = RadarStatus.warning;
      } else if (statusStr == 'INVALID') {
        status = RadarStatus.invalid;
      } else {
        status = RadarStatus.safe;
      }

      final reading = RadarReading(
        angle: angle,
        distance: distance,
        status: status,
      );

      // Store in current sweep data
      _currentSweepData[angle] = reading;

      // Emit radar reading
      _radarReadingController.add(reading);

      // Also emit legacy format for backward compatibility
      // Map angles to left/center/right (simplified)
      if (angle <= 60) {
        latest[0] = (distance ?? 0).toInt();
      } else if (angle <= 120) {
        latest[1] = (distance ?? 0).toInt();
      } else {
        latest[2] = (distance ?? 0).toInt();
      }
      _dataController.add(latest);
    } catch (e) {
      print('Error parsing angle line: $e');
    }
  }

  void _parseObjectDetection(String line) {
    // Format: "*** OBJECT #1 DETECTED! ***"
    try {
      final regex = RegExp(r'OBJECT #(\d+)');
      final match = regex.firstMatch(line);
      if (match != null) {
        final objectNum = int.parse(match.group(1)!);
        _objectDetectedController.add(objectNum);
      }
    } catch (e) {
      print('Error parsing object detection: $e');
    }
  }

  void _parseSweepSummary(String line) {
    // Format: ">>> Total Objects Detected: 2"
    try {
      final regex = RegExp(r'Total Objects Detected: (\d+)');
      final match = regex.firstMatch(line);
      if (match != null) {
        final totalObjects = int.parse(match.group(1)!);
        _sweepCompleteController.add(totalObjects);

        // Clear sweep data for next sweep
        _currentSweepData.clear();
      }
    } catch (e) {
      print('Error parsing sweep summary: $e');
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
    _dataController.close();
    _radarReadingController.close();
    _objectDetectedController.close();
    _sweepCompleteController.close();
  }
}
