import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/motion/clay_motion.dart';
import 'jelly_transform.dart';

/// Shared pointer interaction layer for clay controls: lazy hover/press
/// springs, jelly squash, pointer cursor, zero Material ink splashes.
class ClayPressable extends StatefulWidget {
  const ClayPressable({
    super.key,
    required this.builder,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.enabled = true,
    this.squash,
    this.surfaceRipple = false,
    this.jelly,
    this.cursor = SystemMouseCursors.click,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget Function(
    BuildContext context,
    double hover,
    double press,
    Widget? child,
  ) builder;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final bool enabled;
  final double? squash;
  final bool surfaceRipple;
  final JellyController? jelly;
  final MouseCursor cursor;
  final HitTestBehavior behavior;

  @override
  State<ClayPressable> createState() => _ClayPressableState();
}

class _ClayPressableState extends State<ClayPressable>
    with TickerProviderStateMixin {
  final _Tick _tick = _Tick();
  AnimationController? _hoverController;
  AnimationController? _pressController;
  final JellyController _ownJelly = JellyController();

  JellyController get _jelly => widget.jelly ?? _ownJelly;

  AnimationController get _hover => _hoverController ??=
      AnimationController.unbounded(vsync: this, value: 0)
        ..addListener(_tick.ping);
  AnimationController get _press => _pressController ??=
      AnimationController.unbounded(vsync: this, value: 0)
        ..addListener(_tick.ping);

  @override
  void dispose() {
    _hoverController?.dispose();
    _pressController?.dispose();
    _tick.dispose();
    super.dispose();
  }

  ClayMotion get _motion => ClayMotion.of(context);
  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _onEnter(PointerEnterEvent _) {
    if (!widget.enabled) return;
    _hover.springTo(1, spring: _motion.snappy);
  }

  void _onExit(PointerExitEvent _) {
    if (_hoverController == null) return;
    _hover.springTo(0, spring: _motion.snappy);
  }

  void _down(TapDownDetails d) {
    if (!_interactive) return;
    _press.springTo(1, spring: _motion.snappy);
    if (widget.squash != 0) _jelly.poke(squash: widget.squash);
    widget.onTapDown?.call(d);
  }

  void _up() {
    if (!_interactive || _pressController == null) return;
    _press.springTo(0, spring: _motion.bouncy);
    if (widget.squash != 0) _jelly.release();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: _tick,
      child: widget.child,
      builder: (context, child) => widget.builder(
        context,
        _hoverController?.value ?? 0,
        _pressController?.value ?? 0,
        child,
      ),
    );

    if (widget.squash != 0) {
      content = JellyTransform(
        controller: _jelly,
        squash: widget.squash,
        surfaceRipple: widget.surfaceRipple,
        child: content,
      );
    }

    return MouseRegion(
      cursor: _interactive ? widget.cursor : MouseCursor.defer,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        onTap: _interactive ? widget.onTap : null,
        onLongPress: _interactive ? widget.onLongPress : null,
        child: content,
      ),
    );
  }
}

class _Tick extends ChangeNotifier {
  void ping() => notifyListeners();
}
