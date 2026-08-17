import 'package:flutter/material.dart';
import 'package:doc_sense/core/theme/app_theme.dart';
import 'package:doc_sense/features/document/presentation/widgets/document_scan_animation.dart';

const _steps = ['Reading file', 'Detecting language', 'Extracting text', 'Preparing AI tools'];

/// Cloud Vision/Gemini calls are single request/response — there's no real
/// per-step progress signal to observe. This animates toward a capped 92%
/// over a plausible duration so it never claims "done" before the actual
/// result (handled by whatever pushes the next page) arrives.
class ScanningProgressView extends StatefulWidget {
  const ScanningProgressView({super.key});

  @override
  State<ScanningProgressView> createState() => _ScanningProgressViewState();
}

class _ScanningProgressViewState extends State<ScanningProgressView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7));
    _progress = Tween<double>(begin: 0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final percent = (_progress.value * 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DocumentScanAnimation(),
                const SizedBox(height: 24),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppColors.buntOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _progress.value,
                    minHeight: 8,
                    backgroundColor: AppColors.softBorder,
                    valueColor: const AlwaysStoppedAnimation(AppColors.buntOrange),
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('What Docora is doing', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _steps.length; i++) ...[
                  _StepRow(label: _steps[i], status: _statusFor(i, _progress.value)),
                  if (i != _steps.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  _StepStatus _statusFor(int index, double progress) {
    final thresholds = List.generate(_steps.length, (i) => (i + 1) / _steps.length);
    if (progress >= thresholds[index]) return _StepStatus.done;
    final firstIncomplete = thresholds.indexWhere((t) => progress < t);
    if (index == firstIncomplete) return _StepStatus.inProgress;
    return _StepStatus.next;
  }
}

enum _StepStatus { done, inProgress, next }

class _StepRow extends StatelessWidget {
  final String label;
  final _StepStatus status;
  const _StepRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color dot, String statusText, Color statusColor) = switch (status) {
      _StepStatus.done => (const Color(0xFF2FA84F), 'Done', const Color(0xFF2FA84F)),
      _StepStatus.inProgress => (AppColors.buntOrange, 'In progress', AppColors.buntOrange),
      _StepStatus.next => (AppColors.ink.withValues(alpha: 0.3), 'Next', AppColors.ink.withValues(alpha: 0.4)),
    };

    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: status == _StepStatus.next ? AppColors.ink.withValues(alpha: 0.5) : AppColors.ink,
            ),
          ),
        ),
        Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
