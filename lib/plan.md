# PROMPT.md — AI Navigation Assistant (Flutter + USB Serial)

---

## PHASE 1 — Project Setup

**Prompt:**
Create a new Flutter project named `ai_nav_assist`.
Set up the folder structure:
- `lib/screens/` — UI screens
- `lib/services/` — USB, TTS, decision logic
- `lib/models/` — data models
- `lib/utils/` — constants, helpers

Build a minimal home screen with:
- App title: "AI Navigation Assist"
- Status text widget: "Waiting for data..."
- A Start/Stop toggle button
- No logic yet — UI only

---

## PHASE 2 — USB Serial Communication

**Prompt:**
Add `usb_serial` to `pubspec.yaml`.

Add to `AndroidManifest.xml`:
```xml
<uses-feature android:name="android.hardware.usb.host" />
<intent-filter>
    <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
</intent-filter>
<meta-data
    android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED"
    android:resource="@xml/device_filter" />
```

Create `res/xml/device_filter.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <usb-device vendor-id="0x1A86" />  <!-- CH340 -->
    <usb-device vendor-id="0x10C4" />  <!-- CP2102 -->
    <usb-device vendor-id="0x2341" />  <!-- Arduino -->
</resources>
```

Create `lib/services/usb_service.dart`:
- Detect connected USB devices via `UsbSerial.listDevices()`
- Request USB permission from user
- Open port: baud rate `9600`, 8N1
- Read incoming serial stream
- Parse format: `"left,center,right"` (e.g., `"120,45,80"`)
- Expose `Stream<List<int>>` of [left, center, right]
- Handle device connect/disconnect events

Update home screen to:
- Show USB connected/disconnected status
- Display live parsed values: Left: 120 | Center: 45 | Right: 80

---

## PHASE 3 — Text-to-Speech Output

**Prompt:**
Add `flutter_tts` to `pubspec.yaml`.

Create `lib/services/tts_service.dart`:
- Initialize TTS engine
- Method: `speak(String message)`
- Set language to `en-US`, pitch and speed tuned for clarity
- Cooldown: skip same message within 3 seconds

Test with hardcoded calls:
- `speak("Move left")`
- `speak("Obstacle ahead")`
- `speak("Path clear")`

---

## PHASE 4 — Decision Engine

**Prompt:**
Create `lib/services/decision_engine.dart`.

Input: `List<int> distances` → [left, center, right]
```dart
const int DANGER  = 40;
const int CAUTION = 80;

String decide(int left, int center, int right) {
  if (center < DANGER) {
    if (left > right) return "Move left";
    else return "Move right";
  } else if (center < CAUTION) {
    return "Caution, slow down";
  } else {
    return "Path clear";
  }
}
```

- Subscribe to USB stream
- On each reading → `decide()` → `tts_service.speak()`
- Minimum 2-second delay between voice commands

---

## PHASE 5 — Camera Integration

**Prompt:**
Add `camera` to `pubspec.yaml`.

Create `lib/screens/camera_screen.dart`:
- Initialize back camera
- Show live `CameraPreview`
- Overlay label: "Scanning..."
- No detection yet — feed only

Add as tab in home screen.

---

## PHASE 6 — Object Detection (Vision)

**Prompt:**
Add `google_mlkit_object_detection` to `pubspec.yaml`.

Create `lib/services/vision_service.dart`:
- Capture frame from camera stream
- Run object detection
- Return detected label: `"person"`, `"car"`, `"bicycle"`

Update decision engine:
```dart
String decide(int left, int center, int right, String? object) {
  if (object == "person" && center < 60) return "Person ahead, move left";
  if (object == "car") return "Stop immediately";
  // existing logic...
}
```

---

## PHASE 7 — Sensor + Vision Fusion

**Prompt:**
Create `lib/services/fusion_service.dart`:
```dart
void fuse() {
  final distances = usbService.latest;
  final object    = visionService.latestLabel;
  final command   = decisionEngine.decide(...distances, object);
  ttsService.speak(command);
}
```

- Timer: every 500ms
- Avoid overlapping TTS calls

---

## PHASE 8 — UX Polish

**Prompt:**
1. Vibration feedback (`vibration` package):
   - Short buzz → caution
   - Long buzz → danger

2. Reduce voice spam:
   - Track last message + timestamp
   - Skip if same within 3 seconds

3. Visual indicator cards:
   - L/C/R distance bars (green/amber/red)
   - Detected object label
   - Current guidance text

4. Latency target: USB read → decision → TTS < 1 second

---

## PHASE 9 — Testing

**Prompt:**
Create `test/navigation_test.dart`:

| Input (L, C, R) | Object   | Expected Output           |
|-----------------|----------|---------------------------|
| 100, 20, 100    | null     | "Move left"               |
| 10, 20, 100     | null     | "Move right"              |
| 100, 100, 100   | null     | "Path clear"              |
| 100, 50, 100    | "person" | "Person ahead, move left" |
| 100, 100, 100   | "car"    | "Stop immediately"        |

Manual tests:
- [ ] USB connect/disconnect handling
- [ ] Indoor corridor
- [ ] Crowded space
- [ ] Low-light
- [ ] Walking speed latency

---

## DEPENDENCIES
```yaml
dependencies:
  usb_serial: ^0.5.2
  flutter_tts: ^3.8.5
  camera: ^0.10.5
  google_mlkit_object_detection: ^0.12.0
  vibration: ^1.8.4
  permission_handler: ^11.0.1
```

---

## NOTES

- Requires Android phone with USB OTG support
- Arduino connects via USB OTG cable (Type-A to Type-C or micro-USB adapter)
- Common USB-Serial chips: CH340 (most clones), CP2102, FTDI
- Baud rate must match Arduino Serial.begin() — default `9600`
- Test on real device only — USB OTG won't work on emulator