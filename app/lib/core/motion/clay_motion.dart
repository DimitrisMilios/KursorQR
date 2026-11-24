import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Spring presets (stiffness / damping / mass). Use these everywhere instead of
/// raw curve durations on interactive controls.
class ClaySprings {
  const ClaySprings._();

  /// Press sink, hover lift, field focus, toggle tracks.
  static const snappy = SpringDescription(mass: 1, stiffness: 520, damping: 32);

  /// Release overshoot, dialogs, toasts, popovers, pucks.
  static const bouncy = SpringDescription(mass: 1, stiffness: 300, damping: 18);

  /// Jelly release wobble and leading edge of liquid-stretching pucks.
  static const liquid = SpringDescription(mass: 1, stiffness: 180, damping: 14);

  /// Panel entrances, hero tilt, progress bars.
  static const gentle = SpringDescription(mass: 1, stiffness: 160, damping: 24);

  /// Critically damped fallback when reduced motion is enabled.
  static const still = SpringDescription(mass: 1, stiffness: 520, damping: 60);
}

class ClayDurations {
  const ClayDurations._();

  static const press = Duration(milliseconds: 90);
  static const hover = Duration(milliseconds: 140);
  static const stagger = Duration(milliseconds: 35);
  static const crossfade = Duration(milliseconds: 180);
  static const toast = Duration(seconds: 3);
}

/// Drives an [AnimationController] with a physics spring. Interruptible:
/// calling again mid-flight redirects seamlessly from current value & velocity.
extension SpringTo on AnimationController {
  TickerFuture springTo(
    double target, {
    SpringDescription spring = ClaySprings.snappy,
    double? velocity,
  }) {
    final sim = SpringSimulation(
      spring,
      value,
      target,
      velocity ?? this.velocity,
    );
    return animateWith(sim);
  }
}

/// A [Curve] sampled from a [SpringSimulation] for route transitions and
/// implicit widgets that accept a [Curve].
class ClaySpringCurve extends Curve {
  ClaySpringCurve(
    this.spring, {
    this.settleDuration = const Duration(milliseconds: 500),
  }) : _sim = SpringSimulation(spring, 0, 1, 0);

  final SpringDescription spring;
  final Duration settleDuration;
  final SpringSimulation _sim;

  static final bouncy = ClaySpringCurve(ClaySprings.bouncy);
  static final gentle = ClaySpringCurve(
    ClaySprings.gentle,
    settleDuration: const Duration(milliseconds: 450),
  );
  static final snappy = ClaySpringCurve(
    ClaySprings.snappy,
    settleDuration: const Duration(milliseconds: 300),
  );
  static final liquid = ClaySpringCurve(
    ClaySprings.liquid,
    settleDuration: const Duration(milliseconds: 650),
  );

  @override
  double transformInternal(double t) {
    if (t >= 1) return 1;
    final seconds =
        t * settleDuration.inMicroseconds / Duration.microsecondsPerSecond;
    return _sim.x(seconds);
  }
}

/// Reduced-motion aware spring & wobble settings for the clay kit.
class ClayMotion {
  const ClayMotion({required this.enabled});

  final bool enabled;

  SpringDescription get snappy =>
      enabled ? ClaySprings.snappy : ClaySprings.still;
  SpringDescription get bouncy =>
      enabled ? ClaySprings.bouncy : ClaySprings.still;
  SpringDescription get liquid =>
      enabled ? ClaySprings.liquid : ClaySprings.still;
  SpringDescription get gentle =>
      enabled ? ClaySprings.gentle : ClaySprings.still;

  Duration get stagger => enabled ? ClayDurations.stagger : Duration.zero;

  /// Press squash amplitude (X +squash, Y -squash).
  double get squash => enabled ? 0.12 : 0.03;

  bool get skew => enabled;
  bool get ripple => enabled;

  Duration staggerFor(int index) => stagger * index;

  static ClayMotion of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ClayMotionScope>();
    if (scope != null) return scope.motion;
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ClayMotion(enabled: !disabled);
  }
}

/// Wraps the application and exposes [ClayMotion.of] respecting OS/browser
/// `prefers-reduced-motion` (`MediaQuery.disableAnimations`).
class ClayMotionScope extends InheritedWidget {
  const ClayMotionScope({
    super.key,
    required this.motion,
    required super.child,
  });

  final ClayMotion motion;

  static Widget fromMediaQuery({required Widget child}) {
    return Builder(
      builder: (context) {
        final disabled =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        return ClayMotionScope(
          motion: ClayMotion(enabled: !disabled),
          child: child,
        );
      },
    );
  }

  @override
  bool updateShouldNotify(ClayMotionScope oldWidget) =>
      oldWidget.motion.enabled != motion.enabled;
}

/// Velocity-proportional skew helper: `clamp(v * 0.0006, -0.18, 0.18)`.
double skewForVelocity(double velocityPxPerSecond) {
  return (velocityPxPerSecond * 0.0006).clamp(-0.18, 0.18);
}

/// Damped sine for the surface outline ripple: `amp * sin(t * 2π * 2.2) * e^(-4t)`.
double rippleAt(double t, {double amp = 3.0}) {
  if (t <= 0) return 0;
  return amp * math.sin(t * 2 * math.pi * 2.2) * math.exp(-4 * t);
}
