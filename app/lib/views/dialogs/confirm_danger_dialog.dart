import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';

/// Shared coral danger confirmation dialog using [ClayDialog].
class ConfirmDangerDialog extends StatelessWidget {
  const ConfirmDangerDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return ClayDialog(
      width: 460,
      title: title,
      headerIcon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.coralDeep,
        size: 26,
      ),
      actions: [
        ClayButton.text(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ClayButton.danger(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
    );
  }
}
