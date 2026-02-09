import 'package:any_link_preview/any_link_preview.dart';
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
            // Link Preview Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AnyLinkPreview(
                link: item.url,
                cache: const Duration(days: 7),
                backgroundColor: Colors.transparent,
                errorWidget: Container(
                  height: isGrid ? 100 : 150,
                  color: Colors.white10,
                  child: const Center(
                    child: Icon(CupertinoIcons.link, color: Colors.white24),
                  ),
                ),
                errorBody: 'Could not load preview',
                errorTitle: 'Link Preview',
                previewHeight: isGrid ? 120 : 160,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? 'No Title',
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
