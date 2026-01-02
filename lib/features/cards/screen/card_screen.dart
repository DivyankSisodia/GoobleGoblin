import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../home/provider/cards_provider.dart';
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
    final cards = ref.watch(cardsProvider);

    final filteredCards = cards.where((c) => c.isCredit == (selectedTabIndex == 1)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.background,
        title: Text(
          'My Wallet',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        actions: [
          InkWell(
            onTap: () {
              if (selectedTabIndex == 0) {
                AppBottomSheet.showManageCardsBottomSheet(context, ref, 'Debit');
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryNeonDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryNeonDark.withOpacity(0.7), width: 1, style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.surface),
                  Gap(6),
                  Text('Edit', style: TextStyle(color: AppColors.surface, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily)),
                ],
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
              style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            const Gap(12),
            Text(
              'Add or create new cards',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            const Gap(24),

            /// Tabs
            Container(
              decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(30)),
              child: CustomSegmentedTabBar(
                tabs: const ['Debit Card', 'Credit Card'],
                selectedIndex: selectedTabIndex,
                onChanged: (index) {
                  setState(() => selectedTabIndex = index);
                },
                backgroundColor: AppColors.surfaceLight.withOpacity(0.1),
              ),
            ),

            const Gap(24),

            /// Cards area
            Builder(
              builder: (_) {
                /// 0 cards
                if (filteredCards.isEmpty) {
                  return Center(
                    child: Text('No cards found', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                  );
                }
            
                /// 1 card
                if (filteredCards.length == 1) {
                  final card = filteredCards.first;
                  return Center(
                    child: CardPreviewWidget(
                      bankName: card.bankName,
                      balance: card.balance.toString(),
                      isCredit: card.isCredit,
                      isSelected: card.isSelected,
                      onTap: () {
                        ref.read(cardsProvider.notifier).toggleCardSelection(card.id);
                      },
                    ),
                  );
                }
            
                /// 2+ cards → stacked
                return StackedCardsView(
                  cards: filteredCards,
                  onCardTap: (id) {
                    ref.read(cardsProvider.notifier).toggleCardSelection(id);
                  },
                );
              },
            ),
            Gap(24),
            GestureDetector(
              onTap: () {
                AppBottomSheet.showAddCardBottomSheet(context, ref);
              },
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.surfaceLight, AppColors.surface]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryNeonDark.withOpacity(0.7), width: 1, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    /// Plus icon
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.12)),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),

                    const SizedBox(width: 16),

                    /// Text
                    Expanded(
                      child: Text(
                        'Add another card',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
                      ),
                    ),

                    /// Arrow
                    Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.6), size: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
