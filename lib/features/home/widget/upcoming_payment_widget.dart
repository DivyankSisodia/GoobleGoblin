import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_images.dart';
import '../../../core/colors.dart';

class UpcomingPaymentWidget extends StatelessWidget {
  const UpcomingPaymentWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            padding: const EdgeInsets.all(12),
            child: Image.asset(AppImages.netflix, color: const Color(0xFFE50914), colorBlendMode: BlendMode.srcIn),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Netflix',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
              Text(
                'Due Tomorrow',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '₹ 1,499',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}
