import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
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

  bool _isValidUrl = false;

  String _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    final trimmed = value.trim();
    final normalized = _normalizeUrl(trimmed);
    setState(() {
      _isValidUrl = _isValidLink(normalized);
    });
  }

  bool _isValidLink(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }


  Future<void> _saveProduct() async {
    final normalizedUrl = _normalizeUrl(_urlController.text);
    if (!_isValidUrl || normalizedUrl.isEmpty) {
      _showError('Please enter a valid product URL');
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', ''));

    final item = WishlistItem(
      url: normalizedUrl,
      title: _extractTitleFromUrl(normalizedUrl) ?? 'Product',
      imageUrl: '',
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

            const Gap(24),

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
