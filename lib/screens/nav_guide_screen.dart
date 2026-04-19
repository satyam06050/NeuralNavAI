import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_res.dart';
import '../controllers/nav_guide_controller.dart';

/// Navigation Guidance Screen
/// Displays zone-based obstacle detection and navigation instructions
/// Based on guide.md specifications
class NavGuideScreen extends StatelessWidget {
  const NavGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavGuideController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAVIGATION GUIDE'),
        actions: [
          // Active toggle button
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isActive.value
                    ? Icons.play_circle_filled
                    : Icons.play_circle_outline,
                color: controller.isActive.value
                    ? AppRes.accentSafe
                    : AppRes.textSecondary,
              ),
              onPressed: () => controller.toggleActive(),
              tooltip: controller.isActive.value
                  ? 'Stop Guidance'
                  : 'Start Guidance',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppRes.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection & Status
                _buildStatusSection(controller),

                const SizedBox(height: AppRes.spaceLG),

                // Zone Visualization
                _buildZoneVisualization(controller),

                const SizedBox(height: AppRes.spaceLG),

                // Distance Cards
                _buildDistanceCards(controller),

                const SizedBox(height: AppRes.spaceLG),

                // Navigation Instruction
                _buildInstructionCard(controller),

                const SizedBox(height: AppRes.spaceXL),

