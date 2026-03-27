import 'package:vibration/vibration.dart';
import 'package:get/get.dart';

class VibrationService extends GetxService {
  final isEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkVibrationSupport();
  }

  Future<void> checkVibrationSupport() async {
    final hasVibrator = await Vibration.hasVibrator();
    isEnabled.value = hasVibrator ?? false;
  }

  /// Haptic feedback patterns based on aurdino.md section 7.6
  Future<void> trigger(VibrationPattern pattern) async {
    if (!isEnabled.value) return;

    try {
      switch (pattern) {
        case VibrationPattern.warning:
          // Long vibration 500ms for WARNING status (< 150 cm)
          await Vibration.vibrate(duration: 500);
          break;

        case VibrationPattern.danger:
          // Rapid double pulse for DANGER very close (< 50 cm)
          await Vibration.vibrate(pattern: [0, 200, 100, 200]);
          break;

        case VibrationPattern.newObject:
          // Triple short pulse for new object detected
          await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
          break;

        case VibrationPattern.sweepComplete:
          // Single short vibration for sweep complete, clear
          await Vibration.vibrate(duration: 200);
          break;

        case VibrationPattern.alert:
          // Strong alert pattern
          await Vibration.vibrate(pattern: [0, 300, 100, 300, 100, 300]);
          break;
      }
    } catch (e) {
      print('Vibration error: $e');
    }
  }

  /// Simple haptic click
  Future<void> click() async {
    if (!isEnabled.value) return;
    try {
      await Vibration.vibrate(duration: 50);
    } catch (_) {}
  }
}

enum VibrationPattern {
  warning, // < 150 cm
  danger, // < 50 cm
  newObject, // Object detected
  sweepComplete, // Sweep done
  alert, // General alert
}
