# PROMPT.md — Add Bluetooth Mode to Existing USB App

---

## GOAL

Add Bluetooth (HC-05) as a second communication option alongside existing USB.
User can toggle between USB and Bluetooth from the Connect screen.
All existing USB code stays untouched.

---

## WHAT CHANGES

| Area | Change |
|---|---|
| `app_res.dart` | Add Bluetooth constants/labels |
| `usb_screen.dart` | Add mode toggle tab at top |
| `app_bindings.dart` | Register new BT controller + service |
| `app_pages.dart` | No change needed |
| New files only | `bluetooth_service.dart`, `bluetooth_controller.dart` |

---

## STEP 1 — Add to app_res.dart

Add these constants (do NOT remove any existing ones):
```dart
// ─── BLUETOOTH CONFIG ────────────────────────────────────
static const String btDeviceName    = 'HC-05';
static const String btParseDelim    = ',';

// ─── BLUETOOTH LABELS ────────────────────────────────────
static const String labelBtScan         = 'SCAN FOR BLUETOOTH DEVICES';
static const String labelBtConnect      = 'CONNECT';
static const String labelBtSearching    = 'Searching for devices...';
static const String labelBtNoDevices    = 'No Bluetooth devices found';
static const String labelBtPermission   = 'Bluetooth permission required';
static const String labelBtConnected    = 'BT Connected';
static const String labelBtDisconnected = 'BT Disconnected';
static const String labelBtMacAddress   = 'MAC';
static const String labelBtPaired       = 'PAIRED';

// ─── CONNECTION MODE ─────────────────────────────────────
static const String modeUsb       = 'USB';
static const String modeBluetooth = 'BLUETOOTH';
static const String labelModeToggle = 'Connection Mode';
```

---

## STEP 2 — New File: bluetooth_service.dart

**File:** `lib/services/bluetooth_service.dart`
```dart
// Mirrors UsbService API exactly so controllers are interchangeable

class BluetoothService {
  BluetoothConnection? _connection;
  List<int> latest = [0, 0, 0];

  // Scan for paired + nearby devices
  Future<List<BluetoothDevice>> scanDevices();

  // Connect by MAC address
  Future<bool> connect(String address);

  // Stream identical shape to UsbService
  Stream<List<int>> get dataStream;

  Future<void> disconnect();
}
```

- Package: `flutter_bluetooth_serial`
- Parse format: `"left,center,right"` using `AppRes.btParseDelim`
- On parse error: return `latest` (last known good values)
- Reconnect on disconnect: retry once after 2 seconds

---

## STEP 3 — New File: bluetooth_controller.dart

**File:** `lib/controllers/bluetooth_controller.dart`
```dart
class BluetoothController extends GetxController {
  final isConnected  = false.obs;
  final isScanning   = false.obs;
  final distances    = [0, 0, 0].obs;
  final deviceList   = <BluetoothDevice>[].obs;
  final connectedMac = ''.obs;

  final _btService = Get.find<BluetoothService>();

  Future<void> scan();
  Future<void> connect(String address);
  Future<void> disconnect();
  void _listen();
}
```

- Same observable interface as `UsbController`
- `onClose()` must call `disconnect()`

---

## STEP 4 — New File: connection_mode_controller.dart

**File:** `lib/controllers/connection_mode_controller.dart`
```dart
class ConnectionModeController extends GetxController {
  // Persisted with GetStorage
  final mode = AppRes.modeUsb.obs;   // 'USB' or 'BLUETOOTH'

  bool get isUsb       => mode.value == AppRes.modeUsb;
  bool get isBluetooth => mode.value == AppRes.modeBluetooth;

  void switchToUsb() {
    _disconnectBluetooth();
    mode.value = AppRes.modeUsb;
    _save();
  }

  void switchToBluetooth() {
    _disconnectUsb();
    mode.value = AppRes.modeBluetooth;
    _save();
  }

  // On switch: disconnect active mode before enabling new one
  void _disconnectUsb();
  void _disconnectBluetooth();
  void _save();   // GetStorage persist
}
```

---

## STEP 5 — Update usb_screen.dart → connect_screen.dart

**Rename file:** `lib/screens/usb_screen.dart` → `lib/screens/connect_screen.dart`

**Update route in app_res.dart:**
```dart
// change:
static const String routeUsb = '/usb';
// to:
static const String routeConnect = '/connect';
```

### Add Mode Toggle at Top
```
┌─────────────────────────────────┐
│  CONNECTION MODE                │
│  ┌──────────┐  ┌─────────────┐  │
│  │  USB  ✓  │  │  BLUETOOTH  │  │
│  └──────────┘  └─────────────┘  │
└─────────────────────────────────┘
```

