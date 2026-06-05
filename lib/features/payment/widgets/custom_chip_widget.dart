import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import '../../../core/colors.dart';

class CategoryChip extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isSVG;
  final bool isSelected;
  final VoidCallback onTap;
  final String? customSvg; // Inline SVG markup

  const CategoryChip({
    super.key,
    required this.iconPath,
    required this.label,
    required this.isSVG,
    required this.isSelected,
    required this.onTap,
    this.customSvg,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomSvg = customSvg != null && customSvg!.trim().isNotEmpty;
    final hasAssetIcon = iconPath.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeonDark
              : AppColors.primaryNeonDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCustomSvg)
              SvgPicture.string(customSvg!, height: 30, width: 30)
            else if (hasAssetIcon)
              isSVG
                  ? SvgPicture.asset(iconPath, height: 30, width: 30)
                  : Image.asset(iconPath, height: 30, width: 30)
            else
              const Icon(Icons.category_rounded, color: Colors.white, size: 24),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(
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
