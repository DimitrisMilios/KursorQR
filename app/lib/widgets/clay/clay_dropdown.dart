import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';
import 'clay_field.dart';
import 'clay_popover.dart';
import 'clay_pressable.dart';

class ClayDropdownItem<T> {
  const ClayDropdownItem({
    required this.value,
    required this.label,
    this.leading,
    this.icon,
  });

  final T value;
  final String label;
  final Widget? leading;
  final IconData? icon;
}

/// Raised pill clay button that opens a bouncy [showClayMenu] popover.
/// Replaces Material [DropdownButtonFormField].
class ClayDropdown<T> extends StatelessWidget {
  const ClayDropdown({
    super.key,
    this.value,
    this.items = const [],
    this.onChanged,
    this.label,
    this.placeholder,
    this.leading,
    this.expand = true,
    this.height = 44,
    this.displayText,
  });

  final T? value;
  final List<ClayDropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? placeholder;
  final Widget? leading;
  final bool expand;
  final double height;
  final String? displayText;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final picked = await showClayMenu<T>(
      context: context,
      anchorRect: rect,
      width: rect.width.clamp(190.0, 360.0),
      items: [
        for (final it in items)
          ClayMenuItem<T>(
            value: it.value,
            label: it.label,
            icon: it.icon,
            leading: it.leading,
            selected: it.value == value,
          ),
      ],
    );
    if (picked != null) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final current = items
        .where((i) => i.value == value)
        .cast<ClayDropdownItem<T>?>()
        .firstOrNull;
    final text = displayText ?? current?.label ?? placeholder ?? '';
    final lead = leading ??
        current?.leading ??
        (current?.icon != null
            ? Icon(current!.icon, size: 16, color: AppColors.textPrimary)
            : null);

    final button = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: ClayPressable(
        onTap: enabled ? () => _open(context) : null,
        enabled: enabled,
        builder: (context, hover, press, _) {
          final h = hover.clamp(0.0, 1.0);
          return Container(
            height: height,
            padding: const EdgeInsets.only(left: 16, right: 12),
            decoration: ClayDecoration(
              radius: height / 2,
              depth: 5,
              lift: ui.lerpDouble(10, 14, h)!,
              pressed: press.clamp(0.0, 1.0),
              shadowOpacity: 0.16,
              edgeOpacity: 0.10,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (lead != null) ...[lead, const SizedBox(width: 8)],
                if (expand)
                  Expanded(
                    child: _label(text, current == null && displayText == null),
                  )
                else
                  _label(text, current == null && displayText == null),
                const SizedBox(width: 6),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          );
        },
      ),
    );

    if (label == null) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClayLabel(
          label!,
          padding: const EdgeInsets.only(left: 4, bottom: 6),
        ),
        button,
      ],
    );
  }

  Widget _label(String text, bool isPlaceholder) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: isPlaceholder ? AppColors.textMuted : AppColors.textPrimary,
        fontSize: AppDimensions.fontMd,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
