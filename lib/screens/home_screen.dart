import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart' as camera;
import '../app_res.dart';
import '../controllers/bluetooth_controller.dart';
import '../controllers/connection_mode_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/usb_controller.dart';
import '../controllers/camera_controller.dart';
import '../widgets/status_banner.dart';
import '../widgets/distance_card.dart';
import '../widgets/danger_overlay.dart';
import '../widgets/radar_scanner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppRes.appName),
        actions: [
          Obx(() {
            final modeCtrl = Get.find<ConnectionModeController>();
            final usbCtrl = Get.find<UsbController>();
            final btCtrl = Get.find<BluetoothController>();
            final isConn = modeCtrl.isUsb
                ? usbCtrl.connectedIndex.value >= 0
                : btCtrl.isConnected.value;
            final label = modeCtrl.isUsb
                ? (isConn ? AppRes.labelConnected : AppRes.labelDisconnected)
                : (isConn
                      ? AppRes.labelBtConnected
                      : AppRes.labelBtDisconnected);
            return Semantics(
              label: label,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppRes.spaceMD,
                  vertical: AppRes.spaceSM,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isConn ? AppRes.accentSafe : AppRes.accentDanger,
                    ),
                    const SizedBox(width: AppRes.spaceSM),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppRes.fontMono,
                        fontSize: AppRes.fontSM,
                        color: isConn ? AppRes.accentSafe : AppRes.accentDanger,
                      ),
                    ),
                    const SizedBox(width: AppRes.spaceSM),
                    const Icon(
                      Icons.power,
                      color: AppRes.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final showDanger =
            controller.isActive.value &&
            controller.distCenter < AppRes.thresholdDanger;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // Status Banner
                StatusBanner(
                  message: controller.guidance.value,
                  level: controller.navLevel.value,
                ),

                // Distance Sensor Panel
                Padding(
                  padding: const EdgeInsets.all(AppRes.spaceMD),
                  child: Row(
                    children: [
                      Expanded(
                        child: DistanceCard(
                          label: AppRes.labelLeft,
                          distance: controller.distLeft,
                        ),
                      ),
                      const SizedBox(width: AppRes.spaceSM),
                      Expanded(
                        child: DistanceCard(
                          label: AppRes.labelCenter,
                          distance: controller.distCenter,
                        ),
                      ),
                      const SizedBox(width: AppRes.spaceSM),
                      Expanded(
                        child: DistanceCard(
                          label: AppRes.labelRight,
                          distance: controller.distRight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Detected Object Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppRes.spaceMD,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppRes.spaceMD,
                      vertical: AppRes.detectedRowPadV,
                    ),
                    decoration: BoxDecoration(
                      color: AppRes.bgSurface,
                      borderRadius: BorderRadius.circular(AppRes.radiusSM),
                      border: Border.all(
                        color: AppRes.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          AppRes.labelDetected,
                          style: TextStyle(
                            fontFamily: AppRes.fontMono,
                            fontSize: AppRes.fontSM,
                            color: AppRes.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          label:
                              'Detected: ${_objLabel(controller.detectedObject.value)}',
                          child: Row(
                            children: [
                              Icon(
                                _objIcon(controller.detectedObject.value),
                                color: AppRes.textPrimary,
                                size: 22,
                              ),
                              const SizedBox(width: AppRes.spaceSM),
                              Text(
                                _objLabel(controller.detectedObject.value),
                                style: const TextStyle(
                                  fontFamily: AppRes.fontMono,
                                  fontSize: AppRes.fontLG,
                                  fontWeight: FontWeight.bold,
                                  color: AppRes.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppRes.spaceMD),

                // Radar Scanner Display
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppRes.spaceMD,
                  ),
                  child: Obx(
                    () => RadarScanner(
                      readings:
                          [], // Will be populated from controller when USB connected
                      currentReading: controller.currentReading.value,
                      totalObjects: controller.totalObjects.value,
                    ),
                  ),
                ),

                const SizedBox(height: AppRes.spaceMD),

                // Camera Feed
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppRes.spaceMD,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRes.radiusSM),
                    child: Container(
                      height: AppRes.cameraFeedHeight,
                      color: AppRes.bgSurface,
                      child: GetBuilder<CameraController>(
                        builder: (cameraCtrl) {
                          if (!cameraCtrl.isInitialized.value) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.no_photography,
                                    size: 64,
                                    color: AppRes.textSecondary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Initializing camera...',
                                    style: TextStyle(
                                      fontFamily: AppRes.fontMono,
                                      fontSize: AppRes.fontSM,
                                      color: AppRes.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (cameraCtrl.cameraController == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.no_photography,
                                    size: 64,
                                    color: AppRes.textSecondary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Camera unavailable',
                                    style: TextStyle(
                                      fontFamily: AppRes.fontMono,
                                      fontSize: AppRes.fontSM,
                                      color: AppRes.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => cameraCtrl
                                        .requestPermissionAndInitialize(),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Grant Permission'),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              Positioned.fill(
                                child: camera.CameraPreview(
                                  cameraCtrl.cameraController!,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppRes.spaceSM,
                                    vertical: AppRes.spaceXS,
                                  ),
                                  color: Colors.black54,
                                  child: const Text(
                                    AppRes.labelLiveFeed,
                                    style: TextStyle(
                                      fontFamily: AppRes.fontMono,
                                      fontSize: AppRes.fontXS,
                                      color: AppRes.textPrimary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 12,
                                child: _BlinkingScanning(),
                              ),
                              // Switch camera button
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.cameraswitch,
                                    color: AppRes.textPrimary,
                                  ),
                                  onPressed: () => cameraCtrl.switchCamera(),
                                  tooltip: 'Switch Camera',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (showDanger)
              Positioned.fill(
                child: DangerOverlay(distance: controller.distCenter),
              ),
          ],
        );
      }),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(
        () => SizedBox(
          width: 140,
          height: AppRes.minTouchTarget,
          child: FloatingActionButton.extended(
            onPressed: controller.toggleActive,
            backgroundColor: controller.isActive.value
                ? AppRes.accentSafe
                : AppRes.textSecondary,
            label: Text(
              controller.isActive.value ? AppRes.labelStop : AppRes.labelStart,
              style: const TextStyle(
                fontFamily: AppRes.fontMono,
                fontSize: AppRes.fontLG,
                fontWeight: FontWeight.bold,
                color: AppRes.bgPrimary,
                letterSpacing: 2,
              ),
            ),
            icon: Icon(
              controller.isActive.value ? Icons.stop : Icons.play_arrow,
              color: AppRes.bgPrimary,
            ),
          ),
        ),
      ),
    );
  }

  String _objLabel(DetectedObject obj) {
    switch (obj) {
      case DetectedObject.person:
        return AppRes.objPerson;
      case DetectedObject.vehicle:
        return AppRes.objVehicle;
      case DetectedObject.none:
        return AppRes.objNone;
    }
  }

  IconData _objIcon(DetectedObject obj) {
    switch (obj) {
      case DetectedObject.person:
        return Icons.person;
      case DetectedObject.vehicle:
        return Icons.directions_car;
      case DetectedObject.none:
        return Icons.remove;
    }
  }
}

class _BlinkingScanning extends StatefulWidget {
  @override
  State<_BlinkingScanning> createState() => _BlinkingScanningState();
}

class _BlinkingScanningState extends State<_BlinkingScanning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppRes.animPulse)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppRes.spaceSM,
          vertical: AppRes.spaceXS,
        ),
        color: Colors.black54,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppRes.accentSafe,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppRes.spaceSM),
            const Text(
              AppRes.labelScanning,
              style: TextStyle(
                fontFamily: AppRes.fontMono,
                fontSize: AppRes.fontXS,
                color: AppRes.accentSafe,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
