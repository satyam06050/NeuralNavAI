import 'package:get/get.dart';
import '../app_res.dart';

class SettingsController extends GetxController {
  final ttsSpeed    = AppRes.ttsSpeedDefault.obs;
  final ttsVolume   = AppRes.ttsVolumeDefault.obs;
  final repeatMsg   = false.obs;
  final cooldown    = AppRes.ttsCooldownSec.obs;
  final dangerDist  = AppRes.thresholdDanger.obs;
  final cautionDist = AppRes.thresholdCaution.obs;
  final vibration   = true.obs;
  final camera      = true.obs;
}
