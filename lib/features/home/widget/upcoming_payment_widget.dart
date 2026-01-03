import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/models/payment.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_images.dart';
import '../../../core/colors.dart';

class UpcomingPaymentWidget extends ConsumerWidget {
  final Payment payment;
  const UpcomingPaymentWidget({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
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
            child: Image.asset(
              payment.category?.icon ?? AppImages.netflix,
              color: payment.category?.icon == null ? const Color(0xFFE50914) : AppColors.textPrimary,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                payment.category?.label ?? 'Subscription',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
              Text(
                'Due ${payment.date}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '₹ ${payment.amount.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}
