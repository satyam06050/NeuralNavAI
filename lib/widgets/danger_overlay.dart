import 'package:flutter/material.dart';
import '../app_res.dart';

class DangerOverlay extends StatefulWidget {
  final int distance;
  const DangerOverlay({super.key, required this.distance});

  @override
  State<DangerOverlay> createState() => _DangerOverlayState();
}

class _DangerOverlayState extends State<DangerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppRes.animPulse)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${AppRes.msgDangerAhead}, ${widget.distance} centimeters',
      child: Container(
        color: AppRes.overlayRed,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 96,
                ),
              ),
              const SizedBox(height: AppRes.spaceLG),
              const Text(
                AppRes.msgDangerAhead,
                style: TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontXXL - 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppRes.spaceSM),
              Text(
                '${widget.distance}cm',
                style: const TextStyle(
                  fontFamily: AppRes.fontMono,
                  fontSize: AppRes.fontXL,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
