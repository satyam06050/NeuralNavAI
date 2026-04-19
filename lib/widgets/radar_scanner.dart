import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_res.dart';
import '../models/radar_reading.dart';

class RadarScanner extends StatelessWidget {
  final RadarReading? currentReading;
  final List<RadarReading> readings;
  final int totalObjects;

  const RadarScanner({
    super.key,
    this.currentReading,
    required this.readings,
    this.totalObjects = 0,
  });

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RADAR SCAN',
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontSM,
                  fontWeight: FontWeight.bold,
                  color: AppRes.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppRes.spaceSM,
                  vertical: AppRes.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppRes.accentSafe.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRes.radiusSM),
                ),
                child: Text(
                  '$totalObjects OBJECTS',
                  style: const TextStyle(
                    fontFamily: AppRes.fontMono,
                    fontSize: AppRes.fontXS,
                    color: AppRes.accentSafe,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppRes.spaceMD),

          // Radar visualization
          AspectRatio(
            aspectRatio: 2 / 1,
            child: CustomPaint(
              painter: _RadarPainter(
                readings: readings,
                currentAngle: currentReading?.angle,
              ),
            ),
          ),

          const SizedBox(height: AppRes.spaceSM),

          // Current reading details
          if (currentReading != null && currentReading!.isValid) ...[
            Container(
              padding: const EdgeInsets.all(AppRes.spaceSM),
              decoration: BoxDecoration(
                color: _getStatusColor(
                  currentReading!.status,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRes.radiusSM),
                border: Border.all(
                  color: _getStatusColor(currentReading!.status),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'ANGLE',
                    '${currentReading!.angle}°',
                    Icons.rotate_90_degrees_ccw,
                  ),
                  _buildStatItem(
                    'DISTANCE',
                    '${currentReading!.distance!.toStringAsFixed(1)} cm',
                    Icons.straighten,
                  ),
                  _buildStatItem(
                    'STATUS',
                    _formatStatus(currentReading!.status),
                    Icons.info,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppRes.textSecondary),
        const SizedBox(height: AppRes.spaceXS),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppRes.fontMono,
            fontSize: AppRes.fontMD,
            fontWeight: FontWeight.bold,
            color: AppRes.textPrimary,
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

class _RadarPainter extends CustomPainter {
  final List<RadarReading> readings;
  final int? currentAngle;

  _RadarPainter({required this.readings, this.currentAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height;
    final radius = size.width / 2;

    // Draw background arc
    final bgPaint = Paint()
      ..color = AppRes.bgPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      3.14, // 180 degrees
      3.14, // 180 degrees sweep
      false,
      bgPaint,
    );

    // Draw angle markers
    for (int angle = 0; angle <= 180; angle += 30) {
      final radian = 3.14 + (angle * 3.14 / 180);
      final x = centerX + radius * math.cos(radian);
      final y = centerY + radius * math.sin(radian);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$angle°',
          style: const TextStyle(
            color: AppRes.textSecondary,
            fontSize: 10,
            fontFamily: AppRes.fontMono,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 15, y - 5));
    }

    // Draw distance rings
    for (int i = 1; i <= 3; i++) {
      final ringRadius = (radius / 3) * i;
      final ringPaint = Paint()
        ..color = AppRes.textSecondary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: ringRadius),
        3.14,
        3.14,
        false,
        ringPaint,
      );
    }

    // Draw readings
    for (final reading in readings) {
      if (!reading.isValid || reading.distance == null) continue;

      final radian = 3.14 + (reading.angle * 3.14 / 180);
      final normalizedDistance = (reading.distance! / 200).clamp(0.0, 1.0);
      final pointRadius = radius * normalizedDistance;

      final x = centerX + pointRadius * math.cos(radian);
      final y = centerY + pointRadius * math.sin(radian);

      final dotPaint = Paint()
        ..color = _getStatusColor(reading.status)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    // Draw current angle indicator
    if (currentAngle != null) {
      final radian = 3.14 + (currentAngle! * 3.14 / 180);
      final linePaint = Paint()
        ..color = AppRes.accentSafe
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(
          centerX + radius * math.cos(radian),
          centerY + radius * math.sin(radian),
        ),
        linePaint,
      );
    }
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

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}
