import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import '../../../core/colors.dart';

class CategoryChip extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isSVG;

  const CategoryChip({super.key, required this.iconPath, required this.label, required this.isSVG});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.primaryNeonDark.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 🔥 KEY LINE
        children: [
          isSVG ? SvgPicture.asset(iconPath, height: 30, width: 30) : Image.asset(iconPath, height: 30, width: 30),
          const Gap(8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
