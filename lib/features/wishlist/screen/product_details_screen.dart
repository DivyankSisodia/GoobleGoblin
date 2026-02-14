import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/wishlist_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/providers.dart';
import '../../payment/screen/new_payment_screen.dart';
import 'webview_screen.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final WishlistItem item;

  const ProductDetailsScreen({super.key, required this.item});

  void _openInWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: item.url,
          title: item.title ?? 'Product',
        ),
      ),
    );
  }

  void _deleteItem(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'Are you sure you want to remove this from your wishlist?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      final success = await ref
          .read(wishlistProvider.notifier)
          .deleteItem(item.id!);
      if (success && context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const Gap(32),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    _buildSectionTitle('Notes'),
                    const Gap(12),
                    _buildNoteCard(),
                    const Gap(32),
                  ],
                  _buildActions(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _deleteItem(context, ref),
          icon: const CircleAvatar(
            backgroundColor: Colors.black26,
            child: Icon(
              CupertinoIcons.trash,
              color: AppColors.errorRed,
              size: 20,
            ),
          ),
        ),
        const Gap(8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.surfaceLight,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.link,
                  size: 60,
                  color: Colors.white24,
                ),
                SizedBox(height: 16),
                Text(
                  'Product Link',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title ?? 'No Title',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (item.isPurchased)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'PURCHASED',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryNeon,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const Gap(8),
        if (item.price != null)
          Text(
            CurrencyUtils.format(item.price!),
            style: GoogleFonts.montserrat(
              color: AppColors.primaryNeon,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        const Gap(16),
        InkWell(
          onTap: () => _openInWebView(context),
          child: Row(
            children: [
              const Icon(CupertinoIcons.link, color: Colors.white38, size: 16),
              const Gap(8),
              Expanded(
                child: Text(
                  item.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: Colors.white24,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        item.notes!,
        style: GoogleFonts.montserrat(
          color: Colors.white70,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildActionButton(
          label: item.isPurchased ? 'ALREADY BOUGHT' : 'MARK AS PURCHASED',
          icon: CupertinoIcons.check_mark_circled,
          onTap: item.isPurchased
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewPaymentScreen(fromWishlist: item),
                  ),
                ),
          isPrimary: true,
        ),
        const Gap(16),
        _buildActionButton(
          label: 'OPEN IN WEBVIEW',
          icon: CupertinoIcons.globe,
          onTap: () => _openInWebView(context),
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: isPrimary ? AppColors.analyticsGradient : null,
            color: !isPrimary
                ? AppColors.surfaceLight.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: !isPrimary
                ? Border.all(color: Colors.white.withValues(alpha: 0.05))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.black : Colors.white,
                size: 20,
              ),
              const Gap(12),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: isPrimary ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
