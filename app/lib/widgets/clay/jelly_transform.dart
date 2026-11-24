import 'package:flutter/material.dart';

import '../../core/motion/clay_motion.dart';

/// Imperative handle for a [JellyTransform].
class JellyController {
  _JellyTransformState? _state;

  void poke({double? squash}) => _state?._poke(squash);
  void release() => _state?._release();
  void tap({double? squash}) => _state?._tap(squash);
  void velocity(double velocityX, {double velocityY = 0}) =>
      _state?._velocity(velocityX, velocityY);
  void settle() => _state?._settle();
  void wobble({double radians = 0.1}) => _state?._wobble(radians);
  bool get isAttached => _state != null;
}

/// Soft-body wobble wrapper with lazy-allocated unbounded spring controllers:
/// out-of-phase X/Y squash & stretch, velocity skew, hover wobble, and optional
/// surface ripple forwarding.
class JellyTransform extends StatefulWidget {
  const JellyTransform({
    super.key,
    required this.child,
    this.controller,
    this.squash,
    this.spring,
    this.onRipple,
    this.surfaceRipple = false,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final JellyController? controller;
  final double? squash;
  final SpringDescription? spring;
  final ValueChanged<double>? onRipple;
  final bool surfaceRipple;
  final Alignment alignment;

  @override
  State<JellyTransform> createState() => _JellyTransformState();
}

/// Exposes surface ripple time (seconds since poke, or -1) to descendants.
class JellyRipple extends InheritedWidget {
  const JellyRipple({super.key, required this.time, required super.child});

  final double time;

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<JellyRipple>()?.time ??
        -1;
  }

  @override
  bool updateShouldNotify(JellyRipple oldWidget) => oldWidget.time != time;
}

class _JellyTransformState extends State<JellyTransform>
    with TickerProviderStateMixin {
  final _Tick _tick = _Tick();
  AnimationController? _x;
  AnimationController? _y;
  AnimationController? _skewX;
  AnimationController? _skewY;
  AnimationController? _rot;
  AnimationController? _rippleController;

  bool _pressed = false;

  AnimationController _spring(double value) =>
      AnimationController.unbounded(vsync: this, value: value)
        ..addListener(_tick.ping);

  AnimationController get _scaleX => _x ??= _spring(1.0);
  AnimationController get _scaleY => _y ??= _spring(1.0);
  AnimationController get _skewXc => _skewX ??= _spring(0.0);
  AnimationController get _skewYc => _skewY ??= _spring(0.0);
  AnimationController get _rotation => _rot ??= _spring(0.0);
  AnimationController get _ripple => _rippleController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )
        ..addListener(_onRippleTick)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onRipple?.call(-1);
        });

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(JellyTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    for (final c in [_x, _y, _skewX, _skewY, _rot, _rippleController]) {
      c?.dispose();
    }
    _tick.dispose();
    super.dispose();
  }

  ClayMotion get _motion => ClayMotion.of(context);
  double get _squash => widget.squash ?? _motion.squash;
  SpringDescription get _releaseSpring => widget.spring ?? _motion.liquid;

  void _onRippleTick() {
    final t = _ripple.value * 0.7;
    widget.onRipple?.call(t);
    if (widget.surfaceRipple && widget.onRipple == null) setState(() {});
  }

  void _poke(double? squash) {
    _pressed = true;
    final s = squash ?? _squash;
    _scaleX.springTo(1 + s, spring: _motion.snappy);
    _scaleY.springTo(1 - s, spring: _motion.snappy);
  }

  void _release() {
    if (!_pressed && (_x?.value ?? 1) == 1 && (_y?.value ?? 1) == 1) return;
    _pressed = false;
    _scaleX.springTo(1.0, spring: _releaseSpring);
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (mounted) _scaleY.springTo(1.0, spring: _releaseSpring);
    });
    if (_motion.ripple && (widget.onRipple != null || widget.surfaceRipple)) {
      _ripple.forward(from: 0);
    }
  }

  void _tap(double? squash) {
    _poke(squash);
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _release();
    });
  }

  void _velocity(double vx, double vy) {
    if (!_motion.skew) return;
    _skewXc.value = skewForVelocity(vx);
    _skewYc.value = skewForVelocity(vy);
  }

  void _settle() {
    if (_skewX == null && _skewY == null) return;
    _skewXc.springTo(0, spring: _motion.bouncy);
    _skewYc.springTo(0, spring: _motion.bouncy);
  }

  void _wobble(double radians) {
    if (!_motion.enabled) return;
    _rotation.springTo(radians, spring: _motion.snappy).then((_) {
      if (mounted) _rotation.springTo(0, spring: _releaseSpring);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.surfaceRipple && widget.onRipple == null) {
      final ripple = _rippleController;
      child = JellyRipple(
        time: ripple != null && ripple.isAnimating ? ripple.value * 0.7 : -1,
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: _tick,
      child: child,
      builder: (context, child) {
        final m = Matrix4.identity()
          ..setEntry(0, 1, _skewX?.value ?? 0)
          ..setEntry(1, 0, _skewY?.value ?? 0);
        final rot = _rot?.value ?? 0;
        if (rot != 0) m.multiply(Matrix4.rotationZ(rot));
        m.multiply(Matrix4.diagonal3Values(_x?.value ?? 1, _y?.value ?? 1, 1));
        return Transform(
          transform: m,
          alignment: widget.alignment,
          child: child,
        );
      },
    );
  }
}

class _Tick extends ChangeNotifier {
  void ping() => notifyListeners();
}
