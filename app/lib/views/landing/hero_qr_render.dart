import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';

/// Interactive 3D Blender clay hero render (`assets/clay/hero_qr_scene.webp`).
///
/// Motion: gentle 4 s vertical float (6 px) + 1.5° sway that plays twice on
/// arrival and then rests (zero idle GPU work), resumes on hover with a 4°
/// perspective tilt toward the pointer, and wobbles with jelly squash on tap.
class HeroQrRender extends StatefulWidget {
  const HeroQrRender({super.key});

  static const String assetPath = 'assets/clay/hero_qr_scene.webp';
  static const double renderWidth = 720;
  static const double renderHeight = 560;

  @override
  State<HeroQrRender> createState() => _HeroQrRenderState();
}

class _HeroQrRenderState extends State<HeroQrRender>
    with TickerProviderStateMixin {
  static const double _floatPx = 6;
  static const double _floatRad = 1.5 * math.pi / 180;
  static const double _tiltRad = 4 * math.pi / 180;
  static const int _arrivalCycles = 2;

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  late final AnimationController _tiltX =
      AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _tiltY =
      AnimationController.unbounded(vsync: this, value: 0);
  final JellyController _jelly = JellyController();

  bool _motionEnabled = true;
  bool _arrived = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionEnabled = ClayMotion.of(context).enabled;
    if (!_motionEnabled) {
      _float
        ..stop()
        ..value = 0;
      _tiltX.value = 0;
      _tiltY.value = 0;
    } else if (!_arrived) {
      _arrived = true;
      _float.repeat(count: _arrivalCycles);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _tiltX.dispose();
    _tiltY.dispose();
    super.dispose();
  }

  void _onEnter() {
    if (_motionEnabled && !_float.isAnimating) _float.repeat();
  }

  void _onHover(PointerEvent event, Size size) {
    if (!_motionEnabled || size.isEmpty) return;
    final nx = ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny =
        ((event.localPosition.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    final spring = ClayMotion.of(context).gentle;
    _tiltY.springTo(nx * _tiltRad, spring: spring);
    _tiltX.springTo(-ny * _tiltRad, spring: spring);
  }

  void _onExit() {
    final spring = ClayMotion.of(context).gentle;
    _tiltX.springTo(0, spring: spring);
    _tiltY.springTo(0, spring: spring);
    if (_float.isAnimating) {
      _float.animateTo(1.0).whenComplete(() {
        if (mounted && !_float.isAnimating) _float.value = 0;
      });
    }
  }

  Matrix4 _transform() {
    final phase = _float.value * 2 * math.pi;
    final dy = _motionEnabled ? _floatPx * math.sin(phase) : 0.0;
    final rz =
        _motionEnabled ? _floatRad * math.sin(phase + math.pi / 3) : 0.0;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..translateByDouble(0.0, dy, 0.0, 1.0)
      ..rotateX(_tiltX.value)
      ..rotateY(_tiltY.value)
      ..rotateZ(rz);
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final decodeWidth = math.min(
      (HeroQrRender.renderWidth * dpr).round(),
      HeroQrRender.renderWidth.toInt() * 2,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: HeroQrRender.renderWidth),
      child: AspectRatio(
        aspectRatio: HeroQrRender.renderWidth / HeroQrRender.renderHeight,
        child: LayoutBuilder(
          builder: (context, constraints) => MouseRegion(
            onEnter: (_) => _onEnter(),
            onHover: (e) => _onHover(e, constraints.biggest),
            onExit: (_) => _onExit(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _jelly.tap(squash: 0.06),
              child: AnimatedBuilder(
                animation: Listenable.merge([_float, _tiltX, _tiltY]),
                builder: (context, child) => Transform(
                  transform: _transform(),
                  alignment: Alignment.center,
                  child: child,
                ),
                child: JellyTransform(
                  controller: _jelly,
                  child: RepaintBoundary(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        HeroQrRender.assetPath,
                        width: HeroQrRender.renderWidth,
                        height: HeroQrRender.renderHeight,
                        cacheWidth: decodeWidth,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        semanticLabel:
                            '3D clay QR code flanked by iOS and Android phones',
                        errorBuilder: (_, __, ___) => const ClayPanel(
                          width: HeroQrRender.renderWidth,
                          height: HeroQrRender.renderHeight,
                          radius: AppDimensions.radiusClayXl,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 120,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
