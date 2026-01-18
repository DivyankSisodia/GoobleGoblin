import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'circular_progress_widget.dart';

class MonthlyBudgetWidget extends StatelessWidget {
  const MonthlyBudgetWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Budget',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400, fontFamily: GoogleFonts.montserrat().fontFamily),
                ),
                Gap(16),
                Text(
                  '₹ 66,660 left',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                ),
                Text(
                  'of ₹ 66,660 limit',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                ),
              ],
            ),
            Gap(20),
            Container(
              padding: const EdgeInsets.all(8),
              // decoration: BoxDecoration(color: AppColors.primaryNeon, borderRadius: BorderRadius.circular(16)),
              child: CircularPercentWidget(
                currentValue: 45645.4,
                totalValue: 66666.66,
                progressColor: AppColors.primaryNeon,
                size: 70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
