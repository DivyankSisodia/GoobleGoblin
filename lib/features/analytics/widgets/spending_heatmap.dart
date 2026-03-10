import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/analytics_provider.dart';

/// Monthly spending heatmap powered by flutter_heatmap_calendar.
/// Shows the current month with colour-coded spending intensity per day.
class SpendingHeatmapWidget extends ConsumerStatefulWidget {
  const SpendingHeatmapWidget({super.key});

  @override
  ConsumerState<SpendingHeatmapWidget> createState() =>
      _SpendingHeatmapWidgetState();
}

class _SpendingHeatmapWidgetState extends ConsumerState<SpendingHeatmapWidget> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(heatmapDailyAmountProvider);
    return async.when(
      loading: () => _shell(
        child: const SizedBox(
          height: 160,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryNeon,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: _buildHeatmap,
    );
  }

  Widget _buildHeatmap(Map<String, double> amountByDay) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // flutter_heatmap_calendar expects Map<DateTime, int>
    // We map each day's amount to an int "level" 1–5 (0 = no spending)
    final maxAmount = amountByDay.values.isEmpty
        ? 1.0
        : amountByDay.values.reduce((a, b) => a > b ? a : b);

    final datasets = <DateTime, int>{};
    for (final entry in amountByDay.entries) {
      final date = DateTime.parse(entry.key);
      // Only include days in the current month
      if (date.month != now.month || date.year != now.year) continue;
      if (entry.value <= 0) continue;
      final level = ((entry.value / maxAmount) * 4).ceil().clamp(1, 4);
      datasets[DateTime(date.year, date.month, date.day)] = level;
    }

    final selectedAmount = _selectedDay != null
        ? (amountByDay[_fmtKey(_selectedDay!)] ?? 0.0)
        : null;

    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── selected-day banner ─────────────────────────────────────────
          if (_selectedDay != null) ...[
            GestureDetector(
              onTap: () => setState(() => _selectedDay = null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtDisplay(_selectedDay!),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.primaryNeon,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      selectedAmount != null && selectedAmount > 0
                          ? CurrencyUtils.format(selectedAmount)
                          : 'No spending',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── heatmap calendar ────────────────────────────────────────────
          HeatMapCalendar(
            flexible: true,
            datasets: datasets,
            initDate: startOfMonth,
            defaultColor: AppColors.surfaceLight,
            textColor: Colors.white70,
            colorMode: ColorMode.color,
            colorsets: const {
              1: Color(0xFF1A3A0A),
              2: Color(0xFF2E6612),
              3: Color(0xFF5BAD24),
              4: Color(0xFFB0FF38), // AppColors.primaryNeon
            },
            borderRadius: 6,
            monthFontSize: 14,
            weekFontSize: 11,
            onClick: (date) {
              setState(() {
                final key = _fmtKey(date);
                final isSame =
                    _selectedDay != null && _fmtKey(_selectedDay!) == key;
                _selectedDay = isSame ? null : date;
              });
            },
          ),

          // ── legend ──────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              for (final color in const [
                Color(0xFF1A3A0A),
                Color(0xFF2E6612),
                Color(0xFF5BAD24),
                Color(0xFFB0FF38),
              ])
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                'More',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  String _fmtKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDisplay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
