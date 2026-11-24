import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';
import 'clay_icon_button.dart';

/// Shows a clay modal dialog with a warm `sandDeep` barrier and bouncy spring
/// entrance. Replaces every Material `showDialog`.
Future<T?> showClayDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Offset? origin,
}) {
  final motion = ClayMotion.of(context);
  final size = MediaQuery.sizeOf(context);
  final alignment = origin == null
      ? Alignment.center
      : Alignment(
          (origin.dx / size.width) * 2 - 1,
          (origin.dy / size.height) * 2 - 1,
        );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: AppColors.sandDeep.withValues(alpha: 0.65),
    transitionDuration: motion.enabled
        ? const Duration(milliseconds: 460)
        : const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondary) =>
        SafeArea(child: Center(child: builder(context))),
    transitionBuilder: (context, animation, secondary, child) {
      final reverse = animation.status == AnimationStatus.reverse;
      final spring = motion.enabled
          ? ClaySpringCurve(
              ClaySprings.bouncy,
              settleDuration: const Duration(milliseconds: 460),
            )
          : Curves.easeOut;
      final t = reverse
          ? Curves.easeIn.transform(animation.value)
          : spring.transform(animation.value);
      final scale = reverse ? 0.96 + 0.04 * t : 0.92 + 0.08 * t;
      final rise = reverse ? 0.0 : 24.0 * (1 - t);
      return Opacity(
        opacity: Curves.easeOut.transform(animation.value.clamp(0.0, 1.0)),
        child: Transform.translate(
          offset: Offset(0, rise),
          child: Transform.scale(scale: scale, alignment: alignment, child: child),
        ),
      );
    },
  );
}

/// Clay dialog panel with optional sunken header icon tile, title, subtitle,
/// close button, staggered entrance, and right-aligned clay actions.
class ClayDialog extends StatelessWidget {
  const ClayDialog({
    super.key,
    required this.child,
    this.width = 560,
    this.title,
    this.subtitle,
    this.subtitleMonospace = false,
    this.headerIcon,
    this.showClose = true,
    this.padding = const EdgeInsets.all(28),
    this.actions,
    this.scrollable = true,
  });

  final Widget child;
  final double width;
  final String? title;
  final String? subtitle;
  final bool subtitleMonospace;
  final Widget? headerIcon;
  final bool showClose;
  final EdgeInsetsGeometry padding;
  final List<Widget>? actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final motion = ClayMotion.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final children = <Widget>[
      if (title != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerIcon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const ClayDecoration.well(
                    radius: AppDimensions.radiusClaySm,
                    depth: 4,
                  ),
                  child: headerIcon,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppDimensions.fontXl,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: subtitleMonospace ? 'monospace' : null,
                            color: AppColors.textMuted,
                            fontSize: subtitleMonospace
                                ? AppDimensions.fontSm
                                : AppDimensions.fontMd,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showClose) ...[
                const SizedBox(width: 12),
                ClayIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  size: 36,
                  iconSize: 18,
                  flat: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ],
          ),
        ),
      child,
      if (actions != null && actions!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: actions!,
          ),
        ),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxWidth: screenSize.width - 32,
          maxHeight: screenSize.height - 48,
        ),
        padding: padding,
        decoration: const ClayDecoration(
          color: AppColors.clay,
          radius: AppDimensions.radiusClayLg,
          depth: AppDimensions.clayDepth,
          lift: 24,
          shadowOpacity: 0.26,
        ),
        child: scrollable
            ? SingleChildScrollView(
                child: _buildColumn(children, motion),
              )
            : _buildColumn(children, motion),
      ),
    );
  }

  Widget _buildColumn(List<Widget> children, ClayMotion motion) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          ClayStagger(index: i, delay: motion.stagger, child: children[i]),
      ],
    );
  }
}

/// Fades and gently rises a child in after `index * delay`.
class ClayStagger extends StatefulWidget {
  const ClayStagger({
    super.key,
    required this.child,
    required this.index,
    this.delay = ClayDurations.stagger,
    this.rise = 12,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final double rise;

  @override
  State<ClayStagger> createState() => _ClayStaggerState();
}

class _ClayStaggerState extends State<ClayStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final cappedIndex = widget.index.clamp(0, 8);
    final delay = widget.delay * cappedIndex;
    if (widget.delay == Duration.zero) {
      _c.value = 1;
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = ClaySpringCurve.gentle.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.rise * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
