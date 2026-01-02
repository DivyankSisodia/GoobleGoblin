import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/app_images.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/features/home/provider/cards_provider.dart';
import 'package:gooble_goblin/features/payment/widgets/amount_widget.dart';
import 'package:gooble_goblin/features/payment/widgets/custom_chip_widget.dart';
import 'package:gooble_goblin/features/payment/widgets/custom_date_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/widget/card_preview_widget.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  const NewPaymentScreen({super.key});

  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  DateTime _selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    // Add some dummy cards for demonstration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardsNotifier = ref.read(cardsProvider.notifier);
      if (ref.read(cardsProvider).isEmpty) {
        cardsNotifier.addCard(CardModel(id: '1', bankName: 'Axis Bank', balance: '10000', isCredit: false));
        cardsNotifier.addCard(CardModel(id: '2', bankName: 'HDFC Bank', balance: '25000', isCredit: true));
        cardsNotifier.addCard(CardModel(id: '3', bankName: 'ICICI Bank', balance: '15000', isCredit: false));
        cardsNotifier.addCard(CardModel(id: '4', bankName: 'SBI Bank', balance: '30000', isCredit: true));
        cardsNotifier.addCard(CardModel(id: '5', bankName: 'Kotak Bank', balance: '20000', isCredit: false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final cardsNotifier = ref.read(cardsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'New Payment',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(20),
            AmountInput(),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Payment Method',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(20),
            SizedBox(
              height: 220,
              child: cards.isEmpty
                  ? Center(
                      child: Text('No cards available', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.5))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return CardPreviewWidget(
                          bankName: card.bankName,
                          balance: card.balance,
                          isCredit: card.isCredit,
                          isSelected: card.isSelected,
                          onTap: () {
                            cardsNotifier.toggleCardSelection(card.id);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: cards.length,
                    ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Date',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: DatePickerPill()),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Category',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: [
                CategoryChip(iconPath: AppImages.bagShopping, label: 'Shopping', isSVG: true),
                CategoryChip(iconPath: AppImages.bike, label: 'Bike', isSVG: true),
                CategoryChip(iconPath: AppImages.bagShopping, label: 'Entertainment', isSVG: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
