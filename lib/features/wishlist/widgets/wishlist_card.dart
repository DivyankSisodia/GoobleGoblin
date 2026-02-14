import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/wishlist_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../screen/product_details_screen.dart';

class WishlistCard extends ConsumerWidget {
  final WishlistItem item;
  final bool isGrid;

  const WishlistCard({super.key, required this.item, required this.isGrid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(item: item),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple Link Placeholder
            Container(
              height: isGrid ? 100 : 60,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.link,
                  size: 40,
                  color: Colors.white24,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.notes?.isEmpty ?? true ? item.title ?? 'No Title' : item.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  if (item.price != null)
                    Text(
                      CurrencyUtils.format(item.price!),
                      style: GoogleFonts.montserrat(
                        color: AppColors.primaryNeon,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!isGrid) ...[
                    const Gap(8),
                    Text(
                      item.notes ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.dateAdded.split('T')[0],
                        style: GoogleFonts.montserrat(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                      if (item.isPurchased)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryNeon,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