                // Info Section
                _buildInfoSection(),
              ],
            ),
          ),

          // Floating Navigation Audio Button at bottom right
          Positioned(
            right: AppRes.spaceMD,
            bottom: AppRes.spaceMD,
            child: FloatingActionButton.extended(
              onPressed: () {
                controller.testNavigationSpeech();
              },
              backgroundColor: AppRes.accentSafe,
              foregroundColor: AppRes.bgPrimary,
              icon: const Icon(Icons.navigation),
              label: const Text(
                'NAVIGATION AUDIO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(NavGuideController controller) {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface,
        borderRadius: BorderRadius.circular(AppRes.radiusMD),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Row(
        children: [
          // Connection indicator
          Obx(
            () => Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: controller.isConnected.value
                    ? AppRes.accentSafe
                    : AppRes.accentDanger,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppRes.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARDUINO RADAR',
                  style: TextStyle(
                    fontSize: AppRes.fontSM,
                    fontWeight: FontWeight.bold,
                    color: AppRes.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.isConnected.value
                        ? AppRes.labelConnected
                        : AppRes.labelDisconnected,
                    style: TextStyle(
                      fontSize: AppRes.fontXS,
                      color: controller.isConnected.value
                          ? AppRes.accentSafe
                          : AppRes.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Active status
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppRes.spaceSM,
                vertical: AppRes.spaceXS,
              ),
              decoration: BoxDecoration(
                color: controller.isActive.value
                    ? AppRes.accentSafe.withOpacity(0.2)
                    : AppRes.bgSurface,
                borderRadius: BorderRadius.circular(AppRes.radiusSM),
                border: Border.all(
                  color: controller.isActive.value
                      ? AppRes.accentSafe
                      : AppRes.borderColor,
                ),
              ),
              child: Text(
                controller.isActive.value ? 'ACTIVE' : 'STANDBY',
                style: TextStyle(
                  fontSize: AppRes.fontXS,
                  fontWeight: FontWeight.bold,
                  color: controller.isActive.value
                      ? AppRes.accentSafe
                      : AppRes.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneVisualization(NavGuideController controller) {
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
          Text(
            'ZONE VISUALIZATION',
            style: TextStyle(
              fontSize: AppRes.fontSM,
              fontWeight: FontWeight.bold,
              color: AppRes.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppRes.spaceMD),

          // Arc visualization with 5 zones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildZoneIndicator(controller, 0, 'HARD LEFT'),
              _buildZoneIndicator(controller, 1, 'LEFT'),
              _buildZoneIndicator(controller, 2, 'CENTER'),
              _buildZoneIndicator(controller, 3, 'RIGHT'),
              _buildZoneIndicator(controller, 4, 'HARD RIGHT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneIndicator(
    NavGuideController controller,
    int index,
    String label,
  ) {
    return Obx(() {
      final level = controller.zoneLevels[index];
      final distance = controller.zoneDistances[index];

      Color bgColor;
      Color borderColor;
      if (level == NavLevel.danger) {
        bgColor = AppRes.accentDanger.withOpacity(0.2);
        borderColor = AppRes.accentDanger;
      } else if (level == NavLevel.warning) {
        bgColor = AppRes.accentCaution.withOpacity(0.2);
        borderColor = AppRes.accentCaution;
      } else {
        bgColor = AppRes.accentSafe.withOpacity(0.2);
        borderColor = AppRes.accentSafe;
      }

      return Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: distance >= 999
                  ? Icon(Icons.check, color: borderColor, size: 28)
                  : Text(
                      '${distance}cm',
                      style: TextStyle(
                        fontSize: AppRes.fontXS,
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          const SizedBox(height: AppRes.spaceXS),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: AppRes.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  Widget _buildDistanceCards(NavGuideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ZONE DISTANCES',
          style: TextStyle(
            fontSize: AppRes.fontSM,
            fontWeight: FontWeight.bold,
            color: AppRes.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppRes.spaceSM),

        Row(
          children: [
            Expanded(child: _buildDistanceCard(controller, 0, 'HARD LEFT')),
            const SizedBox(width: AppRes.spaceSM),
            Expanded(child: _buildDistanceCard(controller, 1, 'LEFT')),
            Expanded(child: _buildDistanceCard(controller, 2, 'CENTER')),
            const SizedBox(width: AppRes.spaceSM),
            Expanded(child: _buildDistanceCard(controller, 3, 'RIGHT')),
            Expanded(child: _buildDistanceCard(controller, 4, 'HARD RIGHT')),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceCard(
    NavGuideController controller,
    int index,
    String label,
  ) {
    return Obx(() {
      final distance = controller.zoneDistances[index];
      final level = controller.zoneLevels[index];

      Color textColor;
      IconData icon;

      if (level == NavLevel.danger) {
        textColor = AppRes.accentDanger;
        icon = Icons.warning_rounded;
      } else if (level == NavLevel.warning) {
        textColor = AppRes.accentCaution;
        icon = Icons.info_rounded;
      } else {
        textColor = AppRes.accentSafe;
        icon = Icons.check_circle_outline_rounded;
      }

      return Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppRes.spaceSM,
          horizontal: AppRes.spaceXS,
        ),
        decoration: BoxDecoration(
          color: AppRes.bgSurface,
          borderRadius: BorderRadius.circular(AppRes.radiusSM),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              distance >= 999 ? 'CLEAR' : '${distance}cm',
              style: TextStyle(
                fontSize: AppRes.fontSM,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.split(' ')[0], // Just first word
              style: TextStyle(fontSize: 9, color: AppRes.textSecondary),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInstructionCard(NavGuideController controller) {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppRes.bgSurface, AppRes.bgSurface.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRes.radiusLG),
        border: Border.all(color: AppRes.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.navigation_rounded,
                color: AppRes.textPrimary,
                size: 24,
              ),
              const SizedBox(width: AppRes.spaceSM),
              Text(
                'NAVIGATION INSTRUCTION',
                style: TextStyle(
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
            () => Text(
              controller.currentInstruction.value.isEmpty
                  ? AppRes.labelWaiting
                  : controller.currentInstruction.value,
              style: TextStyle(
                fontSize: AppRes.fontXL,
                fontWeight: FontWeight.bold,
                color: _getInstructionColor(controller),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getInstructionColor(NavGuideController controller) {
    final priority = controller.instructionPriority.value;
    if (priority == InstructionPriority.critical ||
        priority == InstructionPriority.high) {
      return AppRes.accentDanger;
    } else if (priority == InstructionPriority.medium) {
      return AppRes.accentCaution;
    } else if (priority == InstructionPriority.low) {
      return AppRes.accentSafe;
    } else {
      return AppRes.textSecondary;
    }
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(AppRes.spaceMD),
      decoration: BoxDecoration(
        color: AppRes.bgSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRes.radiusSM),
        border: Border.all(color: AppRes.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZONE MAPPING (0°-180°)',
            style: TextStyle(
              fontSize: AppRes.fontSM,
              fontWeight: FontWeight.bold,
              color: AppRes.textPrimary,
            ),
          ),
          const SizedBox(height: AppRes.spaceSM),
          _buildInfoRow('Hard Left:', '0° - 30°'),
          _buildInfoRow('Left:', '35° - 70°'),
          _buildInfoRow('Center:', '75° - 105°'),
          _buildInfoRow('Right:', '110° - 145°'),
          _buildInfoRow('Hard Right:', '150° - 180°'),
          const SizedBox(height: AppRes.spaceMD),
          Text(
            'DISTANCE THRESHOLDS',
            style: TextStyle(
              fontSize: AppRes.fontSM,
              fontWeight: FontWeight.bold,
              color: AppRes.textPrimary,
            ),
          ),
          const SizedBox(height: AppRes.spaceSM),
          _buildInfoRow('Safe:', '> 250 cm', color: AppRes.accentSafe),
          _buildInfoRow('Warning:', '100-250 cm', color: AppRes.accentCaution),
          _buildInfoRow('Danger:', '< 100 cm', color: AppRes.accentDanger),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppRes.spaceXS),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppRes.fontXS,
              color: AppRes.textSecondary,
            ),
          ),
          const SizedBox(width: AppRes.spaceSM),
          Text(
            value,
            style: TextStyle(
              fontSize: AppRes.fontXS,
              fontWeight: FontWeight.bold,
              color: color ?? AppRes.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
