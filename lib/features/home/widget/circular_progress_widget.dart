import 'package:flutter/material.dart';
import 'package:gooble_goblin/core/colors.dart';

class CircularPercentWidget extends StatelessWidget {
  final double currentValue;
  final double totalValue;
  final double size;
  final Color progressColor;
  final Color backgroundColor;

  const CircularPercentWidget({
    super.key,
    required this.currentValue,
    required this.totalValue,
    this.size = 120.0,
    this.progressColor = Colors.blue,
    this.backgroundColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentage (0.0 to 1.0)
    // We use .clamp to ensure the value stays between 0% and 100%
    double percentage = (totalValue > 0) ? (currentValue / totalValue).clamp(0.0, 1.0) : 0.0;
    int displayPercent = (percentage * 100).toInt();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The background track
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 8,
            valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
          ),
          // The actual progress
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: 8,
            strokeCap: StrokeCap.round, // Rounded edges
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          // The text in the middle
          Center(
            child: Text(
              '$displayPercent%',
              style: TextStyle(
                fontSize: size * 0.2, // Scales text based on widget size
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}