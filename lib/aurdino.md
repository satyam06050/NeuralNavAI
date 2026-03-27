5. Actual Serial Output Format (from Arduino code)
The Arduino sends these exact message types over Serial at 9600 baud. Flutter must parse all of them.
Message Type 1 — Startup Header (sent once on boot)
============================================
       SMART RADAR SYSTEM — ONLINE
============================================
Detection threshold : 150 cm
Close-alert range   : 50 cm
Angle step          : 5 deg
--------------------------------------------
Message Type 2 — Per-Angle Status (sent at every angle step)
Angle: 45  | Distance: 32.5 cm  | Status: WARNING
Angle: 90  | Distance: 210.0 cm | Status: SAFE
Angle: 135 | Distance: --- cm   | Status: INVALID
Message Type 3 — Object Detection Event (sent when new object found)
  *** OBJECT #1 DETECTED! ***
  *** OBJECT #2 DETECTED! ***
Message Type 4 — End-of-Sweep Summary (sent after each full 180° sweep)
--------------------------------------------
>>> Total Objects Detected: 2
============================================

6. Flutter App — What It Must Parse
Flutter receives a continuous raw text stream. It must buffer characters, split on newlines, and identify which message type each line is.
Line Classification Rules for Flutter Parser
Line ContainsActionStarts with Angle:Extract angle, distance, status → update radar UIContains *** OBJECT #Extract object number → trigger alert + voiceStarts with >>> Total ObjectsExtract final count → speak sweep summaryContains SMART RADAR SYSTEMConnection confirmed → show connected stateContains ---- or ====Separator line → ignoreContains Detection thresholdStore config values for display
Data to Extract from Each Angle Line
From: Angle: 45  | Distance: 32.5 cm  | Status: WARNING

Angle → 45 (integer, 0–180)
Distance → 32.5 (float in cm) or null if ---
Status → WARNING / SAFE / INVALID


7. Flutter App Modules
7.1 Dependencies
PackageUseusb_serialRead from FT232R FTDI chip over OTGflutter_ttsSpeak voice guidance to blind uservibrationHaptic alerts
7.2 Android Setup

USB Host permission in AndroidManifest.xml
device_filter.xml → FTDI VID decimal 1027 (= hex 0x0403)
Auto-launch app when OTG cable plugged in

7.3 Service: USB Serial Manager

Scan USB devices, find VID = 0x0403
Open port at 9600 baud (must match Arduino)
Stream raw bytes → character buffer
Split buffer on \n → feed complete lines to parser

7.4 Service: Radar Data Parser

Receives one line at a time
Classifies line type (Angle / Object / Summary / Header / Separator)
Extracts values using string splitting
Emits structured events to UI and voice engine

7.5 Service: Voice Engine (TTS)

New object detected: "Object number 1 detected at 45 degrees, 32 centimeters"
WARNING status: "Warning! Object very close, 32 centimeters ahead"
Sweep summary with objects: "Scan complete. 2 objects detected."
Sweep summary clear: "Area is clear. Safe to move."
Uses message queue — never overlaps speech
Speech rate: 0.45 (slow and clear)

7.6 Service: Haptic Feedback
EventVibration PatternWARNING status (< 150 cm)Long vibration 500 msDANGER very close (< 50 cm)Rapid double pulseNew object detectedTriple short pulseSweep complete, clearSingle short vibration