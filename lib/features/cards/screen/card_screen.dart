import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

import '../../../core/colors.dart';
import '../../home/widget/custom_segmented_tab_bar.dart';
import '../widget/card_preview_widget.dart';
import '../../home/provider/cards_provider.dart';

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
    final filteredCards = cards.where((card) => card.isCredit == (selectedTabIndex == 1)).toList();

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
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage\nCards',
              style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            Gap(12),
            Text(
              'Add or create new cards',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            Gap(24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(30)),
              child: CustomSegmentedTabBar(
                tabs: const ['Debit Card', 'Credit Card'],
                selectedIndex: selectedTabIndex,
                onChanged: (index) {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                backgroundColor: AppColors.surfaceLight.withOpacity(0.1),
              ),
            ),
            Gap(24),
            Expanded(
              child: filteredCards.isEmpty
                  ? Center(
                      child: Text(
                        'No cards found',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredCards.length,
                      separatorBuilder: (context, index) => Gap(16),
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        return CardPreviewWidget(
                          bankName: card.bankName,
                          balance: card.balance.toString(),
                          isCredit: card.isCredit,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
