import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// Card widget for displaying money source in onboarding
class MoneySourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final double? progress; // For credit cards (0.0 to 1.0)
  final VoidCallback? onDelete;

  const MoneySourceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.progress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Gap(16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          // Progress bar for credit cards
          if (progress != null) ...[const Gap(12), _buildProgressBar()],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percentage = (progress! * 100).toInt();
    final barColor = progress! < 0.5
        ? AppColors.successGreen
        : progress! < 0.75
        ? AppColors.warningYellow
        : AppColors.errorRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Credit Used',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: barColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Gap(6),
        Stack(
          children: [
            // Background
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: progress!.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor, barColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
