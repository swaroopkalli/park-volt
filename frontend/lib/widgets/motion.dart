import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// True when the user asked the OS/browser for reduced motion.
bool reduceMotion(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

Duration motion(BuildContext context, [int ms = 400]) => reduceMotion(context) ? Duration.zero : Duration(milliseconds: ms);

extension MotionX on Widget {
  /// Fade + slight scale in, optionally staggered by [index]. No-op under reduced motion.
  Widget enter(BuildContext context, {int index = 0, int stepMs = 40, int maxDelayMs = 400}) {
    if (reduceMotion(context)) return this;
    final delay = Duration(milliseconds: (index * stepMs).clamp(0, maxDelayMs));
    return animate(delay: delay).fadeIn(duration: 300.ms).scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1), duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

/// Lets mouse / trackpad drag-scroll lists on web and desktop, with smooth physics.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

/// Shimmering placeholder block used instead of spinners.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.height = 72, this.radius = 12});
  final double height, radius;
  @override
  Widget build(BuildContext context) {
    final box = Container(height: height, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(radius)));
    if (reduceMotion(context)) return box;
    return box.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white54);
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.height = 72});
  final int count;
  final double height;
  @override
  Widget build(BuildContext context) => Column(children: [for (var i = 0; i < count; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Skeleton(height: height))]);
}

/// Animated count-up that tweens between values instead of jumping.
class CountText extends StatelessWidget {
  const CountText({super.key, required this.value, this.decimals = 0, this.prefix = '', this.suffix = '', this.style});
  final double value;
  final int decimals;
  final String prefix, suffix;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: motion(context, 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

/// Soft glow ring used for the selected slot.
List<BoxShadow> glow(Color c, bool on) => on ? [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 2)] : const [];
