import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_res.dart';
import '../controllers/nav_controller.dart';
import '../controllers/usb_controller.dart';
import '../models/radar_reading.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavController>();
    final usbCtrl = Get.find<UsbController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ARDUINO DATA'),
        actions: [
          Obx(() {
            final isConnected = usbCtrl.connectedIndex.value >= 0;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppRes.spaceMD,
                vertical: AppRes.spaceSM,
              ),
              margin: const EdgeInsets.all(AppRes.spaceSM),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppRes.accentSafe.withValues(alpha: 0.2)
                    : AppRes.accentDanger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRes.radiusSM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isConnected
                        ? AppRes.accentSafe
                        : AppRes.accentDanger,
                  ),
                  const SizedBox(width: AppRes.spaceSM),
                  Text(
                    isConnected ? 'CONNECTED' : 'DISCONNECTED',
                    style: TextStyle(
                      fontFamily: AppRes.fontMono,
                      fontSize: AppRes.fontXS,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? AppRes.accentSafe
                          : AppRes.accentDanger,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppRes.spaceMD),
        children: [
          // Connection Status Card
          _ConnectionStatusCard(),

          const SizedBox(height: AppRes.spaceMD),

          // Distance Sensors Card
          _DistanceSensorsCard(controller: controller),

          const SizedBox(height: AppRes.spaceMD),

          // Radar Reading Card
          _RadarReadingCard(controller: controller),

          const SizedBox(height: AppRes.spaceMD),

          // Object Detection Card
          _ObjectDetectionCard(controller: controller),

          const SizedBox(height: AppRes.spaceMD),

          // Raw Data Log Card
          _RawDataLogCard(),

          const SizedBox(height: AppRes.spaceLG),

          // Info Footer
          Container(
            padding: const EdgeInsets.all(AppRes.spaceMD),
            decoration: BoxDecoration(
              color: AppRes.bgSurface,
              borderRadius: BorderRadius.circular(AppRes.radiusSM),
              border: Border.all(color: AppRes.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATA REFRESH RATE',
                  style: TextStyle(
                    fontFamily: AppRes.fontMono,
                    fontSize: AppRes.fontXS,
                    color: AppRes.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppRes.spaceXS),
                const Text(
                  'Updates in real-time from Arduino',
                  style: TextStyle(
                    fontFamily: AppRes.fontMono,
                    fontSize: AppRes.fontSM,
                    color: AppRes.textPrimary,
                  ),
                ),
                const Divider(height: 32, color: AppRes.borderColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('BAUD RATE', '9600'),
                    _buildInfoItem('ANGLE STEP', '${AppRes.angleStep}°'),
                    _buildInfoItem(
                      'THRESHOLD',
                      '${AppRes.detectionThreshold}cm',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontLG,
            fontWeight: FontWeight.bold,
            color: AppRes.accentSafe,
          ),
        ),
        const SizedBox(height: AppRes.spaceXS),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontXS,
            color: AppRes.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// CONNECTION STATUS CARD
// ──────────────────────────────────────────────────────────────

class _ConnectionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final usbCtrl = Get.find<UsbController>();

    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusMD),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.usb, color: AppRes.textSecondary, size: 20),
              const SizedBox(width: AppRes.spaceSM),
              const Text(
                'CONNECTION STATUS',
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  fontWeight: FontWeight.bold,
                  color: AppRes.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppRes.spaceMD),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow(
                  'Device',
                  usbCtrl.devices.isEmpty
                      ? 'None'
                      : usbCtrl.connectedIndex.value >= 0
                      ? 'USB Device #${usbCtrl.connectedIndex.value + 1}'
                      : 'Not connected',
                ),
                const SizedBox(height: AppRes.spaceSM),
                _buildStatusRow('Status', usbCtrl.statusText.value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontSM,
            color: AppRes.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontSM,
              color: AppRes.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// DISTANCE SENSORS CARD
// ──────────────────────────────────────────────────────────────

class _DistanceSensorsCard extends StatelessWidget {
  final NavController controller;

  const _DistanceSensorsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusMD),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: AppRes.textSecondary, size: 20),
              const SizedBox(width: AppRes.spaceSM),
              const Text(
                'DISTANCE SENSORS (cm)',
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  fontWeight: FontWeight.bold,
                  color: AppRes.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppRes.spaceLG),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDistanceIndicator(
                  'LEFT',
                  controller.distLeft,
                  Icons.arrow_back,
                ),
                _buildDistanceIndicator(
                  'CENTER',
                  controller.distCenter,
                  Icons.arrow_upward,
                ),
                _buildDistanceIndicator(
                  'RIGHT',
                  controller.distRight,
                  Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceIndicator(String label, int distance, IconData icon) {
    final isDanger = distance < AppRes.thresholdDanger && distance > 0;
    final isCaution =
        distance >= AppRes.thresholdDanger &&
        distance < AppRes.thresholdCaution &&
        distance > 0;

    return Column(
      children: [
        Icon(
          icon,
          color: isDanger
              ? AppRes.accentDanger
              : isCaution
              ? AppRes.accentCaution
              : AppRes.textSecondary,
          size: 28,
        ),
        const SizedBox(height: AppRes.spaceSM),
        Text(
          '$distance',
          style: TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontXL,
            fontWeight: FontWeight.bold,
            color: isDanger
                ? AppRes.accentDanger
                : isCaution
                ? AppRes.accentCaution
                : AppRes.textPrimary,
          ),
        ),
        const SizedBox(height: AppRes.spaceXS),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontXS,
            color: AppRes.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// RADAR READING CARD
// ──────────────────────────────────────────────────────────────

class _RadarReadingCard extends StatelessWidget {
  final NavController controller;

  const _RadarReadingCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusMD),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, color: AppRes.textSecondary, size: 20),
              const SizedBox(width: AppRes.spaceSM),
              const Text(
                'CURRENT RADAR READING',
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  fontWeight: FontWeight.bold,
                  color: AppRes.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppRes.spaceMD),
          Obx(() {
            final reading = controller.currentReading.value;
            if (reading == null || !reading.isValid) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppRes.spaceLG),
                  child: Text(
                    'No radar data received',
                    style: TextStyle(
                      fontFamily: AppRes.fontMono,
                      fontSize: AppRes.fontSM,
                      color: AppRes.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                _buildReadingRow('ANGLE', '${reading.angle}°'),
                const SizedBox(height: AppRes.spaceSM),
                _buildReadingRow(
                  'DISTANCE',
                  '${reading.distance!.toStringAsFixed(1)} cm',
                ),
                const SizedBox(height: AppRes.spaceSM),
                _buildReadingRow(
                  'STATUS',
                  _formatStatus(reading.status),
                  statusColor: _getStatusColor(reading.status),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReadingRow(String label, String value, {Color? statusColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppRes.spaceMD,
        vertical: AppRes.spaceSM,
      ),
      decoration: BoxDecoration(
        color: statusColor?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRes.radiusSM),
        border: statusColor != null
            ? Border.all(color: statusColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontSM,
              color: AppRes.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontMD,
              fontWeight: FontWeight.bold,
              color: statusColor ?? AppRes.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RadarStatus status) {
    switch (status) {
      case RadarStatus.safe:
        return AppRes.accentSafe;
      case RadarStatus.warning:
        return AppRes.accentCaution;
      case RadarStatus.invalid:
        return AppRes.textSecondary;
    }
  }

  String _formatStatus(RadarStatus status) {
    switch (status) {
      case RadarStatus.safe:
        return 'SAFE';
      case RadarStatus.warning:
        return 'WARNING';
      case RadarStatus.invalid:
        return 'INVALID';
    }
  }
}

// ──────────────────────────────────────────────────────────────
// OBJECT DETECTION CARD
// ──────────────────────────────────────────────────────────────

class _ObjectDetectionCard extends StatelessWidget {
  final NavController controller;

  const _ObjectDetectionCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusMD),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: AppRes.textSecondary, size: 20),
              const SizedBox(width: AppRes.spaceSM),
              const Text(
                'OBJECT DETECTION',
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  fontWeight: FontWeight.bold,
                  color: AppRes.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppRes.spaceLG),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  'TOTAL OBJECTS',
                  '${controller.totalObjects.value}',
                  Icons.list,
                ),
                _buildStatBox(
                  'LAST ANGLE',
                  '${controller.lastObjectAngle.value}°',
                  Icons.rotate_90_degrees_ccw,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppRes.accentSafe, size: 32),
        const SizedBox(height: AppRes.spaceSM),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontXXL,
            fontWeight: FontWeight.bold,
            color: AppRes.accentSafe,
          ),
        ),
        const SizedBox(height: AppRes.spaceSM),
        SizedBox(
          width: 100,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontXS,
              color: AppRes.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// RAW DATA LOG CARD
// ──────────────────────────────────────────────────────────────

class _RawDataLogCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusMD),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: AppRes.textSecondary, size: 20),
              const SizedBox(width: AppRes.spaceSM),
              const Text(
                'RAW DATA STREAM',
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  fontWeight: FontWeight.bold,
                  color: AppRes.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppRes.spaceMD),
          Container(
            padding: const EdgeInsets.all(AppRes.spaceMD),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(AppRes.radiusSM),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '// Live Arduino serial data will appear here',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: AppRes.fontSM,
                    color: AppRes.textSecondary,
                  ),
                ),
                SizedBox(height: AppRes.spaceSM),
                Text(
                  '// Format examples:',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: AppRes.fontSM,
                    color: AppRes.textSecondary,
                  ),
                ),
                Text(
                  '// Angle: 45  | Distance: 32.5 cm  | Status: WARNING',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: AppRes.fontSM,
                    color: AppRes.accentCaution,
                  ),
                ),
                Text(
                  '// *** OBJECT #1 DETECTED! ***',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: AppRes.fontSM,
                    color: AppRes.accentSafe,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
