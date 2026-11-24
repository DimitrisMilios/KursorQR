import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';

/// Muted uppercase section / field label.
class ClayLabel extends StatelessWidget {
  const ClayLabel(
    this.text, {
    super.key,
    this.color = AppColors.textMuted,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Sunken clay well text input with spring-animated focus depth, muted caps
/// label, optional prefix/suffix, helper text, and inline error messaging.
class ClayField extends StatefulWidget {
  const ClayField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefix,
    this.suffix,
    this.style,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    this.radius = AppDimensions.radiusClaySm,
    this.monospace = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? prefixText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final Widget? prefix;
  final Widget? suffix;
  final TextStyle? style;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final EdgeInsetsGeometry contentPadding;
  final double radius;
  final bool monospace;

  @override
  State<ClayField> createState() => _ClayFieldState();
}

class _ClayFieldState extends State<ClayField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focus;
  late final AnimationController _focusAnim;
  bool _ownsFocus = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _focus.addListener(_onFocus);
    _focusAnim = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(ClayField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focus.removeListener(_onFocus);
      if (_ownsFocus) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
      _ownsFocus = widget.focusNode == null;
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() {
    _focusAnim.springTo(
      _focus.hasFocus ? 1 : 0,
      spring: ClayMotion.of(context).snappy,
    );
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    _focusAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;
    final textStyle = (widget.style ??
            const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ))
        .copyWith(fontFamily: widget.monospace ? 'monospace' : null);

    final field = TextField(
      controller: widget.controller,
      focusNode: _focus,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      textAlign: widget.textAlign,
      cursorColor: AppColors.primary,
      style: textStyle,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: textStyle.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        prefixText: widget.prefixText,
        prefixStyle: textStyle.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        counterText: '',
        isDense: true,
        contentPadding: widget.contentPadding,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        prefixIcon: widget.prefix,
        suffixIcon: widget.suffix,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );

    return AnimatedBuilder(
      animation: _focusAnim,
      child: field,
      builder: (context, child) {
        final f = _focusAnim.value.clamp(0.0, 1.0);
        final wellColor = hasError ? AppColors.coralSoft : AppColors.clayDeep;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Transform.translate(
                offset: Offset(0, -2 * f),
                child: ClayLabel(
                  widget.label!,
                  color: hasError
                      ? AppColors.coralDeep
                      : Color.lerp(AppColors.textMuted, AppColors.primary, f)!,
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                ),
              ),
            Opacity(
              opacity: widget.enabled ? 1 : 0.62,
              child: Container(
                decoration: ClayDecoration.well(
                  color: wellColor,
                  radius: widget.radius,
                  depth: 5 + 3 * f,
                  shadeOpacity: 0.14 + 0.04 * f,
                ),
                child: child,
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 6),
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.coralDeep,
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (widget.helperText != null)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 6),
                child: Text(
                  widget.helperText!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
