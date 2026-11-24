import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';

/// One row inside a clay popover menu.
class ClayMenuItem<T> {
  const ClayMenuItem({
    this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.leading,
    this.danger = false,
    this.enabled = true,
    this.selected = false,
  }) : divider = false;

  const ClayMenuItem.header({
    required this.label,
    this.subtitle,
  })  : value = null,
        icon = null,
        leading = null,
        danger = false,
        enabled = false,
        selected = false,
        divider = false;

  const ClayMenuItem.divider()
      : value = null,
        label = '',
        subtitle = null,
        icon = null,
        leading = null,
        danger = false,
        enabled = false,
        selected = false,
        divider = true;

  final T? value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool danger;
  final bool enabled;
  final Widget? leading;
  final bool selected;
  final bool divider;
}

/// Anchored bouncy clay popover menu. Replaces Material [PopupMenuButton] / `showMenu`.
Future<T?> showClayMenu<T>({
  required BuildContext context,
  required List<ClayMenuItem<T>> items,
  Offset? position,
  Rect? anchorRect,
  double width = 236,
}) {
  assert(position != null || anchorRect != null);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final anchor = anchorRect ?? Rect.fromLTWH(position!.dx, position.dy, 0, 0);
  final motion = ClayMotion.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _ClayPopoverRoute<T>(
      anchor: anchor,
      overlaySize: overlay.size,
      width: width,
      motion: motion,
      builder: (context) => ClayMenuList<T>(items: items, motion: motion),
    ),
  );
}

class _ClayPopoverRoute<T> extends PopupRoute<T> {
  _ClayPopoverRoute({
    required this.anchor,
    required this.overlaySize,
    required this.width,
    required this.builder,
    required this.motion,
  });

  final Rect anchor;
  final Size overlaySize;
  final double width;
  final WidgetBuilder builder;
  final ClayMotion motion;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => motion.enabled
      ? const Duration(milliseconds: 400)
      : const Duration(milliseconds: 120);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    const margin = 10.0;
    var left = anchor.left;
    if (left + width > overlaySize.width - margin) {
      left = overlaySize.width - margin - width;
    }
    if (left < margin) left = margin;
    final top = anchor.bottom + 8;
    final flip =
        top + 320 > overlaySize.height && anchor.top > overlaySize.height / 2;
    final alignment = Alignment(
      left + width / 2 < anchor.center.dx ? 1 : -1,
      flip ? 1 : -1,
    );

    final curve = CurvedAnimation(
      parent: animation,
      curve: motion.enabled
          ? ClaySpringCurve(
              ClaySprings.bouncy,
              settleDuration: const Duration(milliseconds: 400),
            )
          : Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    Widget child = Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: overlaySize.height - margin * 2),
        decoration: const ClayDecoration(
          color: AppColors.clay,
          radius: AppDimensions.radiusClay,
          depth: 5,
          lift: 16,
          shadowOpacity: 0.24,
        ),
        padding: const EdgeInsets.all(8),
        child: builder(context),
      ),
    );

    child = AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) {
        final t = animation.status == AnimationStatus.reverse
            ? animation.value
            : curve.value;
        final scale = animation.status == AnimationStatus.reverse
            ? 0.95 + 0.05 * t
            : 0.9 + 0.1 * t;
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, alignment: alignment, child: child),
        );
      },
    );

    return Stack(
      children: [
        if (flip)
          Positioned(
            left: left,
            bottom: overlaySize.height - anchor.top + 8,
            child: child,
          )
        else
          Positioned(left: left, top: top, child: child),
      ],
    );
  }
}

class ClayMenuList<T> extends StatelessWidget {
  const ClayMenuList({
    super.key,
    required this.items,
    required this.motion,
  });

  final List<ClayMenuItem<T>> items;
  final ClayMotion motion;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            _StaggerIn(
              delay: motion.enabled
                  ? Duration(milliseconds: 22 * i)
                  : Duration.zero,
              child: items[i].divider
                  ? const SizedBox(height: 8)
                  : ClayMenuRow<T>(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class ClayMenuRow<T> extends StatelessWidget {
  const ClayMenuRow({super.key, required this.item, this.onTap});

  final ClayMenuItem<T> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!item.enabled && item.subtitle != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppDimensions.fontXs,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppDimensions.fontBody,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final color = item.danger ? AppColors.coralDeep : AppColors.textPrimary;
    return Opacity(
      opacity: item.enabled ? 1 : 0.45,
      child: ClayPressable(
        onTap: item.enabled
            ? (onTap ?? () => Navigator.of(context).pop<T>(item.value))
            : null,
        enabled: item.enabled,
        squash: 0.04,
        builder: (context, hover, press, _) {
          final h = hover.clamp(0.0, 1.0);
          return Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusClaySm - 2),
              color: (item.danger ? AppColors.coral : AppColors.mint)
                  .withValues(alpha: 0.55 * h + (item.selected ? 0.38 : 0)),
            ),
            child: Row(
              children: [
                if (item.leading != null) ...[
                  item.leading!,
                  const SizedBox(width: 10),
                ] else if (item.icon != null) ...[
                  Icon(item.icon, size: 17, color: color),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (item.selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    if (widget.delay == Duration.zero) {
      _c.value = 1;
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
