import 'package:get/get.dart';
import '../app_res.dart';
import '../models/radar_reading.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

/// Navigation Guidance Controller
/// Implements the logic from guide.md for converting Arduino sensor data
/// into navigation instructions for visually impaired users
class NavGuideController extends GetxController {
  final isConnected = false.obs;
  final isActive = false.obs;

  // Zone-based distance data (in cm)
  // Zones: Hard Left, Left, Center, Right, Hard Right
  final zoneDistances = <int>[999, 999, 999, 999, 999].obs;

  // Danger levels per zone
  final zoneLevels = <NavLevel>[
    NavLevel.safe,
    NavLevel.safe,
    NavLevel.safe,
    NavLevel.safe,
    NavLevel.safe,
  ].obs;

  // Current navigation instruction
  final currentInstruction = ''.obs;
  final instructionPriority = InstructionPriority.none.obs;

  // Scan buffer for collecting full 180° sweep
  final Map<int, double> scanBuffer = {}; // angle -> distance
  DateTime? lastScanTime;

  // TTS cooldown management
  DateTime? lastSpeechTime;
  String? lastSpokenMessage;

  // Services
  TtsService? get _tts {
    try {
      return Get.find<TtsService>();
    } catch (e) {
      print('[NavGuideController] TTS service not found: $e');
      return null;
    }
  }

  VibrationService? get _vibration {
    try {
      return Get.find<VibrationService>();
    } catch (e) {
      print('[NavGuideController] Vibration service not found: $e');
      return null;
    }
  }

  // Zone angle ranges (from guide.md)
  static const zoneAngleRanges = [
    (0, 30), // Hard Left
    (35, 70), // Left
    (75, 105), // Center
    (110, 145), // Right
    (150, 180), // Hard Right
  ];

  @override
  void onInit() {
    super.onInit();
    ever(isConnected, (connected) {
      if (!connected) {
        resetScanBuffer();
        currentInstruction.value = AppRes.labelWaiting;
        instructionPriority.value = InstructionPriority.none;
      }
    });
  }

  /// Update connection status
  void updateConnection(bool connected) {
    isConnected.value = connected;
    if (connected && isActive.value) {
      resetScanBuffer();
    }
  }

  /// Toggle navigation guidance active state
  void toggleActive() {
    isActive.value = !isActive.value;
    print(
      '[NavGuideController] toggleActive() called, isActive: ${isActive.value}, isConnected: ${isConnected.value}',
    );

    if (isActive.value && isConnected.value) {
      resetScanBuffer();
      print('[NavGuideController] Speaking activation message');
      _tts?.speak('Navigation guidance activated');
    } else {
      print('[NavGuideController] Speaking deactivation message');
      _tts?.speak('Navigation guidance deactivated');
    }
  }

