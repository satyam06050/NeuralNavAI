# Arduino Obstacle Detection → Flutter Navigation Guide
### Implementation Plan for Visually Impaired Navigation Assistance

---

## 1. Understanding the Serial Data Format

From the debug logs, your Arduino sends two types of messages over Bluetooth/Serial:

### A. `APP:DATA` — Per-angle sensor readings
```
APP:DATA,<angle>,<distance_cm>,<severity>
```
| Field | Meaning |
|---|---|
| `angle` | Servo angle in degrees (0°–180°) |
| `distance_cm` | Measured distance; `999.0` = no obstacle (>500cm) |
| `severity` | `0` = Safe, `2` = Warning, `3` = Danger |

### B. `APP:ALERT` — Named object detections
```
APP:ALERT,id=<n>,angle=<deg>,dist=<cm>,type=<TYPE>
```
| Type | Meaning |
|---|---|
| `2ND_WARNING` | Object within 250cm — caution |
| `BIG_WARNING` | Object within 100cm — stop |

### C. `APP:SUDDEN_ALERT` — Emergency trigger
```
APP:SUDDEN_ALERT,dist=<cm>,action=STOP_IMMEDIATELY
```
This fires when an object appears in front suddenly — highest priority.

---

## 2. Data Parsing Strategy

### Step 1 — Accumulate a Full Scan
- The Arduino sweeps from 0° to 180° and sends one `APP:DATA` per angle step (every 5°)
- Collect all 37 readings (0°,5°,10°…180°) into a **scan buffer**
- Consider a scan "complete" when angle resets back to 0° or after a timeout (~500ms)

### Step 2 — Divide the 180° Arc into Zones
Map angles to directional zones for user guidance:

| Zone | Angle Range | Guidance Meaning |
|---|---|---|
| **Hard Left** | 0° – 30° | Far left side |
| **Left** | 35° – 70° | Left side |
| **Center** | 75° – 105° | Directly ahead |
| **Right** | 110° – 145° | Right side |
| **Hard Right** | 150° – 180° | Far right side |

> **Note:** Confirm this mapping by physically pointing your sensor and checking which angles map to which directions. It may be mirrored.

### Step 3 — Determine the Danger Level Per Zone
For each zone, take the **minimum distance** among all readings in that zone.

| Distance | Level |
|---|---|
| > 250 cm | ✅ SAFE |
| 100–250 cm | ⚠️ WARNING |
| < 100 cm | 🚨 DANGER |

### Step 4 — Generate Navigation Instruction
Priority order (highest to lowest):

1. `SUDDEN_ALERT` received → **"STOP IMMEDIATELY"** (override everything)
2. Center zone is DANGER → **"STOP — obstacle directly ahead"**
3. Center zone is WARNING + left is SAFE → **"Bear left — obstacle ahead"**
4. Center zone is WARNING + right is SAFE → **"Bear right — obstacle ahead"**
5. All zones SAFE → **"Path clear — safe to move"**
6. Left is DANGER → **"Move away from left"**
7. Right is DANGER → **"Move away from right"**

---

## 3. Flutter Implementation Architecture

### Recommended Layers

```
BLE/Serial Layer
     ↓
Raw Data Stream (String lines)
     ↓
Parser Service (extracts APP:DATA / APP:ALERT / APP:SUDDEN_ALERT)
     ↓
Scan Buffer (collects one full sweep)
     ↓
Zone Analyzer (maps angles → zones → danger levels)
     ↓
Instruction Engine (decides navigation command)
     ↓
Output Layer (TTS + Haptic + Visual UI)
```

---

## 4. Output Modalities

### A. Text-to-Speech (TTS) — Primary
Use `flutter_tts` package.

- Announce every **new** instruction (don't repeat same message)
- Rate: medium speed, clear enunciation
- Priority queue: SUDDEN_ALERT interrupts any ongoing speech
- Cooldown: don't re-announce the same direction more than once per 2 seconds

### B. Haptic Feedback — Secondary (instant, no audio needed)
Use `HapticFeedback` from Flutter services:

| Command | Pattern |
|---|---|
| STOP | Long continuous vibration |
| Danger ahead | 3 quick pulses |
| Bear left/right | 2 pulses left side / right side (if using phone in hand) |
| Path clear | Single soft tick |

### C. Visual UI — For companions / sighted mode
- Large colored arc/radar showing 0°–180°
- Color-coded zones: Green = safe, Yellow = warning, Red = danger
- Big text instruction in center of screen
- High contrast, large fonts (accessibility-first)

---

## 5. Edge Cases to Handle

| Situation | How to Handle |
|---|---|
| `distance = 999.0` | Treat as SAFE / no obstacle |
| Partial scan (Bluetooth lag) | Use last complete scan; discard incomplete |
| Rapid SUDDEN_ALERTs | Deduplicate within 1 second |
| All zones show DANGER | Say: "Obstacles all around — stand still" |
| Reconnect after disconnect | Reset scan buffer, re-announce connection |
| Garbled/incomplete line | Skip the line; don't crash parser |

---

## 6. Voice Instruction Script Examples

| Situation | What to Say |
|---|---|
| SUDDEN_ALERT | *"Stop immediately! Sudden obstacle!"* |
| Center < 60cm | *"Danger! Object very close ahead. Stop."* |
| Center 60–100cm | *"Warning — obstacle ahead. Slow down."* |
| Center clear, left danger | *"Obstacle on your left. Move right."* |
| Center clear, right danger | *"Obstacle on your right. Move left."* |
| All clear | *"Path is clear."* |
| Multiple danger zones | *"Obstacles nearby. Move carefully."* |

---

## 7. Suggested Flutter Package Stack

| Purpose | Package |
|---|---|
| Bluetooth Serial | `flutter_bluetooth_serial` or `flutter_blue_plus` |
| Text-to-Speech | `flutter_tts` |
| Haptic feedback | Flutter built-in `HapticFeedback` |
| State management | `riverpod` or `provider` |
| Background audio | `just_audio` (for earcon beeps) |

---

## 8. Testing Checklist

- [ ] Parser correctly handles all 3 message types
- [ ] Zone mapping matches physical sensor direction
- [ ] TTS fires correctly without repetition
- [ ] SUDDEN_ALERT overrides all other speech
- [ ] App handles Bluetooth disconnect gracefully
- [ ] UI readable in sunlight (high contrast)
- [ ] Tested with earphones (primary use case for visually impaired)

---

*This document covers the full implementation logic from raw Arduino serial data to accessible navigation guidance for visually impaired users.*