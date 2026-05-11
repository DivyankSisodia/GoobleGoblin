import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/DB/db_helper.dart';
import '../../../providers/providers.dart';

import 'circular_progress_widget.dart';

class MonthlyBudgetWidget extends ConsumerWidget {
  const MonthlyBudgetWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(monthlyBudgetProvider);
    final paymentsState = ref.watch(paymentsProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);

    final spent = paymentsState.currentMonthSpending;

    return budgetAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (budget) {
        final remaining = (budget - spent).clamp(0.0, double.infinity);
        final usedFraction = budget > 0
            ? (spent / budget).clamp(0.0, 1.0)
            : 0.0;

        final fontFamily = GoogleFonts.montserrat().fontFamily;

        return GestureDetector(
          onTap: () => _showEditBudgetDialog(context, ref, budget),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Monthly Budget',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              fontFamily: fontFamily,
                            ),
                          ),
                          const Gap(8),
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ],
                      ),
                      const Gap(16),
                      Text(
                        isVisible
                            ? '${CurrencyUtils.format(remaining)} left'
                            : '•••••••',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                        ),
                      ),
                      Text(
                        isVisible
                            ? 'of ${CurrencyUtils.format(budget)} limit'
                            : 'of ••••••• limit',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: CircularPercentWidget(
                      currentValue: spent,
                      totalValue: budget > 0 ? budget : 1,
                      progressColor: usedFraction >= 0.9
                          ? AppColors.errorRed
                          : usedFraction >= 0.7
                          ? Colors.orange
                          : AppColors.primaryNeon,
                      size: 70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show a dialog to edit the monthly budget
  Future<void> _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    double currentBudget,
  ) async {
    final controller = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );

    final newBudget = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Monthly Budget',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.montserrat(
                color: AppColors.primaryNeon,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              hintText: 'Enter budget amount',
              hintStyle: GoogleFonts.montserrat(color: Colors.white30),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryNeon.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text);
                if (parsed != null && parsed > 0) {
                  Navigator.of(ctx).pop(parsed);
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.montserrat(color: AppColors.primaryNeon),
              ),
            ),
          ],
        );
      },
    );

    if (newBudget != null && newBudget != currentBudget) {
      await DatabaseHelper.instance.setMonthlyBudget(newBudget);
      ref.invalidate(monthlyBudgetProvider);
    }
  }
}
