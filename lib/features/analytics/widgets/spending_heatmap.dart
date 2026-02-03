import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/analytics_provider.dart';

/// Creative heatmap visualization for spending intensity
class SpendingHeatmapWidget extends ConsumerWidget {
  const SpendingHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapData = ref.watch(spendingHeatmapProvider);
    final days = AppDateUtils.getLastNDays(35); // 5 weeks

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Heatmap grid
          _buildHeatmapGrid(days, heatmapData),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(
    List<DateTime> days,
    Map<DateTime, double> heatmapData,
  ) {
    // Organize days into weeks
    final weeks = <List<DateTime>>[];
    var currentWeek = <DateTime>[];

    for (final day in days) {
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
      currentWeek.add(day);
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(7, (index) {
              if (index < week.length) {
                final day = week[index];
                final intensity = _getIntensity(day, heatmapData);
                final color = AppColors.getHeatmapColor(intensity);
                final isToday = AppDateUtils.isToday(day);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message:
                        '${AppDateUtils.formatDisplay(day)}\nSpending: ${(intensity * 100).toStringAsFixed(0)}%',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(color: AppColors.primaryNeon, width: 2)
                            : null,
                        boxShadow: intensity > 0.5
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryNeon.withValues(
                                    alpha: intensity * 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isToday
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryNeon,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              } else {
                return const SizedBox(width: 32);
              }
            }),
          ),
        );
      }).toList(),
    );
  }

  double _getIntensity(DateTime day, Map<DateTime, double> heatmapData) {
    for (final entry in heatmapData.entries) {
      if (entry.key.year == day.year &&
          entry.key.month == day.month &&
          entry.key.day == day.day) {
        return entry.value;
      }
    }
    return 0;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = index / 4;
          return Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.getHeatmapColor(intensity),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'More',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
