# USB OTG Fix — Targeted Improvements
**Based on actual `usb_service.dart` code review**

---

## Problem 1 🔴 — `_parseLine()` never sends raw data to `TestScreen`

**Root Cause:** Your `_listen()` method calls `_parseLine()` for every line, but `_parseLine()` only adds to `_dataController` in two narrow cases:
1. The legacy 3-part comma-separated format
2. After parsing an `Angle:` line (adds `latest`, not the raw line)

**The TestScreen listens to `dataStream` (`_dataController`), but almost every line from your Arduino v2.0 is silently dropped before reaching it.**

Lines currently DROPPED (never reach TestScreen):
- `--- NEW SWEEP STARTED ---`
- `APP:SWEEP_START`
- `APP:DATA,45,32.5,2`
- `APP:ALERT,id=1,...`
- `SWEEP COMPLETE | Objects detected...`
- `APP:CYCLE_END,...`
- `APP:OBJ,...`
- `>>> OBJECT #1 DETECTED at 45°...`

**Fix — add one line at the top of `_parseLine()`:**

```dart
void _parseLine(String line) {
  if (line.isEmpty) return;

  // ✅ ALWAYS forward every raw line to TestScreen
  _dataController.add(line.codeUnits);

  // ... rest of your existing parsing logic unchanged
}
```

This single line fixes TestScreen immediately — everything else below is about fixing the structured parsers.

---

## Problem 2 🔴 — Wrong permission requested

**Your code:**
```dart
var status = await Permission.storage.request();
```

`Permission.storage` is for file access — it has nothing to do with USB. Android manages USB through a completely separate system dialog, not through `permission_handler`.

**Fix — replace storage permission with USB serial's built-in permission method:**

```dart
Future<bool> connect() async {
  try {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      print('[UsbService] No USB devices found.');
      return false;
    }

    UsbDevice device = devices.first;
    print('[UsbService] Found: ${device.productName} VID:${device.vid} PID:${device.pid}');

    // ✅ This is the correct USB permission — triggers Android's USB dialog
    bool? hasPermission = await UsbSerial.requestPermission(device);
    if (hasPermission != true) {
      print('[UsbService] ❌ USB permission denied.');
      return false;
    }

    _port = await device.create();
    if (_port == null) return false;

    bool opened = await _port!.open();
    if (!opened) {
      await Future.delayed(const Duration(milliseconds: 150));
      opened = await _port!.open(); // second attempt for FTDI
    }
    if (!opened) {
      _port = null;
      return false;
    }

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
      9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE,
    );

    _listen();
    print('[UsbService] ✅ Connected at 9600 baud.');
    return true;
  } catch (e, st) {
    print('[UsbService] ❌ connect() error: $e\n$st');
    return false;
  }
}
```

Also remove the `permission_handler` import and `pubspec.yaml` entry if it's only used for this.

---

## Problem 3 🔴 — `_parseAngleLine()` breaks on Arduino v2.0 format

**Your parser expects:**
```
Angle: 45  |  Distance: 32.5 cm  |  Status: WARNING
```

**Arduino v2.0 actually sends:**
```
Angle: 45°  | Dist: 32.5 cm | Status: !!DANGER!! OBJECT VERY CLOSE
Angle: 90°  | Dist: >500cm  | Status: SAFE / CLEAR
```

Three things silently break:
- `Distance:` → `Dist:` (your `.replaceAll('Distance:', '')` does nothing)
- `45°` → `int.tryParse()` returns `null` because of the `°` character → angle is always 0
- Status strings like `!!DANGER!! OBJECT VERY CLOSE` and `⚠ WARNING — Object nearby` don't match your exact-string checks

**Fix:**

```dart
void _parseAngleLine(String line) {
  try {
    final parts = line.split('|');
    if (parts.length < 3) return;

    // Fix 1: Strip degree symbol
    final angle = int.tryParse(
      parts[0].replaceAll('Angle:', '').replaceAll('°', '').trim()
    ) ?? 0;

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

    final reading = RadarReading(angle: angle, distance: distance, status: status);
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
```

