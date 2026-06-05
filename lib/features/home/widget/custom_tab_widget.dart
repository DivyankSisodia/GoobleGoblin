import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      itemCount: payments.length > 10 ? 10 : payments.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final payment = payments[index];
        final category = payment.category;
        final isIncome = payment.isIncome;

        final title = payment.note?.isNotEmpty == true
            ? payment.note!
            : (category?.label ?? 'Other');
        final subtitle = isIncome
            ? 'Income · ${category?.label ?? 'Received'}'
            : (payment.note?.isNotEmpty == true
                  ? category?.label ?? 'Payment'
                  : 'Payment');
        final amountText = isIncome
            ? '+ ${CurrencyUtils.format(payment.amount)}'
            : CurrencyUtils.format(payment.amount);
        final amountColor = isIncome ? AppColors.successGreen : Colors.white;

        return _itemTile(
          title: title,
          subtitle: subtitle,
          amount: amountText,
          highlight: false,
          iconPath: category?.assetPath,
          categoryIcon: category?.icon,
          customSvg: category?.customSvg,
          amountColor: amountColor,
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final category = categories[index];
        final relatedPayments = payments
            .where((p) => p.categoryId == category.id)
            .toList();
        final totalAmount = relatedPayments.fold<double>(
          0,
          (sum, p) => sum + p.amount,
        );
        final paymentCount = relatedPayments.length;

        return GestureDetector(
          onLongPress: () =>
              _showDeleteCategorySheet(category, paymentCount, relatedPayments),
          child: _itemTile(
            title: category.label,
            subtitle: paymentCount > 0
                ? '$paymentCount transaction${paymentCount == 1 ? '' : 's'}'
                : 'No transactions',
            amount: paymentCount > 0 ? CurrencyUtils.format(totalAmount) : '',
            highlight: false,
            iconPath: category.assetPath,
            categoryIcon: category.icon,
            customSvg: category.customSvg,
          ),
        );
      },
    );
  }

  void _showDeleteCategorySheet(
    Category category,
    int paymentCount,
    List<Payment> relatedPayments,
  ) {
    final isPredefined = category.isPredefined;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            Text(
              category.label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Text(
              paymentCount > 0
                  ? '$paymentCount transaction${paymentCount == 1 ? '' : 's'} linked'
                  : 'No transactions linked',
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Gap(24),
            if (isPredefined)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Built-in categories cannot be deleted.',
                  style: GoogleFonts.montserrat(
                    color: AppColors.warningYellow,
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              if (paymentCount > 0) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showReassignDialog(category, relatedPayments);
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Move & Delete'),
                  ),
                ),
                const Gap(12),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmAndDelete(category, relatedPayments);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    paymentCount > 0 ? 'Delete Anyway' : 'Delete Category',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                  ),
                ),
              ),
            ],
            const Gap(8),
          ],
        ),
      ),
    );
  }

  void _showReassignDialog(
    Category fromCategory,
    List<Payment> paymentsToMove,
  ) {
    final allCategories = ref
        .read(categoriesProvider)
        .categories
        .where((c) => c.id != fromCategory.id)
        .toList();

    Category? targetCategory;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Move ${paymentsToMove.length} transaction${paymentsToMove.length == 1 ? '' : 's'}',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Move transactions from "${fromCategory.label}" to:',
                style: GoogleFonts.montserrat(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Gap(16),
              ...allCategories.map(
                (cat) => RadioListTile<Category>(
                  value: cat,
                  groupValue: targetCategory,
                  title: Text(
                    cat.label,
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  activeColor: AppColors.primaryNeon,
                  onChanged: (c) => setDialogState(() => targetCategory = c),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: targetCategory == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _moveAndDelete(
                        fromCategory,
                        targetCategory!,
                        paymentsToMove,
                      );
                    },
              child: const Text('MOVE & DELETE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveAndDelete(
    Category from,
    Category to,
    List<Payment> payments,
  ) async {
    final paymentsNotifier = ref.read(paymentsProvider.notifier);

    for (final payment in payments) {
      final updated = payment.copyWith(
        categoryId: to.id!,
        categoryUuid: to.uuid,
      );
      await paymentsNotifier.updatePayment(updated);
    }

    await ref.read(categoriesProvider.notifier).deleteCategory(from.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Moved ${payments.length} transaction${payments.length == 1 ? '' : 's'} to "${to.label}" & deleted "${from.label}"',
          ),
        ),
      );
    }
  }

  void _confirmAndDelete(Category category, List<Payment> relatedPayments) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete "${category.label}"?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          relatedPayments.isNotEmpty
              ? 'This will remove the category. ${relatedPayments.length} transaction${relatedPayments.length == 1 ? '' : 's'} will lose their category label.'
              : 'This category has no transactions. It will be permanently removed.',
          style: GoogleFonts.montserrat(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(categoriesProvider.notifier)
                  .deleteCategory(category.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${category.label}" deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
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
    String? customSvg,
    double? progress,
    Color? progressColor,
    Color? amountColor,
  }) {
    final themeColor = PredefinedCategories.getColor(categoryIcon);
    final hasCustomSvg = customSvg != null && customSvg.trim().isNotEmpty;
    final isSvgAsset =
        iconPath != null && iconPath.toLowerCase().endsWith('.svg');

    Widget buildIcon() {
      if (hasCustomSvg) {
        return SvgPicture.string(customSvg, width: 28, height: 28);
      }
      if (iconPath != null) {
        if (isSvgAsset) {
          return SvgPicture.asset(iconPath, width: 28, height: 28);
        }
        return Image.asset(iconPath, width: 28, height: 28);
      }
      return Icon(Icons.payment, color: themeColor, size: 24);
    }

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
                child: buildIcon(),
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
                  color:
                      amountColor ??
                      (highlight ? AppColors.primaryNeon : Colors.white),
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
