import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import '../app_res.dart';
import '../models/radar_reading.dart';

class UsbService {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;
  final _buffer = StringBuffer();

  final _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  // Radar data streams
  final _radarReadingController = StreamController<RadarReading>.broadcast();
  Stream<RadarReading> get radarReadingStream => _radarReadingController.stream;

  final _objectDetectedController = StreamController<int>.broadcast();
  Stream<int> get objectDetectedStream => _objectDetectedController.stream;

  final _sweepCompleteController = StreamController<int>.broadcast();
  Stream<int> get sweepCompleteStream => _sweepCompleteController.stream;

  List<int> latest = [0, 0, 0];
  final Map<int, RadarReading> _currentSweepData = {};

  bool get isConnected => _port != null;

  // Device discovery
  Future<List<UsbDevice>> listDevices() => UsbSerial.listDevices();

  bool isKnownVendor(int? vid) =>
      vid != null &&
      [
        AppRes.vendorCH340,
        AppRes.vendorCP2102,
        AppRes.vendorArduino,
        AppRes.vendorFTDI,
      ].contains(vid);

  // Call this from your UI or on app start (auto-connect to first device)
  Future<bool> connect() async {
    try {
      print('[UsbService] Starting USB connection...');

      List<UsbDevice> devices = await UsbSerial.listDevices();
      print('[UsbService] Found ${devices.length} device(s)');

      if (devices.isEmpty) {
        print('[UsbService] No USB devices found.');
        return false;
      }

      // Pick the first device (Arduino/FTDI)
      UsbDevice device = devices.first;
      final vendorId = device.vid ?? 0;
      final productId = device.pid ?? 0;

      String chipName = 'Unknown';
      if (vendorId == 1027)
        chipName = 'FTDI FT232R';
      else if (vendorId == 6790)
        chipName = 'CH340';
      else if (vendorId == 9025)
        chipName = 'Arduino';

      print(
        '[UsbService] Found device: ${device.productName} | VID: 0x${vendorId.toRadixString(16).toUpperCase()} PID: 0x${productId.toRadixString(16).toUpperCase()} ($chipName)',
      );

      // Create and open the port
      print('[UsbService] Creating port...');
      _port = await device.create();
      if (_port == null) {
        print('[UsbService] Failed to create port.');
        return false;
      }

      print('[UsbService] Opening port...');
      bool opened = await _port!.open();
      print('[UsbService] Port open result: $opened');

      if (!opened) {
        print(
          '[UsbService] Failed to open port - trying FTDI alternative method...',
        );
        // FTDI chips sometimes need a second attempt
        await Future.delayed(Duration(milliseconds: 150));
        opened = await _port!.open();
        print('[UsbService] Second attempt result: $opened');

        if (!opened) {
          print('[UsbService] ❌ Failed to open port after 2 attempts.');
          _port = null;
          return false;
        }
      }

      // CRITICAL: Must match Arduino's Serial.begin(9600)
      print('[UsbService] Setting DTR/RTS...');
      await _port!.setDTR(true);
      await _port!.setRTS(true);

      print('[UsbService] Setting port parameters to 9600 baud...');
      await _port!.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // Listen to the input stream
      print('[UsbService] Starting stream listener...');
      _listen();

      print('[UsbService] ✅ Connected and listening.');
      return true;
    } catch (e, stackTrace) {
      print('[UsbService] ❌ Connection error: $e');
      print('[UsbService] Stack trace: $stackTrace');
      return false;
    }
  }

  // Connect to specific device (for UsbController compatibility - deprecated, use connect())
  @Deprecated('Use connect() instead')
  Future<bool> connectToDevice(UsbDevice device) async {
    return await connect();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _port?.close();
    _port = null;
    print('[UsbService] Disconnected.');
  }

  void dispose() {
    disconnect();
    _dataController.close();
  }

