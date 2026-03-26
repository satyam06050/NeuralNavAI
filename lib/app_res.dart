import 'package:flutter/material.dart';

class AppRes {
  // ─── APP INFO ────────────────────────────────────────────
  static const String appName    = 'NAV ASSIST';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Built for visually impaired navigation';

  // ─── ROUTES ──────────────────────────────────────────────
  static const String routeHome     = '/home';
  static const String routeUsb      = '/usb';
  static const String routeSettings = '/settings';

  // ─── COLORS ──────────────────────────────────────────────
  static const Color bgPrimary     = Color(0xFF0A0A0A);
  static const Color bgSurface     = Color(0xFF141414);
  static const Color accentSafe    = Color(0xFF00FF88);
  static const Color accentCaution = Color(0xFFFFB800);
  static const Color accentDanger  = Color(0xFFFF3B30);
  static const Color textPrimary   = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor   = Color(0xFF2A2A2A);
  static const Color overlayRed    = Color(0xD9FF3B30);

  // ─── FONTS ───────────────────────────────────────────────
  static const String fontMono = 'JetBrainsMono';

  // ─── FONT SIZES ──────────────────────────────────────────
  static const double fontXS  = 11.0;
  static const double fontSM  = 14.0;
  static const double fontMD  = 16.0;
  static const double fontLG  = 20.0;
  static const double fontXL  = 28.0;
  static const double fontXXL = 40.0;

  // ─── SPACING ─────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // ─── BORDER RADIUS ───────────────────────────────────────
  static const double radiusSM = 6.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 20.0;

  // ─── TOUCH TARGETS ───────────────────────────────────────
  static const double minTouchTarget = 48.0;

  // ─── SENSOR THRESHOLDS (cm) ──────────────────────────────
  static const int thresholdDanger  = 40;
  static const int thresholdCaution = 80;
  static const int maxDistance      = 200;

  // ─── USB CONFIG ──────────────────────────────────────────
  static const int    usbBaudRate   = 9600;
  static const int    usbDataBits   = 8;
  static const int    usbStopBits   = 1;
  static const String usbParseDelim = ',';

  // ─── VENDOR IDs ──────────────────────────────────────────
  static const int vendorCH340   = 0x1A86;
  static const int vendorCP2102  = 0x10C4;
  static const int vendorArduino = 0x2341;
  static const int vendorFTDI    = 0x0403;

  // ─── TTS CONFIG ──────────────────────────────────────────
  static const double ttsSpeedDefault  = 1.0;
  static const double ttsVolumeDefault = 1.0;
  static const int    ttsCooldownSec   = 3;
  static const String ttsLanguage      = 'en-US';

  // ─── GUIDANCE MESSAGES ───────────────────────────────────
  static const String msgPathClear     = 'PATH CLEAR';
  static const String msgMoveLeft      = 'MOVE LEFT';
  static const String msgMoveRight     = 'MOVE RIGHT';
  static const String msgObstacleAhead = 'OBSTACLE AHEAD';
  static const String msgSlowDown      = 'CAUTION, SLOW DOWN';
  static const String msgPersonAhead   = 'PERSON AHEAD, MOVE LEFT';
  static const String msgStopNow       = 'STOP IMMEDIATELY';
  static const String msgDangerAhead   = 'DANGER AHEAD';

  // ─── UI LABELS ───────────────────────────────────────────
  static const String labelLeft         = 'LEFT';
  static const String labelCenter       = 'CENTER';
  static const String labelRight        = 'RIGHT';
  static const String labelDetected     = 'DETECTED OBJECT';
  static const String labelLiveFeed     = 'LIVE FEED';
  static const String labelScanning     = 'SCANNING...';
  static const String labelConnected    = 'USB Connected';
  static const String labelDisconnected = 'USB Disconnected';
  static const String labelStart        = 'START';
  static const String labelStop         = 'STOP';
  static const String labelWaiting      = 'Waiting for data...';
  static const String labelNone         = 'None';

  // ─── USB SCREEN LABELS ───────────────────────────────────
  static const String labelUsbScan        = 'SCAN FOR USB DEVICES';
  static const String labelUsbConnect     = 'CONNECT';
  static const String labelUsbConnected   = 'CONNECTED';
  static const String labelUsbConnectDev  = 'CONNECT DEVICE';
  static const String labelUsbSearching   = 'Detecting USB devices...';
  static const String labelUsbNoDevices   = 'No USB devices found';
  static const String labelUsbPermission  = 'USB permission required';
  static const String labelUsbOtg         = 'Connect Arduino via USB OTG cable';
  static const String labelUsbBaud        = 'Baud Rate: 9600';
  static const String labelUsbConnFailed  = 'Connection failed';
  static const String labelUsbFoundOne    = 'Found 1 device';
  static const String labelUsbDevice      = 'USB Device';

  // ─── SETTINGS LABELS ─────────────────────────────────────
  static const String settingsTtsSpeed    = 'TTS Speed';
  static const String settingsTtsVolume   = 'TTS Volume';
  static const String settingsRepeatMsg   = 'Repeat same message';
  static const String settingsCooldown    = 'Min gap between messages (sec)';
  static const String settingsDangerDist  = 'Danger distance (cm)';
  static const String settingsCautionDist = 'Caution distance (cm)';
  static const String settingsVibration   = 'Vibration enabled';
  static const String settingsCamera      = 'Camera detection enabled';
  static const String settingsVoice       = 'Voice Settings';
  static const String settingsThreshold   = 'Threshold Settings';
  static const String settingsFeedback    = 'Feedback';
  static const String settingsAbout       = 'About';

  // ─── DETECTED OBJECT LABELS ──────────────────────────────
  static const String objPerson  = 'Person';
  static const String objVehicle = 'Vehicle';
  static const String objNone    = 'None';

  // ─── NAV TABS ────────────────────────────────────────────
  static const String tabHome     = 'Home';
  static const String tabConnect  = 'Connect';
  static const String tabSettings = 'Settings';

  // ─── ASSETS ──────────────────────────────────────────────
  static const String fontPathRegular = 'assets/fonts/JetBrainsMono-Regular.ttf';
  static const String fontPathBold    = 'assets/fonts/JetBrainsMono-Bold.ttf';

  // ─── LAYOUT ───────────────────────────────────────────────
  static const double cameraFeedHeight   = 240.0;
  static const double detectedRowPadV    = 14.0;

  // ─── ANIMATION DURATIONS ─────────────────────────────────
  static const Duration animFast   = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animPulse  = Duration(milliseconds: 800);

  // ─── FUSION INTERVAL ─────────────────────────────────────
  static const Duration fusionTick = Duration(milliseconds: 500);
}
