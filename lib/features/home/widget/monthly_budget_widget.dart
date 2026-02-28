import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
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

        return Column(
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
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: fontFamily,
                      ),
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
        );
      },
    );
  }
}