---

## Problem 4 🟠 — Object detection parser never matches

**Your trigger condition:**
```dart
if (line.contains('*** OBJECT #') && line.contains('DETECTED! ***'))
```

**Arduino v2.0 sends:**
```
  >>> OBJECT #1 DETECTED at 45° | 32.5 cm | ...
```

The `***` format doesn't exist anywhere in your Arduino v2.0 code. This condition never fires.

**Fix — update the trigger in `_parseLine()`:**

```dart
// OLD:
if (line.contains('*** OBJECT #') && line.contains('DETECTED! ***')) {

// NEW:
if (line.contains('OBJECT #') && line.contains('DETECTED')) {
```

The regex inside `_parseObjectDetection()` (`OBJECT #(\d+)`) is already correct — only the trigger needed fixing.

---

## Problem 5 🟠 — `APP:` structured lines are completely ignored

Your Arduino v2.0 sends a whole structured protocol that `_parseLine()` never handles. These fall through to the legacy CSV check (which requires exactly 3 comma-parts), fail, and are silently dropped.

**Fix — add an `APP:` branch in `_parseLine()` before the legacy CSV check:**

```dart
// In _parseLine(), add before the legacy CSV block:
if (line.startsWith('APP:')) {
  _parseAppLine(line);
  return;
}
```

```dart
void _parseAppLine(String line) {
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
          : zone == 0 ? RadarStatus.safe : RadarStatus.safe;
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

  // APP:ALERT, APP:OBJ, APP:SUDDEN_ALERT — log for now, extend as needed
  print('[UsbService] APP event: $line');
}
```

---

## Problem 6 🟡 — TestScreen color coding doesn't match v2.0 strings

After fix #1, TestScreen will show all lines. But the color coding uses old format checks:

```dart
// This won't match v2.0 sweep summary:
if (line.contains('Total Objects'))  // v2 sends "SWEEP COMPLETE | Objects detected..."
```

**Fix in `test_screen.dart`:**

```dart
Color tileColor = Colors.grey[800]!;

if (line.contains('Angle:')) {
  tileColor = Colors.orange[900]!;
} else if (line.contains('OBJECT') && line.contains('DETECTED')) {
  tileColor = Colors.green[900]!;
} else if (line.contains('SWEEP COMPLETE') || line.contains('Total Objects')) {
  tileColor = Colors.blue[900]!;
} else if (line.startsWith('APP:')) {
  tileColor = Colors.purple[900]!;    // Purple for structured APP: lines
} else if (line.contains('DANGER')) {
  tileColor = Colors.red[900]!;       // Red for danger alerts
}
```

---

## Fix Priority Summary

| Priority | Problem | File | Fix |
|----------|---------|------|-----|
| 🔴 1 | Raw lines never reach TestScreen | `usb_service.dart` | Add `_dataController.add(line.codeUnits)` at top of `_parseLine()` |
| 🔴 2 | Wrong permission (`storage` vs USB) | `usb_service.dart` | Replace with `UsbSerial.requestPermission(device)` |
| 🔴 3 | `Angle:` parser fails on v2.0 format | `usb_service.dart` | Handle `Dist:`, `°` symbol, fuzzy status matching |
| 🟠 4 | Object detection never matches | `usb_service.dart` | Update trigger from `*** OBJECT #` to `OBJECT # + DETECTED` |
| 🟠 5 | `APP:` lines silently dropped | `usb_service.dart` | Add `_parseAppLine()` handler |
| 🟡 6 | TestScreen colors don't match v2.0 | `test_screen.dart` | Update color condition strings |

**Fix #2 (permissions) + #1 (raw forwarding) first — these two will get data appearing in TestScreen within minutes.**