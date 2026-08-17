import 'package:flutter/material.dart';
import 'package:doc_sense/core/theme/app_theme.dart';

/// A document icon with a viewfinder frame and a scan-line sweeping up and
/// down it — the classic "scanning" visual, built with plain Flutter
/// animations (no external asset needed).
class DocumentScanAnimation extends StatefulWidget {
  const DocumentScanAnimation({super.key});

  @override
  State<DocumentScanAnimation> createState() => _DocumentScanAnimationState();
}

class _DocumentScanAnimationState extends State<DocumentScanAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _size = Size(110, 132);
  static const _bracketLength = 18.0;
  static const _bracketThickness = 3.0;
  static const _inset = 6.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size.width,
      height: _size.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _size.width - _inset * 3,
            height: _size.height - _inset * 3,
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: const Icon(Icons.description_rounded, color: AppColors.coralGlass, size: 44),
          ),
          for (final alignment in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(alignment: alignment, child: _CornerBracket(alignment: alignment)),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final top = _inset + _controller.value * (_size.height - _inset * 2 - 4);
              return Positioned(
                top: top,
                left: _inset,
                right: _inset,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, AppColors.buntOrange, Colors.transparent],
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.buntOrange.withValues(alpha: 0.6), blurRadius: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final Alignment alignment;
  const _CornerBracket({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    const length = _DocumentScanAnimationState._bracketLength;
    const thickness = _DocumentScanAnimationState._bracketThickness;

    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: length, height: thickness, color: AppColors.buntOrange),
          ),
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: Container(width: thickness, height: length, color: AppColors.buntOrange),
          ),
        ],
      ),
    );
  }
}
