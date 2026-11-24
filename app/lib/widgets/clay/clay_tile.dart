import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';

/// Selectable interactive clay tile (replaces ChoiceChip & ActionChip).
/// Raises with a bouncy spring when selected (gold by default).
class ClayTile extends StatefulWidget {
  const ClayTile({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.radius = AppDimensions.radiusClaySm,
    this.selectedColor = AppColors.gold,
    this.idleColor = AppColors.clayDeep,
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color selectedColor;
  final Color? idleColor;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  State<ClayTile> createState() => _ClayTileState();
}

class _ClayTileState extends State<ClayTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sel;

  @override
  void initState() {
    super.initState();
    _sel = AnimationController.unbounded(
      vsync: this,
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(ClayTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final motion = ClayMotion.of(context);
      _sel.springTo(
        widget.selected ? 1 : 0,
        spring: widget.selected ? motion.bouncy : motion.snappy,
      );
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGold = widget.selectedColor == AppColors.gold;
    final selectedDeco = ClayDecoration(
      color: widget.selectedColor,
      radius: widget.radius,
      depth: 4,
      lift: 10,
      shadowOpacity: 0.18,
      edgeOpacity: 0.10,
      highlightColor: isGold ? AppColors.goldLight : AppColors.clayLight,
      shadeColor: isGold ? AppColors.goldDeep : AppColors.clayShade,
      highlightOpacity: isGold ? 0.7 : 0.9,
      shadeOpacity: isGold ? 0.45 : 0.16,
    );
    final idleDeco = widget.idleColor == null
        ? selectedDeco.hidden
        : ClayDecoration(
            color: widget.idleColor!,
            radius: widget.radius,
            depth: 3,
            lift: 4,
            shadowOpacity: 0.08,
          );

    return ClayPressable(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      squash: 0.05,
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: widget.child,
      builder: (context, hover, press, child) {
        return AnimatedBuilder(
          animation: _sel,
          child: child,
          builder: (context, child) {
            final t = _sel.value.clamp(0.0, 1.0);
            final h = hover.clamp(0.0, 1.0);
            var deco = ClayDecoration.lerp(idleDeco, selectedDeco, t)!;
            if (t < 0.99 && h > 0) {
              final hoverDeco = idleDeco.copyWith(
                color: Color.lerp(
                  idleDeco.color,
                  AppColors.mint.withValues(alpha: 0.6),
                  h,
                ),
                lift: 8,
              );
              deco = ClayDecoration.lerp(deco, hoverDeco, h * (1 - t))!;
            }
            deco = deco.copyWith(pressed: press.clamp(0.0, 1.0) * 0.5);
            return Container(
              width: widget.width,
              height: widget.height,
              alignment: widget.alignment,
              padding: widget.padding,
              decoration: deco,
              child: child,
            );
          },
        );
      },
    );
  }
}
