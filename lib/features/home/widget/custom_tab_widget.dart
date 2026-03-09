import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/card.dart';
import '../../../core/models/category.dart';
import '../../../core/models/payment.dart';
import '../../../core/app_images.dart';
import '../../../providers/providers.dart';
import 'custom_segmented_tab_bar.dart';

class CustomTabWidget extends ConsumerStatefulWidget {
  const CustomTabWidget({super.key});

  @override
  ConsumerState<CustomTabWidget> createState() => _CustomTabWidgetState();
}

class _CustomTabWidgetState extends ConsumerState<CustomTabWidget> {
  final List<String> tabs = ['Transactions', 'Cards', 'Categories'];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentsProvider).payments;
    final cards = ref.watch(cardsProvider).cards;
    final categories = ref.watch(categoriesProvider).categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomSegmentedTabBar(
            tabs: tabs,
            selectedIndex: selectedIndex,
            onChanged: (index) => setState(() => selectedIndex = index),
          ),
        ),
        const Gap(24),
        _buildTabContent(
          payments: payments,
          cards: cards,
          categories: categories,
        ),
        const Gap(20),
      ],
    );
  }

  // ---------------- TAB SWITCH ----------------

  Widget _buildTabContent({
    required List<Payment> payments,
    required List<BankCard> cards,
    required List<Category> categories,
  }) {
    switch (selectedIndex) {
      case 0:
        return _transactionsTab(payments);
      case 1:
        return _cardsTab(cards);
      case 2:
        return _categoriesTab(categories, payments);
      default:
        return const SizedBox();
    }
  }

  // ---------------- TRANSACTIONS ----------------

  Widget _transactionsTab(List<Payment> payments) {
    if (payments.isEmpty) return _emptyState('No transactions yet');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payments.length > 10
          ? 10
          : payments.length, // Show only recent 10
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final payment = payments[index];
        final category = payment.category;

        return _itemTile(
          title: category?.label ?? 'Other',
          subtitle: payment.note?.isNotEmpty == true
              ? payment.note!
              : 'Payment',
          amount: CurrencyUtils.format(payment.amount),
          highlight: false,
          iconPath: category?.assetPath,
          categoryIcon: category?.icon,
        );
      },
    );
  }

  // ---------------- CARDS ----------------

  Widget _cardsTab(List<BankCard> cards) {
    if (cards.isEmpty) return _emptyState('No sources added');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final card = cards[index];

        String icon = AppImages.debitCard;
        if (card.isCredit) icon = AppImages.creditCard;
        if (card.isCash) icon = AppImages.cash;

        return _itemTile(
          title: card.bankName,
          subtitle: card.accountType.displayName,
          amount: CurrencyUtils.format(card.displayBalance),
          highlight: card.isPrimary,
          iconPath: icon,
          progress: card.isCredit ? card.creditUsagePercentage : null,
          progressColor: card.isCredit
              ? _getCreditColor(card.creditUsagePercentage)
              : null,
        );
      },
    );
  }

  Color _getCreditColor(double percentage) {
    if (percentage < 0.5) return AppColors.successGreen;
    if (percentage < 0.75) return AppColors.warningYellow;
    return AppColors.errorRed;
  }

  // ---------------- CATEGORIES ----------------

  Widget _categoriesTab(List<Category> categories, List<Payment> payments) {
    if (categories.isEmpty) return _emptyState('No categories');

    // Filter categories that have spending
    final spentCategories = categories.where((cat) {
      return payments.any((p) => p.categoryId == cat.id);
    }).toList();

    if (spentCategories.isEmpty) {
      return _emptyState('No spending by category yet');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: spentCategories.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final category = spentCategories[index];
        final relatedPayments = payments
            .where((p) => p.categoryId == category.id)
            .toList();
        final totalAmount = relatedPayments.fold<double>(
          0,
          (sum, p) => sum + p.amount,
        );

        return _itemTile(
          title: category.label,
          subtitle: '${relatedPayments.length} transactions',
          amount: CurrencyUtils.format(totalAmount),
          highlight: false,
          iconPath: category.assetPath,
          categoryIcon: category.icon,
        );
      },
    );
  }

  // ---------------- TILE ----------------

  Widget _itemTile({
    required String title,
    required String subtitle,
    required String amount,
    required bool highlight,
    String? iconPath,
    String? categoryIcon,
    double? progress,
    Color? progressColor,
  }) {
    final themeColor = PredefinedCategories.getColor(categoryIcon);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? AppColors.primaryNeon.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: iconPath != null
                    ? Image.asset(iconPath)
                    : Icon(
                        Icons.category_outlined,
                        color: themeColor,
                        size: 20,
                      ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.montserrat(
                  color: highlight ? AppColors.primaryNeon : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const Gap(12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? AppColors.primaryNeon,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, color: AppColors.surfaceLight, size: 48),
            const Gap(16),
            Text(
              text,
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- STYLES ----------------

final _titleStyle = TextStyle(
  color: Colors.white,
  fontSize: 16,
  fontWeight: FontWeight.bold,
  fontFamily: GoogleFonts.montserrat().fontFamily,
);

final _subtitleStyle = TextStyle(
  color: Colors.white54,
  fontSize: 12,
  fontFamily: GoogleFonts.montserrat().fontFamily,
);
