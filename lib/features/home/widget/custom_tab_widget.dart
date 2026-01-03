import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_images.dart';
import '../../../core/colors.dart';
import '../../../core/models/card.dart';
import '../../../core/models/category.dart';
import '../../../core/models/payment.dart';
import '../../category/provider/category_provider.dart';
import '../../payment/provider/transcation_provider.dart';
import '../provider/cards_provider.dart';
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
    final payments = ref.watch(transactionProvider);
    final cards = ref.watch(cardsProvider);
    final categories = ref.watch(categoryProvider);

    return Column(
      children: [
        CustomSegmentedTabBar(tabs: tabs, selectedIndex: selectedIndex, onChanged: (index) => setState(() => selectedIndex = index)),
        const Gap(24),
        _buildTabContent(payments: payments, cards: cards, categories: categories),
        const Gap(20),
      ],
    );
  }

  // ---------------- TAB SWITCH ----------------

  Widget _buildTabContent({required List<Payment> payments, required List<BankCard> cards, required List<Category> categories}) {
    switch (selectedIndex) {
      case 0:
        return _transactionsTab(payments, cards, categories);
      case 1:
        return _cardsTab(cards);
      case 2:
        return _categoriesTab(categories, payments);
      default:
        return const SizedBox();
    }
  }

  // ---------------- TRANSACTIONS ----------------

  Widget _transactionsTab(List<Payment> payments, List<BankCard> cards, List<Category> categories) {
    if (payments.isEmpty) return _emptyState('No transactions yet');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final payment = payments[index];

        return _itemTile(
          title: _categoryLabel(payment.categoryId, categories),
          subtitle: _cardName(payment.cardId, cards),
          amount: '₹ ${payment.amount.toStringAsFixed(0)}',
          highlight: false,
          icon: _categoryIcon(payment.categoryId, categories),
        );
      },
    );
  }

  // ---------------- CARDS ----------------

  Widget _cardsTab(List<BankCard> cards) {
    if (cards.isEmpty) return _emptyState('No cards added');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final card = cards[index];

        return _itemTile(title: card.bankName, subtitle: card.isPrimary ? 'Primary Card' : card.type, amount: '₹ ${card.balance.toStringAsFixed(0)}', highlight: card.isPrimary, icon: card.type == 'Debit' ? AppImages.debitCard : AppImages.creditCard);
      },
    );
  }

  Widget _categoriesTab(List<Category> categories, List<Payment> payments) {
    if (categories.isEmpty) return _emptyState('No categories added');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (_, index) {
        final category = categories[index];

        final relatedPayments = payments.where((p) => p.categoryId == category.id).toList();

        final totalAmount = relatedPayments.fold<double>(0, (sum, p) => sum + p.amount);

        return _itemTile(title: category.label, subtitle: '${relatedPayments.length} transactions', amount: '₹ ${totalAmount.toStringAsFixed(0)}', highlight: false, icon: category.icon);
      },
    );
  }

  // ---------------- TILE ----------------

  Widget _itemTile({required String title, required String subtitle, required String amount, required bool highlight, String? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.3),
        gradient: highlight ? AppColors.progressGradient : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? AppColors.primaryNeon : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            padding: const EdgeInsets.all(10),
            child: Image.asset(icon ?? AppImages.bagShopping, color: AppColors.textPrimary, colorBlendMode: BlendMode.srcIn),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle),
                Text(subtitle, style: _subtitleStyle),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(color: highlight ? AppColors.primaryNeon : Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  String _categoryLabel(int id, List<Category> categories) {
    try {
      return categories.firstWhere((c) => c.id == id).label;
    } catch (_) {
      return 'Unknown';
    }
  }

  String? _categoryIcon(int id, List<Category> categories) {
    try {
      return categories.firstWhere((c) => c.id == id).icon;
    } catch (_) {
      return null;
    }
  }

  String _cardName(int id, List<BankCard> cards) {
    try {
      return cards.firstWhere((c) => c.id == id).bankName;
    } catch (_) {
      return 'Unknown';
    }
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.white54, fontFamily: GoogleFonts.montserrat().fontFamily),
        ),
      ),
    );
  }
}

// ---------------- STYLES ----------------

final _titleStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily);

final _subtitleStyle = TextStyle(color: Colors.white54, fontSize: 12, fontFamily: GoogleFonts.montserrat().fontFamily);