  // Stream listener with buffering for proper line splitting
  void _listen() {
    _subscription = _port!.inputStream!.listen((Uint8List data) {
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

    // ✅ ALWAYS forward every raw line to TestScreen
    _dataController.add(line.codeUnits);

    // Message Type 1: Startup Header - "SMART RADAR SYSTEM — ONLINE"
    if (line.contains('SMART RADAR SYSTEM')) {
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

    // Message Type 3: Object Detection Event
    if (line.contains('OBJECT #') && line.contains('DETECTED')) {
      _parseObjectDetection(line);
      return;
    }

    // Message Type 4: End-of-Sweep Summary
    if (line.startsWith('>>> Total Objects Detected:')) {
      _parseSweepSummary(line);
      return;
    }

    // Message Type 5: APP: structured lines (Arduino v2.0 protocol)
    if (line.startsWith('APP:')) {
      _parseAppLine(line);
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
    try {
      final parts = line.split('|');
      if (parts.length < 3) return;

      // Fix 1: Strip degree symbol
      final angle =
          int.tryParse(
            parts[0].replaceAll('Angle:', '').replaceAll('°', '').trim(),
          ) ??
          0;

      // Fix 2: Handle both "Distance:" and "Dist:", and ">500cm"
      final distPart = parts[1]
          .replaceAll('Distance:', '')
          .replaceAll('Dist:', '')
          .replaceAll('cm', '')
          .replaceAll('>', '')
          .trim();
      double? distance = (distPart == '---' || distPart.isEmpty)
          ? null
          : double.tryParse(distPart);

      // Fix 3: Use contains() for fuzzy status matching
      final statusStr = parts[2].toUpperCase();
      RadarStatus status;
      if (statusStr.contains('DANGER')) {
        status = RadarStatus.warning;
      } else if (statusStr.contains('WARNING')) {
        status = RadarStatus.warning;
      } else if (statusStr.contains('NOTICE')) {
        status = RadarStatus.safe;
      } else if (statusStr.contains('INVALID') || distance == null) {
        status = RadarStatus.invalid;
      } else {
        status = RadarStatus.safe;
      }

      final reading = RadarReading(
        angle: angle,
        distance: distance,
        status: status,
      );
      _currentSweepData[angle] = reading;
      _radarReadingController.add(reading);

      if (angle <= 60) {
        latest[0] = (distance ?? 0).toInt();
      } else if (angle <= 120) {
        latest[1] = (distance ?? 0).toInt();
      } else {
        latest[2] = (distance ?? 0).toInt();
      }
      _dataController.add(latest);
    } catch (e) {
      print('[UsbService] _parseAngleLine error: $e | line: $line');
    }
  }

  void _parseObjectDetection(String line) {
    try {
      final regex = RegExp(r'OBJECT #(\d+)');
      final match = regex.firstMatch(line);
      if (match != null) {
        final objectNum = int.parse(match.group(1)!);
        _objectDetectedController.add(objectNum);
      }
    } catch (e) {
      // Error parsing object detection handled silently
    }
  }

  void _parseSweepSummary(String line) {
    try {
      final regex = RegExp(r'Total Objects Detected: (\d+)');
      final match = regex.firstMatch(line);
      if (match != null) {
        final totalObjects = int.parse(match.group(1)!);
        _sweepCompleteController.add(totalObjects);
        _currentSweepData.clear();
      }
    } catch (e) {
      // Error parsing sweep summary handled silently
    }
  }

  void _parseAppLine(String line) {
    // Format: APP:READY, APP:SWEEP_START, APP:DATA,angle,distance,zone
    if (line == 'APP:READY' || line == 'APP:SWEEP_START') {
      if (line == 'APP:SWEEP_START') _currentSweepData.clear();
      return;
    }

    // Format: APP:DATA,angle,distance_cm,zone
    if (line.startsWith('APP:DATA,')) {
      final parts = line.replaceFirst('APP:DATA,', '').split(',');
      if (parts.length == 3) {
        final angle = int.tryParse(parts[0]) ?? 0;
        final rawDist = double.tryParse(parts[1]);
        final zone = int.tryParse(parts[2]) ?? 0;
        final distance = (rawDist == null || rawDist >= 999) ? null : rawDist;
        RadarStatus status = zone >= 3
            ? RadarStatus.warning
            : zone == 0
            ? RadarStatus.safe
            : RadarStatus.safe;
        _radarReadingController.add(
          RadarReading(angle: angle, distance: distance, status: status),
        );
      }
      return;
    }

    // Format: APP:CYCLE_END,objects=N
    if (line.startsWith('APP:CYCLE_END')) {
      final match = RegExp(r'objects=(\d+)').firstMatch(line);
      if (match != null) {
        _sweepCompleteController.add(int.parse(match.group(1)!));
        _currentSweepData.clear();
      }
      return;
    }

    // APP:ALERT, APP:OBJ, APP:SUDDEN_ALERT — log for now
    print('[UsbService] APP event: $line');
  }
}
