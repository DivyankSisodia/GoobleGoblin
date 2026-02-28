import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/providers.dart';

class TotalBalanceWidget extends ConsumerWidget {
  const TotalBalanceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);

    // Calculate trend from analytics if available
    final trendValue = analyticsState.analytics?.totalSpending ?? 0;
    final isPositive = trendValue >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 16.0, top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(balanceVisibilityProvider.notifier).state =
                        !isVisible;
                  },
                  icon: Icon(
                    isVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    color: Colors.white54,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isVisible ? CurrencyUtils.format(totalBalance) : '•••••••',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositive
                                ? AppColors.successGreen
                                : AppColors.errorRed)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          (isPositive
                                  ? AppColors.successGreen
                                  : AppColors.errorRed)
                              .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                        size: 14,
                      ),
                      const Gap(6),
                      Text(
                        'This Month',
                        style: GoogleFonts.montserrat(
                          color: isPositive
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Text(
                  isVisible
                      ? 'Spent ${CurrencyUtils.formatCompact(trendValue)}'
                      : 'Spent •••',
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }
}
