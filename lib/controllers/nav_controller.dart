import 'package:get/get.dart';
import '../app_res.dart';
import '../models/radar_reading.dart';
import '../services/tts_service.dart';
import '../services/vibration_service.dart';

enum NavLevel { safe, caution, danger }

enum DetectedObject { none, person, vehicle }

class NavController extends GetxController {
  final isConnected = false.obs;
  final isActive = false.obs;
  final distances = [
    0,
    0,
    0,
  ].obs; // [left, center, right] — zeroed until USB data arrives
  final detectedObject = DetectedObject.none.obs;
  final guidance = AppRes.msgPathClear.obs;
  final navLevel = NavLevel.safe.obs;

  // New radar-specific state
  final currentReading = Rxn<RadarReading>();
  final totalObjects = 0.obs;
  final lastObjectAngle = 0.obs;

  int get distLeft => distances[0];
  int get distCenter => distances[1];
  int get distRight => distances[2];

  // Get services
  TtsService? get _tts => Get.find<TtsService>();
  VibrationService? get _vibration => Get.find<VibrationService>();

  void toggleActive() => isActive.value = !isActive.value;

  void updateDistances(List<int> d) {
    distances.value = d;
    _computeGuidance();
  }

  /// Handle individual radar angle reading
  void onRadarReading(RadarReading reading) {
    currentReading.value = reading;

    if (!isActive.value || !reading.isValid) return;

    // Trigger haptic and voice feedback based on status
    if (reading.status == RadarStatus.warning) {
      _triggerWarning(reading);
    } else if (reading.status == RadarStatus.safe && reading.distance != null) {
      if (reading.distance! < AppRes.thresholdDanger) {
        _triggerDanger(reading);
      } else if (reading.distance! < AppRes.thresholdCaution) {
        _triggerWarning(reading);
      }
    }
  }

  /// Handle object detection event
  void onObjectDetected(int objectNumber) {
    totalObjects.value = objectNumber;

    if (!isActive.value) return;

    // Trigger vibration for new object
    _vibration?.trigger(VibrationPattern.newObject);

    // Voice announcement
    final reading = currentReading.value;
    if (reading != null && reading.isValid) {
      _tts?.speak(
        'Object number $objectNumber detected at ${reading.angle} degrees, '
        '${reading.distance!.toInt()} centimeters',
      );
    } else {
      _tts?.speak('Object number $objectNumber detected');
    }
  }

  /// Handle sweep complete
  void onSweepComplete(int totalObjectsCount) {
    totalObjects.value = totalObjectsCount;

    if (!isActive.value) return;

    if (totalObjectsCount > 0) {
      _tts?.speak('Scan complete. $totalObjectsCount objects detected.');
    } else {
      _tts?.speak('Area is clear. Safe to move.');
      _vibration?.trigger(VibrationPattern.sweepComplete);
    }
  }

  void _triggerWarning(RadarReading reading) {
    if (reading.distance == null) return;

    // Haptic feedback
    _vibration?.trigger(VibrationPattern.warning);

    // Voice warning
    if (reading.distance! < AppRes.closeAlertRange) {
      _tts?.speak(
        'Warning! Object very close, ${reading.distance!.toInt()} centimeters ahead',
      );
    } else {
      _tts?.speak(
        'Caution, object at ${reading.distance!.toInt()} centimeters',
      );
    }
  }

  void _triggerDanger(RadarReading reading) {
    if (reading.distance == null) return;

    // Strong haptic alert
    _vibration?.trigger(VibrationPattern.danger);

    // Urgent voice warning
    _tts?.speak(
      'Danger! Stop! Object at ${reading.distance!.toInt()} centimeters',
      immediate: true,
    );
  }

  void _computeGuidance() {
    final c = distCenter;
    if (c < AppRes.thresholdDanger) {
      guidance.value = AppRes.msgDangerAhead;
      navLevel.value = NavLevel.danger;
    } else if (c < AppRes.thresholdCaution) {
      guidance.value = AppRes.msgSlowDown;
      navLevel.value = NavLevel.caution;
    } else {
      guidance.value = AppRes.msgPathClear;
      navLevel.value = NavLevel.safe;
    }
  }
}
