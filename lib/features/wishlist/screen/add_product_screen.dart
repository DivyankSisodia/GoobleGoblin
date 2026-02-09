import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ADD THIS
import '../../../core/models/wishlist_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _urlController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  Metadata? _metadata;
  bool _isValidUrl = false;
  bool _isLoadingPreview = false;
  String? _errorMessage;
  String? _imageUrl; // Track image separately for better control

  @override
  void dispose() {
    _urlController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) async {
    final trimmed = value.trim();
    setState(() {
      _isValidUrl = AnyLinkPreview.isValidLink(trimmed);
      _isLoadingPreview = _isValidUrl;
      _errorMessage = null;
      if (!_isValidUrl) {
        _metadata = null;
        _imageUrl = null;
      }
    });

    if (_isValidUrl) {
      try {
        final meta = await AnyLinkPreview.getMetadata(
          link: trimmed,
          userAgent: _browserUserAgent,
          headers: _defaultHeaders,
          cache: const Duration(minutes: 15),
        );
        if (mounted) {
          setState(() {
            _metadata = meta;
            _imageUrl = _getValidImageUrl(meta); // Custom image extraction
            _isLoadingPreview = false;
            _errorMessage = null;
          });
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Metadata fetch error: $e');
          setState(() {
            _isLoadingPreview = false;
            _errorMessage = 'Preview unavailable for this link';
            _metadata = null;
            _imageUrl = null;
          });
        }
      }
    }
  }

  // NEW: Robust image URL extraction with Amazon-specific logic
  String? _getValidImageUrl(Metadata? meta) {
    if (meta?.image?.isNotEmpty == true) {
      // Direct metadata image (most reliable)
      return meta!.image;
    }
    
    // Amazon-specific image extraction from URL or description
    final url = _urlController.text.trim();
    if (url.contains('amazon') && url.contains('dp/')) {
      // Try extracting ASIN and construct Amazon image URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.contains('dp')) {
        final asinIndex = pathSegments.indexOf('dp') + 1;
        if (asinIndex < pathSegments.length) {
          final asin = pathSegments[asinIndex];
          return 'https://m.media-amazon.com/images/I/31${asin.substring(0, 1)}xxxx.jpg'; // Fallback pattern
        }
      }
    }
    
    // Fallback: try og:image from description or return null
    if (meta?.desc?.contains('og:image') == true) {
    // ✅ CORRECT SYNTAX: Use r'' raw string + proper escaping
    final ogMatch = RegExp(r"""og:image["']?\s*[:=]\s*["']([^"']+)""")
        .firstMatch(meta!.desc ?? '');
    if (ogMatch != null && ogMatch.group(1)?.isNotEmpty == true) {
      return ogMatch.group(1)?.trim();
    }
  }
    
    return null;
  }

  static const String _browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'DNT': '1',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  Future<void> _saveProduct() async {
    if (!_isValidUrl || _urlController.text.trim().isEmpty) {
      _showError('Please enter a valid product URL');
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', ''));

    final item = WishlistItem(
      url: _urlController.text.trim(),
      title: _metadata?.title ??
          _extractTitleFromUrl(_urlController.text.trim()) ??
          'Product',
      imageUrl: _imageUrl ?? '', // Use our validated image URL
      price: price,
      notes: _notesController.text.trim(),
      dateAdded: DateTime.now().toIso8601String(),
    );

    final success = await ref.read(wishlistProvider.notifier).addItem(item);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product added to wishlist!'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      _showError('Failed to save product');
    }
  }

  String? _extractTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.contains('dp') && uri.pathSegments.length > 1) {
        return 'Amazon Product - ${uri.pathSegments[1].toUpperCase()}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add Product',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Product URL'),
            const Gap(12),
            _buildTextField(
              controller: _urlController,
              hint: 'https://www.amazon.in/dp/B0ABC123XYZ...',
              onChanged: _onUrlChanged,
              prefixIcon: CupertinoIcons.link,
            ),
            const Gap(24),

            // NEW: Custom Preview Section (replaces AnyLinkPreview)
            if (_isValidUrl) ...[
              _buildCustomPreview(),
              const Gap(24),
            ],

            _buildSectionTitle('Price (Optional)'),
            const Gap(12),
            _buildTextField(
              controller: _priceController,
              hint: '₹2999.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: CupertinoIcons.money_dollar_circle,
            ),
            const Gap(24),

            _buildSectionTitle('Notes (Optional)'),
            const Gap(12),
            _buildTextField(
              controller: _notesController,
              hint: 'Why do you want this product?',
              maxLines: 3,
            ),
            const Gap(40),

            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // NEW: Custom preview with robust image handling
  Widget _buildCustomPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryNeon.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (_metadata?.title?.isNotEmpty == true) ...[
            Text(
              _metadata!.title!,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(12),
          ],

          // NEW: Robust Image Preview (THIS FIXES BROKEN IMAGES)
          _buildImagePreview(),
          const Gap(12),

          // Description
          if (_metadata?.desc?.isNotEmpty == true) ...[
            Text(
              _metadata!.desc!,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // NEW: THE KEY FIX - Custom image preview with fallbacks
  Widget _buildImagePreview() {
    if (_isLoadingPreview) {
      return _buildImagePlaceholder(loading: true);
    }

    if (_errorMessage != null || _imageUrl == null || _imageUrl!.isEmpty) {
      return _buildImagePlaceholder(loading: false);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
        imageUrl: _imageUrl!,
        placeholder: (context, url) => _buildImagePlaceholder(loading: true),
        errorWidget: (context, url, error) => _buildImagePlaceholder(loading: false),
        httpHeaders: _defaultHeaders,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  // NEW: Unified placeholder widget
  Widget _buildImagePlaceholder({required bool loading}) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_search_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
                const Gap(8),
                Text(
                  _errorMessage ?? 'No image preview available',
                  style: GoogleFonts.montserrat(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: CupertinoTextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        padding: const EdgeInsets.all(16),
        placeholder: hint,
        style: GoogleFonts.montserrat(color: Colors.white),
        placeholderStyle: GoogleFonts.montserrat(color: Colors.white38),
        prefix: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(prefixIcon, color: Colors.white38, size: 20),
              )
            : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    final isSaveEnabled = _isValidUrl && _urlController.text.trim().isNotEmpty;

    return InkWell(
      onTap: isSaveEnabled ? _saveProduct : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isSaveEnabled
              ? AppColors.analyticsGradient
              : AppColors.analyticsGradient.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNeon.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: isSaveEnabled ? Colors.black : Colors.black54,
            ),
            const Gap(12),
            Text(
              'SAVE TO WISHLIST',
              style: GoogleFonts.montserrat(
                color: isSaveEnabled ? Colors.black : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
