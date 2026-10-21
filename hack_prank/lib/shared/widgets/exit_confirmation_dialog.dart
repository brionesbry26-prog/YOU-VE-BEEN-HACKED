import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Asks whether to end the simulation. Resolves to true for "EXIT SAFELY".
/// Dismissing the dialog (tapping outside / back) continues the prank.
Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => const ExitConfirmationDialog(),
  );
  return result ?? false;
}

class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.shield_outlined, color: AppColors.hackerGreen, size: 36),
      title: Text(
        'End the simulation?',
        textAlign: TextAlign.center,
        style: AppText.display(size: 26),
      ),
      content: Text(
        'This is only a simulation. Nothing on this device was touched.',
        textAlign: TextAlign.center,
        style: AppText.terminal(color: AppColors.textSecondary),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'CONTINUE PRANK',
            style: AppText.display(size: 17, color: AppColors.hackerGreen),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.hackerGreen,
            foregroundColor: AppColors.background,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'EXIT SAFELY',
            style: AppText.display(size: 17, color: AppColors.background),
          ),
        ),
      ],
    );
  }
}
