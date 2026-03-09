import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/cards_provider.dart';

/// Shows a Cupertino-style dialog with credit card summary
void showCreditCardSummaryDialog(BuildContext context) {
  showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _CreditCardSummaryDialog(),
  );
}

class _CreditCardSummaryDialog extends ConsumerWidget {
  const _CreditCardSummaryDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(creditCardSummaryProvider);

    return CupertinoAlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.creditcard_fill,
            color: AppColors.primaryNeon,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            'Credit Card Summary',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
      content: summary.hasCreditCards
          ? _SummaryContent(summary: summary)
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No credit cards found.\nAdd a credit card to see the summary.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Done',
            style: GoogleFonts.montserrat(
              color: AppColors.primaryNeon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final CreditCardSummary summary;
  const _SummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          // Overall summary
          _OverviewSection(summary: summary),
          const SizedBox(height: 16),
          // Individual cards
          ...summary.creditCards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CreditCardTile(card: card),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final CreditCardSummary summary;
  const _OverviewSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final usagePct = (summary.overallUsagePercentage * 100).toStringAsFixed(1);
    final usageColor = _getUsageColor(summary.overallUsagePercentage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Usage bar
          Row(
            children: [
              Text(
                'Overall Usage',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$usagePct%',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: usageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.overallUsagePercentage,
              backgroundColor: CupertinoColors.systemGrey4,
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _StatItem(
                label: 'Total Limit',
                value: _formatAmount(summary.totalCreditLimit),
              ),
              _StatItem(
                label: 'Used',
                value: _formatAmount(summary.totalUsedAmount),
                valueColor: AppColors.errorRed,
              ),
              _StatItem(
                label: 'Available',
                value: _formatAmount(summary.totalAvailableCredit),
                valueColor: AppColors.successGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CreditCardTile extends StatelessWidget {
  final BankCard card;
  const _CreditCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final usagePct = (card.creditUsagePercentage * 100).toStringAsFixed(1);
    final usageColor = _getUsageColor(card.creditUsagePercentage);
    final statusLabel = card.creditUsageStatus.label;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              const Icon(
                CupertinoIcons.creditcard,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  card.bankName,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: usageColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: usageColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Usage bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: card.creditUsagePercentage,
              backgroundColor: CupertinoColors.systemGrey4,
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used: ${_formatAmount(card.usedAmount)}',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                '$usagePct%',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: usageColor,
                ),
              ),
              Text(
                'Limit: ${_formatAmount(card.creditLimit)}',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _getUsageColor(double percentage) {
  if (percentage < 0.5) return AppColors.successGreen;
  if (percentage < 0.75) return AppColors.warningYellow;
  return AppColors.errorRed;
}

String _formatAmount(double amount) {
  if (amount >= 100000) {
    return '₹${(amount / 1000).toStringAsFixed(0)}K';
  }
  return '₹${amount.toStringAsFixed(0)}';
}
