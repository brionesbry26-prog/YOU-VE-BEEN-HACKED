import 'package:flutter/material.dart';

import '../../../core/constants/prank_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Fictional files "transferring" one after another as [progress] goes 0 → 1.
/// Every name and size comes from [PrankConstants.simulatedFiles]; the device
/// is never inspected.
class SimulatedFileList extends StatelessWidget {
  const SimulatedFileList({
    super.key,
    required this.progress,
    this.files = PrankConstants.simulatedFiles,
    this.largeText = false,
    this.highContrast = false,
  });

  final double progress;
  final List<SimulatedFile> files;
  final bool largeText;
  final bool highContrast;

  /// Transfer progress (0-1) of file [index] at overall [progress].
  static double rowProgress(int index, int count, double progress) {
    // Rows start staggered across the first 70% and each takes 30%, so every
    // file has finished before the stage ends.
    final start = index / count * 0.7;
    return ((progress - start) / 0.3).clamp(0.0, 1.0);
  }

  static int completedCount(int count, double progress) {
    var done = 0;
    for (var i = 0; i < count; i++) {
      if (rowProgress(i, count, progress) >= 1) done++;
    }
    return done;
  }

  @override
  Widget build(BuildContext context) {
    final done = completedCount(files.length, progress);
    final rows = <Widget>[];
    for (var i = 0; i < files.length; i++) {
      final start = i / files.length * 0.7;
      if (progress < start) break;
      rows.add(
        _FileRow(
          file: files[i],
          progress: rowProgress(i, files.length, progress),
          largeText: largeText,
          highContrast: highContrast,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows,
        const SizedBox(height: 12),
        Text(
          'SIMULATED FILES PROCESSED: ${done.toString().padLeft(2, '0')}',
          style: AppText.terminal(
            color: AppColors.hackerGreen,
            large: largeText,
            size: 15,
            weight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.progress,
    required this.largeText,
    required this.highContrast,
  });

  final SimulatedFile file;
  final double progress;
  final bool largeText;
  final bool highContrast;

  IconData get _icon {
    final ext = file.name.split('.').last;
    return switch (ext) {
      'jpg' || 'png' => Icons.image_outlined,
      'vcf' => Icons.contacts_outlined,
      'txt' => Icons.chat_bubble_outline,
      'zip' => Icons.folder_zip_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      _ => Icons.lock_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final complete = progress >= 1;
    final style = AppText.terminal(
      large: largeText,
      highContrast: highContrast,
      size: 13,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (context, appear, child) => Opacity(
        opacity: appear,
        child: Transform.translate(offset: Offset(0, 8 * (1 - appear)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(_icon, size: 20, color: AppColors.mutedTerminal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.label,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(file.size, style: style.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: complete ? AppColors.hackerGreen : AppColors.warning,
                      backgroundColor: AppColors.hackerGreen.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: complete
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('done'),
                        color: AppColors.hackerGreen,
                        size: 22,
                      )
                    : Text(
                        '${(progress * 100).round()}%',
                        key: const ValueKey('pct'),
                        textAlign: TextAlign.right,
                        style: style.copyWith(color: AppColors.warning),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