  /// Test voice - speak CURRENT navigation instruction based on actual Arduino data
  void testNavigationSpeech() {
    print('[NavGuideController] NAVIGATION AUDIO button pressed');

    // Check if we have any Arduino data
    if (scanBuffer.isEmpty || !isConnected.value) {
      print(
        '[NavGuideController] No Arduino data - isConnected: ${isConnected.value}, scanBuffer empty: ${scanBuffer.isEmpty}',
      );
      _tts?.speak(
        'No Arduino data received. Connect Arduino and activate guidance.',
        immediate: true,
      );
      return;
    }

    // Analyze zones from current scan buffer
    _analyzeZones();

    print('[NavGuideController] Current zone distances:');
    print(
      '[NavGuideController]   Center: ${zoneDistances[2]}cm, Level: ${zoneLevels[2]}',
    );
    print(
      '[NavGuideController]   Left: ${zoneDistances[1]}cm, Level: ${zoneLevels[1]}',
    );
    print(
      '[NavGuideController]   Right: ${zoneDistances[3]}cm, Level: ${zoneLevels[3]}',
    );

    // Generate and speak the ACTUAL current navigation instruction
    // Temporarily set active to true for testing
    final wasActive = isActive.value;
    isActive.value = true;
    _generateInstruction(0);

    // Restore previous state after short delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (!wasActive) isActive.value = false;
    });

    print('[NavGuideController] Navigation instruction generated and spoken');
  }

  /// Process individual radar reading from USB service
  void onRadarReading(RadarReading reading) {
    if (!isConnected.value || !reading.isValid) return;

    // Add to scan buffer
    if (reading.distance != null) {
      scanBuffer[reading.angle] = reading.distance!;
      lastScanTime = DateTime.now();

      // Update zone distances immediately
      _updateZoneFromReading(reading);
    }

    // Process real-time alerts if active
    if (isActive.value) {
      _processRealtimeAlert(reading);
    }
  }

  /// Process complete sweep data
  void onSweepComplete(int totalObjects) {
    print(
      '[NavGuideController] onSweepComplete called - total objects: $totalObjects',
    );
    print(
      '[NavGuideController] isConnected: ${isConnected.value}, isActive: ${isActive.value}',
    );

    if (!isConnected.value) {
      print('[NavGuideController] Not connected - returning');
      return;
    }

    // Analyze zones from complete scan
    _analyzeZones();
    print(
      '[NavGuideController] Zones analyzed - center: ${zoneDistances[2]}cm, left: ${zoneDistances[1]}cm, right: ${zoneDistances[3]}cm',
    );

    // Generate navigation instruction
    _generateInstruction(totalObjects);
  }

  /// Reset scan buffer (called on disconnect or reconnection)
  void resetScanBuffer() {
    scanBuffer.clear();
    zoneDistances.assignAll([999, 999, 999, 999, 999]);
    zoneLevels.assignAll([
      NavLevel.safe,
      NavLevel.safe,
      NavLevel.safe,
      NavLevel.safe,
      NavLevel.safe,
    ]);
    currentInstruction.value = AppRes.labelWaiting;
    instructionPriority.value = InstructionPriority.none;
  }

  /// Update zone distance from single reading
  void _updateZoneFromReading(RadarReading reading) {
    final angle = reading.angle;
    final distance = reading.distance ?? 999;

    // Find which zone this angle belongs to
    for (int i = 0; i < zoneAngleRanges.length; i++) {
      final range = zoneAngleRanges[i];
      if (angle >= range.$1 && angle <= range.$2) {
        // Update zone distance with minimum (closest obstacle)
        if (distance < zoneDistances[i]) {
          zoneDistances[i] = distance.toInt();
          zoneLevels[i] = _getLevelForDistance(distance);
        }
        break;
      }
    }
  }

  /// Analyze all zones from scan buffer
  void _analyzeZones() {
    // Reset zone distances
    zoneDistances.assignAll([999, 999, 999, 999, 999]);

    // Process all buffered readings
    scanBuffer.forEach((angle, distance) {
      for (int i = 0; i < zoneAngleRanges.length; i++) {
        final range = zoneAngleRanges[i];
        if (angle >= range.$1 && angle <= range.$2) {
          // Take minimum distance in each zone
          if (distance < zoneDistances[i]) {
            zoneDistances[i] = distance.toInt();
          }
          break;
        }
      }
    });

    // Calculate danger levels
    for (int i = 0; i < 5; i++) {
      zoneLevels[i] = _getLevelForDistance(zoneDistances[i].toDouble());
    }
  }

  /// Get danger level for distance
  NavLevel _getLevelForDistance(double distance) {
    if (distance >= 999 || distance > 250) return NavLevel.safe;
    if (distance < 100) return NavLevel.danger;
    return NavLevel.warning;
  }

  /// Process real-time alerts (SUDDEN_ALERT equivalent)
  void _processRealtimeAlert(RadarReading reading) {
    if (!reading.isValid || reading.distance == null) return;

    final distance = reading.distance!;

    // Immediate danger - object very close ahead (center zone)
    if (reading.angle >= 75 && reading.angle <= 105 && distance < 60) {
      _triggerImmediateStop();
    }
  }

  /// Generate navigation instruction based on zone analysis
  void _generateInstruction(int totalObjects) {
    print('[NavGuideController] _generateInstruction called');

    final centerDist = zoneDistances[2]; // Center zone
    final leftDist = zoneDistances[1]; // Left zone
    final rightDist = zoneDistances[3]; // Right zone

    final centerLevel = zoneLevels[2];
    final leftLevel = zoneLevels[1];
    final rightLevel = zoneLevels[3];

    print(
      '[NavGuideController] Zone levels - Center: $centerLevel (${centerDist}cm), Left: $leftLevel (${leftDist}cm), Right: $rightLevel (${rightDist}cm)',
    );

    // Priority 1: All zones dangerous - multiple danger zones
    if (centerLevel == NavLevel.danger &&
        leftLevel == NavLevel.danger &&
        rightLevel == NavLevel.danger) {
      print('[NavGuideController] Multiple danger zones detected');
      _setInstruction(
        'Obstacles nearby. Move carefully.',
        InstructionPriority.critical,
      );
      return;
    }

    // Priority 2: Center danger - very close object
    if (centerLevel == NavLevel.danger) {
      print(
        '[NavGuideController] Center danger detected - distance: $centerDist',
      );
      if (centerDist < 60) {
        _setInstruction(
          'Danger! Object very close ahead. Stop.',
          InstructionPriority.high,
        );
      } else if (leftLevel == NavLevel.safe) {
        _setInstruction(
          'Stop immediately! Sudden obstacle!',
          InstructionPriority.high,
        );
      } else if (rightLevel == NavLevel.safe) {
        _setInstruction(
          'Stop immediately! Sudden obstacle!',
          InstructionPriority.high,
        );
      } else {
        _setInstruction(
          'Danger! Object very close ahead. Stop.',
          InstructionPriority.high,
        );
      }
      return;
    }

    // Priority 3: Center warning (60-100cm)
    if (centerLevel == NavLevel.warning) {
      print(
        '[NavGuideController] Center warning detected - distance: $centerDist',
      );
      if (centerDist >= 60 && centerDist <= 100) {
        _setInstruction(
          'Warning — obstacle ahead. Slow down.',
          InstructionPriority.medium,
        );
      }

      // Side dangers - move opposite direction
      if (leftLevel == NavLevel.danger) {
        _setInstruction(
          'Obstacle on your left. Move right.',
          InstructionPriority.medium,
        );
        return;
      }

      if (rightLevel == NavLevel.danger) {
        _setInstruction(
          'Obstacle on your right. Move left.',
          InstructionPriority.medium,
        );
        return;
      }

      return;
    }

    // Priority 4: Side dangers only (center clear)
    if (leftLevel == NavLevel.danger) {
      print('[NavGuideController] Left danger detected');
      _setInstruction(
        'Obstacle on your left. Move right.',
        InstructionPriority.medium,
      );
      return;
    }

    if (rightLevel == NavLevel.danger) {
      print('[NavGuideController] Right danger detected');
      _setInstruction(
        'Obstacle on your right. Move left.',
        InstructionPriority.medium,
      );
      return;
    }

    // Priority 5: All clear
    print('[NavGuideController] Path is clear');
    _setInstruction('Path is clear.', InstructionPriority.low);
  }

  /// Set instruction with priority and TTS
  void _setInstruction(String message, InstructionPriority priority) {
    print('[NavGuideController] _setInstruction called: "$message"');

    // Always update the display
    currentInstruction.value = message;
    instructionPriority.value = priority;

    // Don't speak if not active
    if (!isActive.value) {
      print('[NavGuideController] Not active - skipping speech');
      return;
    }

    final now = DateTime.now();

    // Check cooldown - only skip if EXACT same message within 3 seconds
    if (message == lastSpokenMessage &&
        lastSpeechTime != null &&
        now.difference(lastSpeechTime!).inSeconds < 3) {
      print(
        '[NavGuideController] Skipping - same message in cooldown (${now.difference(lastSpeechTime!).inSeconds}s)',
      );
      return;
    }

    // Speak the message
    final immediate =
        priority == InstructionPriority.critical ||
        priority == InstructionPriority.high;

    print(
      '[NavGuideController] Speaking via TTS: "$message" (immediate: $immediate)',
    );
    print('[NavGuideController] TTS available: ${_tts != null}');

    if (_tts != null) {
      _tts!.speak(message, immediate: immediate);
      print('[NavGuideController] TTS speak called successfully');

      lastSpeechTime = now;
      lastSpokenMessage = message;

      // Trigger haptic feedback
      _triggerHaptic(priority);
    } else {
      print('[NavGuideController] ERROR: TTS is null!');
    }
  }

  /// Trigger immediate stop (highest priority)
  void _triggerImmediateStop() {
    _setInstruction(
      'STOP IMMEDIATELY! Sudden obstacle!',
      InstructionPriority.critical,
    );
    _vibration?.trigger(VibrationPattern.danger);
  }

  /// Trigger haptic feedback based on priority
  void _triggerHaptic(InstructionPriority priority) {
    switch (priority) {
      case InstructionPriority.critical:
      case InstructionPriority.high:
        _vibration?.trigger(VibrationPattern.danger);
        break;
      case InstructionPriority.medium:
        _vibration?.trigger(VibrationPattern.warning);
        break;
      case InstructionPriority.low:
        _vibration?.trigger(VibrationPattern.sweepComplete);
        break;
      case InstructionPriority.none:
        break;
    }
  }

  /// Get zone name for display
  String getZoneName(int index) {
    const names = ['Hard Left', 'Left', 'Center', 'Right', 'Hard Right'];
    return names[index];
  }

  /// Get color for zone level
  String getZoneColor(int index) {
    switch (zoneLevels[index]) {
      case NavLevel.safe:
        return 'safe';
      case NavLevel.warning:
        return 'warning';
      case NavLevel.danger:
        return 'danger';
    }
  }
}

/// Navigation instruction priority levels
enum InstructionPriority { none, low, medium, high, critical }

/// Navigation danger levels
enum NavLevel { safe, warning, danger }
