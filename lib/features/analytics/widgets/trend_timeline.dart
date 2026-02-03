import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/payment_repository.dart';

/// Creative timeline visualization for spending trends
class TrendTimelineWidget extends StatefulWidget {
  final List<DailySpendingData> dailyData;

  const TrendTimelineWidget({super.key, required this.dailyData});

  @override
  State<TrendTimelineWidget> createState() => _TrendTimelineWidgetState();
}

class _TrendTimelineWidgetState extends State<TrendTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _maxAmount {
    if (widget.dailyData.isEmpty) return 0;
    return widget.dailyData
        .map((d) => d.amount)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dailyData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get last 14 days of data
    final displayData = widget.dailyData.take(14).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Trend',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last ${displayData.length} days',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (_selectedIndex != null &&
                  _selectedIndex! < displayData.length)
                _buildSelectedInfo(displayData[_selectedIndex!]),
            ],
          ),
          const SizedBox(height: 24),

          // Timeline bars
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: displayData.asMap().entries.map((entry) {
                    return _buildBar(
                      entry.value,
                      entry.key,
                      displayData.length,
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Date labels
          Row(
            children: displayData.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final isLast = entry.key == displayData.length - 1;
              final isMid = entry.key == displayData.length ~/ 2;

              return Expanded(
                child: Center(
                  child: Text(
                    (isFirst || isLast || isMid)
                        ? AppDateUtils.getDayName(entry.value.date)
                        : '',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(DailySpendingData data, int index, int total) {
    final heightRatio = _maxAmount > 0 ? data.amount / _maxAmount : 0.0;
    final isSelected = _selectedIndex == index;
    final isHighest = data.amount == _maxAmount && data.amount > 0;

    // Color based on amount intensity
    Color barColor;
    if (isHighest) {
      barColor = AppColors.accentMagenta;
    } else if (heightRatio > 0.7) {
      barColor = AppColors.accentOrange;
    } else if (heightRatio > 0.4) {
      barColor = AppColors.primaryNeon;
    } else {
      barColor = AppColors.accentTeal;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = _selectedIndex == index ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Amount indicator on selection
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    CurrencyUtils.formatCompact(data.amount),
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                ),

              // Bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: (80 * heightRatio * _animation.value).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor.withValues(alpha: 0.6), barColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(isSelected ? 8 : 4),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: barColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedInfo(DailySpendingData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppDateUtils.formatDisplay(data.date),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyUtils.format(data.amount),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNeon,
            ),
          ),
          Text(
            '${data.transactionCount} transaction${data.transactionCount != 1 ? 's' : ''}',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
