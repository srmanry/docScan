import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Speaker icon with two states: sound waves rippling outwards while
/// something is being read aloud, and a muted speaker (with a cross) when it
/// is not. Drawn rather than shipped as an SVG so the animation runs natively
/// and takes the icon colour.
class AnimatedSpeakerIcon extends StatefulWidget {
  final bool speaking;
  final double size;
  final Color color;

  const AnimatedSpeakerIcon({
    super.key,
    required this.speaking,
    required this.color,
    this.size = 24,
  });

  @override
  State<AnimatedSpeakerIcon> createState() => _AnimatedSpeakerIconState();
}

class _AnimatedSpeakerIconState extends State<AnimatedSpeakerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1367),
  );

  @override
  void initState() {
    super.initState();
    if (widget.speaking) _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedSpeakerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speaking == oldWidget.speaking) return;
    if (widget.speaking) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SpeakerPainter(
            progress: widget.speaking ? _controller.value : null,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _SpeakerPainter extends CustomPainter {
  /// 0–1 through the ripple loop, or null when the icon is at rest and both
  /// waves are simply drawn in full.
  final double? progress;
  final Color color;

  const _SpeakerPainter({required this.progress, required this.color});

  // When each wave starts and finishes fading in, matching the source
  // animation: the inner wave leads, the outer one follows.
  static const _innerStart = 0.0;
  static const _innerEnd = 0.366;
  static const _outerStart = 0.488;
  static const _outerEnd = 0.854;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cy = size.height / 2;

    _paintBody(canvas, s, cy);

    if (progress == null) {
      _paintMutedCross(canvas, s, cy);
      return;
    }

    _paintWave(
      canvas,
      s,
      cy,
      radius: 0.26,
      phase: _phase(_innerStart, _innerEnd),
    );
    _paintWave(
      canvas,
      s,
      cy,
      radius: 0.40,
      phase: _phase(_outerStart, _outerEnd),
    );
  }

  /// 0 = not shown yet, 1 = fully out.
  double _phase(double start, double end) {
    final t = progress;
    if (t == null) return 0;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return Curves.easeInOut.transform((t - start) / (end - start));
  }

  void _paintBody(Canvas canvas, double s, double cy) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(s * 0.35, cy - s * 0.30)
      ..lineTo(s * 0.20, cy - s * 0.11)
      ..lineTo(s * 0.07, cy - s * 0.11)
      ..lineTo(s * 0.07, cy + s * 0.11)
      ..lineTo(s * 0.20, cy + s * 0.11)
      ..lineTo(s * 0.35, cy + s * 0.30)
      ..close();

    // A round join keeps the cone's corners as soft as the rest of the UI.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.08
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, paint);
  }

  void _paintMutedCross(Canvas canvas, double s, double cy) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round;

    const cx = 0.66;
    const arm = 0.115;
    canvas.drawLine(
      Offset(s * (cx - arm), cy - s * arm),
      Offset(s * (cx + arm), cy + s * arm),
      paint,
    );
    canvas.drawLine(
      Offset(s * (cx + arm), cy - s * arm),
      Offset(s * (cx - arm), cy + s * arm),
      paint,
    );
  }

  void _paintWave(
    Canvas canvas,
    double s,
    double cy, {
    required double radius,
    required double phase,
  }) {
    if (phase <= 0) return;

    // Waves ease outwards and grow slightly as they appear.
    final r = s * radius * (0.88 + 0.12 * phase) + s * 0.03 * phase;
    final paint = Paint()
      ..color = color.withValues(alpha: phase.clamp(0, 1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.28, cy), radius: r),
      -math.pi / 4,
      math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpeakerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
