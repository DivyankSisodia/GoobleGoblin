import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    required this.selectedSubcategoryId,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
    required this.onAddCategory,
    required this.onAddSubcategory,
    required this.onReloadCategories,
  });

  final CategoriesState categoriesState;
  final int? selectedCategoryId;
  final int? selectedSubcategoryId;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<int?> onSubcategorySelected;
  final VoidCallback onAddCategory;
  final VoidCallback onAddSubcategory;
  final Future<void> Function() onReloadCategories;

  @override
  Widget build(BuildContext context) {
    final categories = categoriesState.categories;

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyCategoryState(
          errorMessage: categoriesState.errorMessage,
          onReloadCategories: onReloadCategories,
          onAddCategory: onAddCategory,
        ),
      );
    }

    if (selectedCategoryId != null) {
      final selectedCategory = categories.firstWhere(
        (c) => c.id == selectedCategoryId,
        orElse: () => categories.first,
      );

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onCategorySelected(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                  const Gap(16),
                  if (selectedCategory.svgIcon.isNotEmpty)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SvgPicture.string(
                          selectedCategory.svgIcon,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.category_rounded, color: Colors.white, size: 24),
                  const Gap(12),
                  Text(
                    selectedCategory.label,
                    style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...selectedCategory.subcategories.map(
                  (sub) => CategoryChip(
                    label: sub.label,
                    isSelected: selectedSubcategoryId == sub.id,
                    onTap: () => onSubcategorySelected(sub.id),
                    svgIcon: sub.svgIcon,
                  ),
                ),
                _AddCategoryActionChip(
                  label: 'Add Subcategory',
                  onTap: onAddSubcategory,
                ),
              ],
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ...categories.map(
            (cat) => CategoryChip(
              label: cat.label,
              isSelected: false,
              onTap: () => onCategorySelected(cat.id),
              svgIcon: cat.svgIcon,
            ),
          ),
          _AddCategoryActionChip(
            label: 'Add Category',
            onTap: onAddCategory,
          ),
        ],
      ),
    );
  }
}

class _AddCategoryActionChip extends StatelessWidget {
  const _AddCategoryActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
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
              label,
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
