# PROMPT.md — Frontend UI (Flutter Screens + USB)

---

## DESIGN DIRECTION

**Aesthetic:** Industrial-utilitarian dark theme — HUD display, accessibility-first, high contrast.

**Color Palette:**
- Background: `#0A0A0A`
- Surface: `#141414`
- Accent (safe): `#00FF88`
- Accent (caution): `#FFB800`
- Accent (danger): `#FF3B30`
- Text primary: `#F0F0F0`
- Text secondary: `#666666`

**Font:** `JetBrains Mono`
**Principle:** Large text. High contrast. No clutter.

---

## SCREEN 1 — Home / Dashboard Screen

**File:** `lib/screens/home_screen.dart`

### Top Bar
- App name: `"NAV ASSIST"` — monospace, letter-spaced
- USB status chip:
  - 🟢 green dot + `AppRes.labelConnected` → `"USB Connected"`
  - 🔴 red dot + `AppRes.labelDisconnected` → `"USB Disconnected"`
- Static signal/power placeholder icon

### Status Banner (full width, prominent)
- Large centered guidance text from `AppRes`:
  - `AppRes.msgPathClear` / `AppRes.msgMoveLeft` / `AppRes.msgObstacleAhead`
- Background color animates (300ms) based on `NavLevel`:
  - `safe` → `AppRes.accentSafe` + dark text
  - `caution` → `AppRes.accentCaution` + dark text
  - `danger` → `AppRes.accentDanger` + white text

### Distance Sensor Panel (3 cards)
```
[ LEFT ]   [ CENTER ]   [ RIGHT ]
  120cm       45cm        80cm
  ██████░░   ████████░   ███████░
```
- Use `DistanceCard` widget for each
- Labels from `AppRes.labelLeft`, `AppRes.labelCenter`, `AppRes.labelRight`

### Detected Object Row
- Label: `AppRes.labelDetected`
- Value: `AppRes.objPerson` / `AppRes.objVehicle` / `AppRes.objNone`
- Icon beside value

### Camera Feed
- Live `CameraPreview` in rounded container
- Top-left overlay: `AppRes.labelLiveFeed`
- Top-right overlay: `AppRes.labelScanning` + blinking dot

### FAB
- Label: `AppRes.labelStart` / `AppRes.labelStop`
- Color: `AppRes.accentSafe` when active, grey when stopped
- Position: bottom center

---

## SCREEN 2 — USB Connect Screen

**File:** `lib/screens/usb_screen.dart`
*(replaces bluetooth_screen.dart)*

### Header
- Back arrow + title: `"CONNECT DEVICE"`

### OTG Hint Banner
- Full-width info row: `AppRes.labelUsbOtg`
- Subtext: `AppRes.labelUsbBaud` → `"Baud Rate: 9600"`

### Scan Button
- Full-width: `AppRes.labelUsbScan` → `"SCAN FOR USB DEVICES"`
- Shows `CircularProgressIndicator` during scan

### Device List
- `ListView` of detected USB devices
- Each tile:
  - Device name (bold monospace)
  - Vendor ID in secondary color (e.g., `VID: 0x1A86`)
  - Chip label badge: `"CH340"` / `"CP2102"` / `"Arduino"` / `"FTDI"`
  - `AppRes.labelUsbConnect` button (outlined, right side)
- Connected device: green left border + lock icon

### Permission Row
- If permission denied: amber warning row
- Text: `AppRes.labelUsbPermission`
- Button: `"GRANT ACCESS"`

### Status Footer
- `AppRes.labelUsbSearching` / `"Found 2 devices"` / `AppRes.labelConnected`

---

## SCREEN 3 — Settings Screen

**File:** `lib/screens/settings_screen.dart`

### Section: `AppRes.settingsVoice`
- TTS Speed slider (0.5x → 2.0x) — label: `AppRes.settingsTtsSpeed`
- TTS Volume slider — label: `AppRes.settingsTtsVolume`
- Toggle: `AppRes.settingsRepeatMsg`
- Number input: `AppRes.settingsCooldown`

### Section: `AppRes.settingsThreshold`
- Number input: `AppRes.settingsDangerDist` (default: `AppRes.thresholdDanger`)
- Number input: `AppRes.settingsCautionDist` (default: `AppRes.thresholdCaution`)

