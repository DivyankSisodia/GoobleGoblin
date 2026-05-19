import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/categories_provider.dart';
import 'custom_chip_widget.dart';

class PaymentCategorySection extends StatelessWidget {
  const PaymentCategorySection({
    super.key,
    required this.categoriesState,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onAddCategory,
    required this.onReloadCategories,
  });

  final CategoriesState categoriesState;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final VoidCallback onAddCategory;
  final Future<void> Function() onReloadCategories;

  @override
  Widget build(BuildContext context) {
    final categories = categoriesState.categories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: categories.isNotEmpty
          ? Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...categories.map(
                  (cat) => CategoryChip(
                    iconPath: cat.assetPath ?? '',
                    label: cat.label,
                    isSVG: false,
                    isSelected: selectedCategoryId == cat.id,
                    onTap: () => onCategorySelected(cat.id),
                  ),
                ),
                _AddCategoryActionChip(onTap: onAddCategory),
              ],
            )
          : _EmptyCategoryState(
              errorMessage: categoriesState.errorMessage,
              onReloadCategories: onReloadCategories,
              onAddCategory: onAddCategory,
            ),
    );
  }
}

class _AddCategoryActionChip extends StatelessWidget {
  const _AddCategoryActionChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const Gap(8),
            Text(
              'Add Category',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({
    required this.errorMessage,
    required this.onReloadCategories,
    required this.onAddCategory,
  });

  final String? errorMessage;
  final Future<void> Function() onReloadCategories;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories are not available yet',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(6),
          Text(
            errorMessage?.isNotEmpty == true
                ? errorMessage!
                : 'Tap below to repair and reload the predefined categories.',
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onReloadCategories,
                    child: const Text('RELOAD'),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onAddCategory,
                    child: const Text('ADD ONE'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
