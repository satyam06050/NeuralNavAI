import 'package:flutter/material.dart';
import '../app_res.dart';

class DistanceCard extends StatelessWidget {
  final String label;
  final int distance;
  final int maxDistance;

  const DistanceCard({
    super.key,
    required this.label,
    required this.distance,
    this.maxDistance = AppRes.maxDistance,
  });

  Color get _barColor {
    if (distance >= AppRes.thresholdCaution) return AppRes.accentSafe;
    if (distance >= AppRes.thresholdDanger)  return AppRes.accentCaution;
    return AppRes.accentDanger;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (distance / maxDistance).clamp(0.0, 1.0);
    return Semantics(
      label: '$label distance $distance centimeters',
      child: Container(
        padding: const EdgeInsets.all(AppRes.spaceSM + 4),
        decoration: BoxDecoration(
          color: AppRes.bgSurface,
          borderRadius: BorderRadius.circular(AppRes.radiusSM),
          border: Border.all(
              color: AppRes.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppRes.fontMono,
                fontSize: AppRes.fontXS,
                color: AppRes.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppRes.spaceXS + 2),
            Text(
              '${distance}cm',
              style: TextStyle(
                fontFamily: AppRes.fontMono,
                fontSize: AppRes.fontLG + 2,
                fontWeight: FontWeight.bold,
                color: _barColor,
              ),
            ),
            const SizedBox(height: AppRes.spaceSM),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: AppRes.animNormal,
              builder: (_, value, __) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor:
                      AppRes.textSecondary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(_barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
