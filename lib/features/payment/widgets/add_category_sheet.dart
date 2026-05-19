import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/category.dart';
import '../../../core/theme/app_theme.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key, required this.existingCategories});

  final List<Category> existingCategories;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIcon = PredefinedCategories.all.first.icon;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rawLabel = _nameController.text.trim();
    final label = _formatLabel(rawLabel);
    final existingLabels = widget.existingCategories
        .map((category) => category.label.trim().toLowerCase())
        .toSet();

    if (label.isEmpty) {
      setState(() => _errorText = 'Please enter a category name');
      return;
    }

    if (existingLabels.contains(label.toLowerCase())) {
      setState(() => _errorText = 'That category already exists');
      return;
    }

    if (PredefinedCategories.isSystemManagedLabel(label)) {
      setState(() {
        _errorText =
            'Use that brand in the note field instead. Keep categories broader.';
      });
      return;
    }

    final selectedTemplate =
        PredefinedCategories.getByIcon(_selectedIcon) ??
        PredefinedCategories.all.first;

    Navigator.of(context).pop(
      Category(
        label: label,
        icon: selectedTemplate.icon,
        assetPath: selectedTemplate.assetPath,
        isPredefined: false,
      ),
    );
  }

  String _formatLabel(String value) {
    final collapsed = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return '';

    return collapsed
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const Gap(22),
            Text(
              'Add Category',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(6),
            Text(
              'Create a broader bucket. Brand names like Amazon or Swiggy should stay in notes.',
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const Gap(20),
            CupertinoTextField(
              controller: _nameController,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              placeholder: 'e.g. Healthcare, Gifts, Pets',
              onChanged: (_) => setState(() => _errorText = null),
              style: GoogleFonts.montserrat(color: Colors.white),
              placeholderStyle: GoogleFonts.montserrat(color: Colors.white38),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _errorText == null
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.errorRed.withValues(alpha: 0.45),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const Gap(10),
              Text(
                _errorText!,
                style: GoogleFonts.montserrat(
                  color: AppColors.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Gap(20),
            Text(
              'Pick a visual style',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: PredefinedCategories.all
                  .map(
                    (template) => GestureDetector(
                      onTap: () => setState(() => _selectedIcon = template.icon),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedIcon == template.icon
                              ? AppColors.primaryNeonDark
                              : AppColors.surfaceLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _selectedIcon == template.icon
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.05),
                            width: _selectedIcon == template.icon ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (template.assetPath != null)
                              Image.asset(
                                template.assetPath!,
                                height: 24,
                                width: 24,
                              )
                            else
                              const Icon(
                                Icons.category_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            const Gap(8),
                            Text(
                              template.label,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: canSave ? _submit : null,
                child: const Text('CREATE CATEGORY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
