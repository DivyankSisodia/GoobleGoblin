import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../home/widget/custom_segmented_tab_bar.dart';
import '../widget/card_preview_widget.dart';
import '../widget/stacked_cards.dart';
import '../../../utils/add_card_bottomsheet.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(cardsProvider);
    final cards = cardsState.cards;

    // Filter cards based on type (Debit vs Credit)
    //selectedTabIndex 0 -> Debit, 1 -> Credit
    final filteredCards = cards.where((c) {
      if (selectedTabIndex == 0) return c.isDebit || c.isCash;
      return c.isCredit;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Wallet',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else {
              ref.read(navigationIndexProvider.notifier).state = 0;
            }
          },
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        actions: [
          if (filteredCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  final cardType = selectedTabIndex == 0 ? 'Debit' : 'Credit';
                  AppBottomSheet.showManageCardsBottomSheet(
                    context,
                    ref,
                    cardType,
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.primaryNeon,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage\nCards',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const Gap(12),
            Text(
              'Add or organize your payment sources',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(32),

            /// Tabs
            CustomSegmentedTabBar(
              tabs: const ['Debit & Cash', 'Credit Cards'],
              selectedIndex: selectedTabIndex,
              onChanged: (index) {
                setState(() => selectedTabIndex = index);
              },
            ),

            const Gap(32),

            /// Cards area
            Expanded(
              child: Builder(
                builder: (_) {
                  if (cardsState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filteredCards.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedTabIndex == 0
                                ? Icons.account_balance_wallet_outlined
                                : Icons.credit_card_off_outlined,
                            color: Colors.white10,
                            size: 80,
                          ),
                          const Gap(16),
                          Text(
                            'No ${selectedTabIndex == 0 ? 'debit' : 'credit'} cards found',
                            style: GoogleFonts.montserrat(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredCards.length == 1) {
                    final card = filteredCards.first;
                    return Center(
                      child: CardPreviewWidget(
                        bankName: card.bankName,
                        balance: card.displayBalance.toStringAsFixed(2),
                        isCredit: card.isCredit,
                        isSelected: card.isSelected,
                        onTap: () {
                          ref
                              .read(cardsProvider.notifier)
                              .toggleCardSelection(card.id);
                        },
                      ),
                    );
                  }

                  return StackedCardsView(
                    cards: filteredCards,
                    onCardTap: (id) {
                      ref.read(cardsProvider.notifier).toggleCardSelection(id);
                    },
                  );
                },
              ),
            ),

            const Gap(24),

            // Add card button
            InkWell(
              onTap: () {
                AppBottomSheet.showAddCardBottomSheet(context, ref);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryNeon,
                        size: 24,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Source',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Debit, Credit or Cash',
                            style: GoogleFonts.montserrat(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white24),
                  ],
                ),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
