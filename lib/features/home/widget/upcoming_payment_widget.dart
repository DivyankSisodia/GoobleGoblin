import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/payment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/category.dart';
import '../../payment/screen/new_payment_screen.dart';

class UpcomingPaymentWidget extends ConsumerWidget {
  final Payment payment;
  const UpcomingPaymentWidget({super.key, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine category accent color
    final categoryColor = PredefinedCategories.getColor(payment.category?.icon);
    final category = payment.category;
    final assetPath = category?.assetPath;
    final customSvg = category?.customSvg;
    final hasCustomSvg = customSvg != null && customSvg.trim().isNotEmpty;
    final isSvgAsset =
        assetPath != null && assetPath.toLowerCase().endsWith('.svg');

    Widget buildIcon() {
      if (hasCustomSvg) {
        return SvgPicture.string(customSvg, width: 30, height: 30);
      }
      if (assetPath != null) {
        if (isSvgAsset) {
          return SvgPicture.asset(assetPath, width: 30, height: 30);
        }
        return Image.asset(assetPath, width: 30, height: 30);
      }
      return Icon(Icons.payments_outlined, color: categoryColor, size: 24);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewPaymentScreen(paymentToEdit: payment),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: categoryColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Icon/Image
            Container(
              height: 50,
              width: 50,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: buildIcon(),
            ),
            const Gap(12),
            // Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  payment.note?.isNotEmpty == true ? payment.note! : 'No Note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  payment.category?.label ?? 'Other Payment',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Gap(16),
            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                CurrencyUtils.formatCompact(payment.amount),
                style: GoogleFonts.montserrat(
                  color: categoryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
