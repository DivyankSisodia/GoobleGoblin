import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../widgets/wishlist_card.dart';
import 'add_product_screen.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const WishlistScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);
    final items = wishlistState.items;

    final content = wishlistState.isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryNeon),
          )
        : items.isEmpty
        ? _buildEmptyState()
        : _buildWishlist(items);

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Product Wishlist',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView
                  ? CupertinoIcons.list_bullet
                  : CupertinoIcons.square_grid_2x2,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        ),
        backgroundColor: AppColors.primaryNeon,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.heart_fill,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const Gap(20),
          Text(
            'Your wishlist is empty',
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(10),
          Text(
            'Add products you want to buy later!',
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlist(items) {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            WishlistCard(item: items[index], isGrid: true),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Gap(16),
      itemBuilder: (context, index) =>
          WishlistCard(item: items[index], isGrid: false),
    );
  }
}
