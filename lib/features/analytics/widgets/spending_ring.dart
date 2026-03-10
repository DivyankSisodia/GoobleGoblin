import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/repositories/payment_repository.dart';

/// Creative spending ring visualization with animated arcs
class SpendingRingWidget extends StatefulWidget {
  final List<CategorySpendingData> categoryData;
  final double totalSpending;
  final String title;
  final String subtitle;

  const SpendingRingWidget({
    super.key,
    required this.categoryData,
    required this.totalSpending,
    this.title = 'Spending by Category',
    this.subtitle = 'Tap on a segment to see details',
  });

  @override
  State<SpendingRingWidget> createState() => _SpendingRingWidgetState();
}

class _SpendingRingWidgetState extends State<SpendingRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text(
            widget.title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Ring and legend side by side
          Row(
            children: [
              // Animated ring
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return GestureDetector(
                        onTapDown: (details) => _handleTap(details, context),
                        child: CustomPaint(
                          painter: _SpendingRingPainter(
                            categoryData: widget.categoryData,
                            progress: _animation.value,
                            selectedIndex: _selectedIndex,
                          ),
                          child: Center(child: _buildCenterContent()),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Legend
              Expanded(flex: 3, child: _buildLegend()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    final selectedData =
        _selectedIndex != null && _selectedIndex! < widget.categoryData.length
        ? widget.categoryData[_selectedIndex!]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          selectedData != null
              ? CurrencyUtils.formatCompact(selectedData.amount)
              : CurrencyUtils.formatCompact(widget.totalSpending),
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          selectedData != null ? selectedData.categoryName : 'Total',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLegend() {
    // Show top 5 categories
    final displayData = widget.categoryData.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: displayData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final color = AppColors.getCategoryColor(index);
        final isSelected = _selectedIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = _selectedIndex == index ? null : index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.categoryName,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${data.percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleTap(TapDownDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final center = Offset(box.size.width / 4, box.size.height / 2);
    final tapPosition = details.localPosition - center;

    // Calculate angle from tap position
    final angle = math.atan2(tapPosition.dy, tapPosition.dx);
    var normalizedAngle = angle + math.pi / 2;
    if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

    // Find which segment was tapped
    double startAngle = 0;
    for (int i = 0; i < widget.categoryData.length; i++) {
      final sweepAngle = widget.categoryData[i].percentage / 100 * 2 * math.pi;
      if (normalizedAngle >= startAngle &&
          normalizedAngle < startAngle + sweepAngle) {
        setState(() {
          _selectedIndex = _selectedIndex == i ? null : i;
        });
        return;
      }
      startAngle += sweepAngle;
    }
  }
}

class _SpendingRingPainter extends CustomPainter {
  final List<CategorySpendingData> categoryData;
  final double progress;
  final int? selectedIndex;

  _SpendingRingPainter({
    required this.categoryData,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final strokeWidth = 24.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Draw segments
    double startAngle = -math.pi / 2;

    for (int i = 0; i < categoryData.length; i++) {
      final data = categoryData[i];
      final sweepAngle = (data.percentage / 100) * 2 * math.pi * progress;
      final color = AppColors.getCategoryColor(i);
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = isSelected ? color : color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 6 : strokeWidth
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      // Add glow effect for selected
      if (isSelected) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 16
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
