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
    final displayBalance = ref.watch(displayBalanceProvider);
    final debitOnly = ref.watch(debitBalanceOnlyProvider);
    final cashBalance = ref.watch(cashBalanceProvider);
    final creditUsed = ref.watch(creditUsedAmountProvider);
    final hasCreditTxns = ref.watch(hasCreditTransactionsProvider);
    final showCash = ref.watch(balanceIncludeCashProvider);
    final showCredit = ref.watch(balanceSubtractCreditProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);
    final analyticsState = ref.watch(analyticsProvider);

    // Trend
    final trendValue = analyticsState.analytics?.totalSpending ?? 0;
    final isPositive = trendValue >= 0;

    // Determine which breakdown description to show under the main amount
    String displayLabel;
    if (showCash && showCredit) {
      displayLabel = 'Debit + Cash - Credit';
    } else if (showCash) {
      displayLabel = 'Debit + Cash';
    } else if (showCredit) {
      displayLabel = 'Debit - Credit';
    } else {
      displayLabel = 'Debit Cards';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row with title and action icons ──
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 8.0, top: 16.0),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cash toggle — only show if cash accounts exist
                    if (cashBalance > 0)
                      _ToggleIcon(
                        iconAsset: 'assets/images/cash.png',
                        tooltip: 'Include Cash',
                        isActive: showCash,
                        onTap: () {
                          ref.read(balanceIncludeCashProvider.notifier).state =
                              !showCash;
                        },
                      ),
                    // Credit toggle — only show if credit txns exist
                    if (hasCreditTxns)
                      _ToggleIcon(
                        icon: CupertinoIcons.creditcard,
                        tooltip: 'Subtract Credit',
                        isActive: showCredit,
                        onTap: () {
                          ref
                                  .read(balanceSubtractCreditProvider.notifier)
                                  .state =
                              !showCredit;
                        },
                      ),
                    const Gap(4),
                    // Eye toggle
                    IconButton(
                      onPressed: () {
                        ref.read(balanceVisibilityProvider.notifier).state =
                            !isVisible;
                      },
                      icon: Icon(
                        isVisible
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: Colors.white54,
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Main balance amount ──
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isVisible ? CurrencyUtils.format(displayBalance) : '•••••••',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Label under the main amount ──
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 4.0),
            child: Text(
              isVisible ? displayLabel : '•••••••',
              style: GoogleFonts.montserrat(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Gap(16),

          // ── Breakdown rows ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Debit Balance (always shown)
                _BreakdownRow(
                  label: 'Debit Balance',
                  amount: debitOnly,
                  isVisible: isVisible,
                ),
                // Cash line (if toggle is on)
                if (showCash && cashBalance > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _BreakdownRow(
                      label: 'Cash Balance',
                      amount: cashBalance,
                      isVisible: isVisible,
                      isAddition: true,
                    ),
                  ),
                // Credit line (if toggle is on)
                if (showCredit && creditUsed > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _BreakdownRow(
                      label: 'Credit Used',
                      amount: creditUsed,
                      isVisible: isVisible,
                      isAddition: false,
                    ),
                  ),
              ],
            ),
          ),

          const Gap(16),

          // ── Trend / spending pill ──
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

// ────────────────────────────────────────────────────────────────
// Small toggle icon button used in the header row
// ────────────────────────────────────────────────────────────────
class _ToggleIcon extends StatelessWidget {
  final String? iconAsset;
  final IconData? icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleIcon({
    this.iconAsset,
    this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  }) : assert(iconAsset != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryNeon.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryNeon.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Center(
            child: iconAsset != null
                ? Image.asset(
                    iconAsset!,
                    width: 18,
                    height: 18,
                    color: isActive ? AppColors.primaryNeon : Colors.white38,
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: isActive ? AppColors.primaryNeon : Colors.white38,
                  ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// A single breakdown row: label + amount
// ────────────────────────────────────────────────────────────────
class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isVisible;
  final bool isAddition;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.isVisible,
    this.isAddition = true,
  });

  @override
  Widget build(BuildContext context) {
    final sign = isAddition ? '+' : '−';
    final signColor = isAddition ? AppColors.successGreen : AppColors.errorRed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              alignment: Alignment.center,
              child: Text(
                sign,
                style: GoogleFonts.montserrat(
                  color: signColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          isVisible ? CurrencyUtils.format(amount) : '•••••',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
