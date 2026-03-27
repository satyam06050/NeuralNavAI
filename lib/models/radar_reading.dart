class RadarReading {
  final int angle;
  final double? distance;
  final RadarStatus status;

  RadarReading({required this.angle, this.distance, required this.status});

  bool get isValid => distance != null && status != RadarStatus.invalid;
  bool get isWarning => status == RadarStatus.warning;
  bool get isSafe => status == RadarStatus.safe;

  @override
  String toString() =>
      'RadarReading(angle: $angle, distance: ${distance ?? "---"}, status: $status)';
}

enum RadarStatus { safe, warning, invalid }

class RadarSweep {
  final List<RadarReading> readings;
  final int totalObjects;
  final DateTime timestamp;

  RadarSweep({
    required this.readings,
    this.totalObjects = 0,
    required this.timestamp,
  });

  /// Get reading for a specific angle
  RadarReading? getByAngle(int angle) {
    try {
      return readings.firstWhere((r) => r.angle == angle);
    } catch (_) {
      return null;
    }
  }

  /// Get closest object distance and angle
  Map<String, dynamic>? getClosestObject() {
    final validReadings = readings
        .where((r) => r.isValid && r.distance != null)
        .toList();
    if (validReadings.isEmpty) return null;

    final closest = validReadings.reduce(
      (a, b) => (a.distance! < b.distance!) ? a : b,
    );

    return {
      'angle': closest.angle,
      'distance': closest.distance,
      'status': closest.status,
    };
  }

  /// Check if path is clear (all readings are safe)
  bool get isPathClear => readings.every((r) => r.isSafe || !r.isValid);
}