### Section: `AppRes.settingsFeedback`
- Toggle: `AppRes.settingsVibration`
- Toggle: `AppRes.settingsCamera`

### Section: `AppRes.settingsAbout`
- `AppRes.appVersion`
- `AppRes.appTagline`

---

## SCREEN 4 — Danger Overlay

**File:** `lib/widgets/danger_overlay.dart`

- Triggered: center distance < `AppRes.thresholdDanger`
- Full-screen overlay: `AppRes.overlayRed` (85% opacity)
- Centered warning triangle icon (large, white)
- Text: `AppRes.msgDangerAhead` (bold caps)
- Subtext: distance in cm (e.g., `"32cm"`)
- Pulse animation: scale 1.0 → 1.15, repeat, duration `AppRes.animPulse`
- Auto-dismisses when distance ≥ `AppRes.thresholdDanger`

---

## WIDGET — Distance Bar Card

**File:** `lib/widgets/distance_card.dart`
```dart
DistanceCard(
  label: AppRes.labelCenter,   // from AppRes
  distance: 45,
  maxDistance: AppRes.maxDistance,
)
```

- Bar color logic:
  - `>= AppRes.thresholdCaution` → `AppRes.accentSafe`
  - `>= AppRes.thresholdDanger` → `AppRes.accentCaution`
  - `< AppRes.thresholdDanger`  → `AppRes.accentDanger`
- Animate with `TweenAnimationBuilder`, duration `AppRes.animNormal`
- Font: `AppRes.fontMono`

---

## WIDGET — Status Banner

**File:** `lib/widgets/status_banner.dart`
```dart
StatusBanner(
  message: AppRes.msgMoveLeft,
  level: NavLevel.caution,
)
```

- `NavLevel` enum: `safe`, `caution`, `danger`
- `AnimatedContainer` color transition: `AppRes.animNormal` (300ms)
- Font size: `AppRes.fontXL` (28sp), bold, uppercase
- Full screen width

---

## NAVIGATION STRUCTURE

**File:** `lib/main.dart`
```dart
GetMaterialApp(
  title: AppRes.appName,
  initialBinding: AppBindings(),
  initialRoute: AppRes.routeHome,
  getPages: AppPages.routes,   // home, usb, settings
  theme: ThemeData(
    scaffoldBackgroundColor: AppRes.bgPrimary,
    fontFamily: AppRes.fontMono,
  ),
)
```

Bottom nav tabs:
- 🏠 `AppRes.tabHome`
- 🔌 `AppRes.tabConnect`  ← USB icon (not Bluetooth)
- ⚙️ `AppRes.tabSettings`

No tab switch animation (instant, accessibility requirement).

---

## SCREENS SUMMARY

| Screen | File | Purpose |
|---|---|---|
| Home | `home_screen.dart` | Main HUD dashboard |
| USB Connect | `usb_screen.dart` | USB OTG device connect |
| Settings | `settings_screen.dart` | Config sliders/toggles |

| Widget | File | Purpose |
|---|---|---|
| DangerOverlay | `danger_overlay.dart` | Full-screen alert |
| DistanceCard | `distance_card.dart` | L/C/R sensor bars |
| StatusBanner | `status_banner.dart` | Guidance message |

---

## ACCESSIBILITY REQUIREMENTS

- Min touch target: `AppRes.minTouchTarget` (48×48px)
- Min text: `AppRes.fontMD` (16sp), key text `AppRes.fontXL`
- `Semantics` widget on all sensor value widgets
- Never color-only — always pair with text or icon
- Respect `MediaQuery.textScaleFactor`

---

## KEY CHANGES FROM BLUETOOTH VERSION

| Bluetooth | USB |
|---|---|
| `bluetooth_screen.dart` | `usb_screen.dart` |
| MAC address display | Vendor ID + chip label |
| Signal strength icon | USB OTG hint banner |
| "Connected to HC-05" | `AppRes.labelConnected` |
| Bluetooth icon in tab | USB plug icon in tab |
| Permission auto (paired) | `AppRes.labelUsbPermission` grant flow |