- Two-segment toggle using `AppRes.modeUsb` / `AppRes.modeBluetooth`
- Active mode: `AppRes.accentSafe` background + dark text
- Inactive mode: `AppRes.bgSurface` background + `AppRes.textSecondary`
- Wrap with `Obx()` — reads `ConnectionModeController.mode`
- On tap: call `switchToUsb()` or `switchToBluetooth()`
- Switching mode disconnects the other — show snackbar confirmation

### USB Panel (existing — no changes)

Show when `modeController.isUsb`:
- OTG hint banner
- Scan button (`AppRes.labelUsbScan`)
- USB device list with VID + chip badge
- Permission row
- Status footer

### Bluetooth Panel (new)

Show when `modeController.isBluetooth`:

**Permission Row** (show if BT permission denied):
- Amber warning: `AppRes.labelBtPermission`
- Button: `"GRANT ACCESS"`

**Scan Button:**
- Full-width: `AppRes.labelBtScan`
- `CircularProgressIndicator` when `btController.isScanning`

**Device List:**
```
┌────────────────────────────────────────┐
│  HC-05                      [CONNECT]  │
│  MAC: 00:14:03:05:2B:1A                │
├────────────────────────────────────────┤
│  BT_SENSOR_2                [CONNECT]  │  ← green left border if connected
│  MAC: 98:D3:31:FB:45:22                │
└────────────────────────────────────────┘
```
- Device name: bold, `AppRes.fontMono`
- MAC: `AppRes.labelBtMacAddress` + address, `AppRes.textSecondary`
- Connected device: `AppRes.accentSafe` left border + `AppRes.labelBtPaired` badge
- Button label: `AppRes.labelBtConnect`

**Status Footer:**
- `AppRes.labelBtSearching` / `"Found N devices"` / `AppRes.labelBtConnected`

---

## STEP 6 — Update home_screen.dart Status Chip

The USB/BT chip in top bar must reflect active mode:
```dart
Obx(() {
  final modeCtrl = Get.find<ConnectionModeController>();
  final usbCtrl  = Get.find<UsbController>();
  final btCtrl   = Get.find<BluetoothController>();

  final isConnected = modeCtrl.isUsb
      ? usbCtrl.isConnected.value
      : btCtrl.isConnected.value;

  final label = modeCtrl.isUsb
      ? (isConnected ? AppRes.labelConnected    : AppRes.labelDisconnected)
      : (isConnected ? AppRes.labelBtConnected  : AppRes.labelBtDisconnected);

  return StatusChip(connected: isConnected, label: label);
})
```

---

## STEP 7 — Update fusion_service.dart
```dart
void fuse() {
  final modeCtrl = Get.find<ConnectionModeController>();

  final distances = modeCtrl.isUsb
      ? Get.find<UsbService>().latest
      : Get.find<BluetoothService>().latest;

  final object  = visionService.latestLabel;
  final command = decisionEngine.decide(...distances, object);
  ttsService.speak(command);
}
```

---

## STEP 8 — Update app_bindings.dart

Add new registrations (keep all existing ones):
```dart
// New services
Get.lazyPut<BluetoothService>(() => BluetoothService());

// New controllers
Get.lazyPut<BluetoothController>(() => BluetoothController());
Get.lazyPut<ConnectionModeController>(() => ConnectionModeController());
```

---

## STEP 9 — Update pubspec.yaml

Add (keep `usb_serial`):
```yaml
flutter_bluetooth_serial: ^0.4.0
```

---

## STEP 10 — Update Bottom Nav Tab Icon
```dart
// In main.dart bottom nav tab for Connect:
// Change USB icon → generic connection icon

BottomNavigationBarItem(
  icon: Obx(() {
    final ctrl = Get.find<ConnectionModeController>();
    return Icon(ctrl.isUsb ? Icons.usb : Icons.bluetooth);
  }),
  label: AppRes.tabConnect,
)
```

---

## FILES CHANGED SUMMARY

| File | Action |
|---|---|
| `app_res.dart` | Add BT constants + mode labels |
| `usb_screen.dart` | Rename → `connect_screen.dart`, add toggle + BT panel |
| `home_screen.dart` | Update status chip to read active mode |
| `fusion_service.dart` | Read from active mode's service |
| `app_bindings.dart` | Register BT service + controllers |
| `main.dart` | Update route name + tab icon |

| File | Action |
|---|---|
| `bluetooth_service.dart` | NEW |
| `bluetooth_controller.dart` | NEW |
| `connection_mode_controller.dart` | NEW |

---

## RULES

- USB code: zero changes to logic, only UI additions
- Both services implement identical `dataStream` + `latest` interface
- `ConnectionModeController` is the single source of truth for active mode
- All strings from `AppRes` — no hardcoding
- GetX only — no setState, no Provider
- Switching mode auto-disconnects previous connection