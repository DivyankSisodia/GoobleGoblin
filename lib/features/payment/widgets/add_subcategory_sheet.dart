import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/category.dart';
import '../../../core/theme/app_theme.dart';

/// Tab for choosing icon source in the add-category sheet.
enum _IconSource { template, customSvg }

class AddSubcategorySheet extends StatefulWidget {
  const AddSubcategorySheet({super.key, required this.categoryId, required this.existingSubcategories});

  final int categoryId;
  final List<SubCategory> existingSubcategories;

  @override
  State<AddSubcategorySheet> createState() => _AddSubcategorySheetState();
}

class _AddSubcategorySheetState extends State<AddSubcategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _svgController = TextEditingController();
  String _selectedTemplateIcon = DefaultCategories.all.first.svgIcon;
  _IconSource _iconSource = _IconSource.template;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _svgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rawLabel = _nameController.text.trim();
    final label = _formatLabel(rawLabel);
    final existingLabels = widget.existingSubcategories
        .map((subcategory) => subcategory.label.trim().toLowerCase())
        .toSet();

    if (label.isEmpty) {
      setState(() => _errorText = 'Please enter a category name');
      return;
    }

    if (existingLabels.contains(label.toLowerCase())) {
      setState(() => _errorText = 'That subcategory already exists');
      return;
    }

    // Build the category based on the chosen icon source
    if (_iconSource == _IconSource.customSvg) {
      final svg = _svgController.text.trim();
      if (svg.isEmpty) {
        setState(
          () => _errorText = 'Please paste SVG code or switch to a template',
        );
        return;
      }
      if (!svg.toLowerCase().contains('<svg')) {
        setState(() => _errorText = 'The text does not look like valid SVG');
        return;
      }
      // Restrict SVG size — keep under ~5 KB for performance
      if (svg.length > 5000) {
        setState(() {
          _errorText =
              'SVG is too large (${svg.length} chars). Keep it under 5,000 characters for best performance.';
        });
        return;
      }

      Navigator.of(context).pop(
        SubCategory(
          categoryId: widget.categoryId,
          label: label,
          svgIcon: svg,
        ),
      );
    } else {
      // Template source
      final selectedTemplate =
          DefaultCategories.all.where((c) => c.svgIcon == _selectedTemplateIcon).firstOrNull ??
          DefaultCategories.all.first;

      Navigator.of(context).pop(
        SubCategory(
          categoryId: widget.categoryId,
          label: label,
          svgIcon: selectedTemplate.svgIcon,
        ),
      );
    }
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
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        (_iconSource == _IconSource.template ||
            _svgController.text.trim().isNotEmpty);

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
            // Drag handle
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
              'Add Subcategory',
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
            // --- Name field ---
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
            // --- Icon source picker ---
            Text(
              'Icon source',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(12),
            // Segmented toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildSourceToggle(
                    label: 'Template',
                    value: _IconSource.template,
                  ),
                  _buildSourceToggle(
                    label: 'Custom SVG',
                    value: _IconSource.customSvg,
                  ),
                ],
              ),
            ),
            const Gap(14),

            // --- Content based on source ---
            if (_iconSource == _IconSource.template)
              _buildTemplatePicker()
            else
              _buildCustomSvgInput(),

            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: canSave ? _submit : null,
                child: const Text('CREATE SUBCATEGORY'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceToggle({
    required String label,
    required _IconSource value,
  }) {
    final isSelected = _iconSource == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _iconSource = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryNeonDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatePicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: DefaultCategories.all
          .map(
            (template) => GestureDetector(
              onTap: () =>
                  setState(() => _selectedTemplateIcon = template.svgIcon),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedTemplateIcon == template.svgIcon
                        ? AppColors.primaryNeon
                        : Colors.white.withOpacity(0.05),
                    width: _selectedTemplateIcon == template.svgIcon ? 2.0 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    template.svgIcon.isNotEmpty
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SvgPicture.string(
                                template.svgIcon,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          )
                        : const Icon(
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
    );
  }

  Widget _buildCustomSvgInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste your SVG markup below',
          style: GoogleFonts.montserrat(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const Gap(10),
        CupertinoTextField(
          controller: _svgController,
          maxLines: 6,
          minLines: 4,
          padding: const EdgeInsets.all(16),
          placeholder:
              '<svg xmlns="http://www.w3.org/2000/svg" ...>\n  ...\n</svg>',
          onChanged: (_) => setState(() => _errorText = null),
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
          placeholderStyle: GoogleFonts.montserrat(
            color: Colors.white24,
            fontSize: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        const Gap(8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tip: Keep SVG under ~5 KB. Use viewBox for scaling.',
              style: GoogleFonts.montserrat(
                color: Colors.white24,
                fontSize: 10,
              ),
            ),
            Text(
              '${_svgController.text.length} / 5,000',
              style: GoogleFonts.montserrat(
                color: _svgController.text.length > 5000
                    ? AppColors.errorRed
                    : Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
