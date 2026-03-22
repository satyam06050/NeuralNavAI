import 'package:get/get.dart';
import '../app_res.dart';

enum NavLevel { safe, caution, danger }
enum DetectedObject { none, person, vehicle }

class NavController extends GetxController {
  final isConnected    = false.obs;
  final isActive       = false.obs;
  final distances      = [120, 45, 80].obs; // [left, center, right]
  final detectedObject = DetectedObject.none.obs;
  final guidance       = AppRes.msgPathClear.obs;
  final navLevel       = NavLevel.safe.obs;

  int get distLeft   => distances[0];
  int get distCenter => distances[1];
  int get distRight  => distances[2];

  void toggleActive() => isActive.value = !isActive.value;

  void updateDistances(List<int> d) {
    distances.value = d;
    _computeGuidance();
  }

  void _computeGuidance() {
    final c = distCenter;
    if (c < AppRes.thresholdDanger) {
      guidance.value  = AppRes.msgDangerAhead;
      navLevel.value  = NavLevel.danger;
    } else if (c < AppRes.thresholdCaution) {
      guidance.value  = AppRes.msgSlowDown;
      navLevel.value  = NavLevel.caution;
    } else {
      guidance.value  = AppRes.msgPathClear;
      navLevel.value  = NavLevel.safe;
    }
  }
}
