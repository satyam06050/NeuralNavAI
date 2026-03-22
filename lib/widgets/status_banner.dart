import 'package:flutter/material.dart';
import '../app_res.dart';
import '../controllers/nav_controller.dart';

class StatusBanner extends StatelessWidget {
  final String message;
  final NavLevel level;

  const StatusBanner({super.key, required this.message, required this.level});

  Color get _bgColor {
    switch (level) {
      case NavLevel.safe:    return AppRes.accentSafe;
      case NavLevel.caution: return AppRes.accentCaution;
      case NavLevel.danger:  return AppRes.accentDanger;
    }
  }

  Color get _textColor =>
      level == NavLevel.danger ? Colors.white : AppRes.bgPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Navigation status: $message',
      child: AnimatedContainer(
        duration: AppRes.animNormal,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppRes.spaceLG),
        color: _bgColor,
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontFamily: AppRes.fontMono,
              fontSize: AppRes.fontXL,
              fontWeight: FontWeight.bold,
              color: _textColor,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
