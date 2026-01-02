import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/models/card.dart';
import '../features/cards/widget/card_preview_widget.dart';
import '../features/home/provider/cards_provider.dart';
import '../features/home/widget/custom_segmented_tab_bar.dart';

class AppBottomSheet {
  static void showAddCardBottomSheet(BuildContext context, WidgetRef ref) {
    int selectedTabIndex = 0;
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B29),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const Gap(24),
                  Text(
                    'Add New Card',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                  ),
                  const Gap(24),
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
                  const Gap(24),
                  CardPreviewWidget(bankName: bankNameController.text, balance: amountController.text, isCredit: selectedTabIndex == 1),
                  const Gap(24),
                  _buildBottomSheetTextField(controller: bankNameController, hint: 'Bank Name', icon: Icons.account_balance_rounded, onChanged: (val) => setState(() {})),
                  const Gap(16),
                  _buildBottomSheetTextField(controller: amountController, hint: 'Current Bank Amount', icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number, onChanged: (val) => setState(() {})),
                  const Gap(32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newCard = BankCard(
                          bankName: bankNameController.text.trim(),
                          balance: double.tryParse(amountController.text.trim()) ?? 0.0,
                          date: DateTime.now().toString(),
                          type: selectedTabIndex == 1 ? 'Credit' : 'Debit',
                        );
                        await ref.read(cardsProvider.notifier).addCard(newCard);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNeon,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Add Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showManageCardsBottomSheet(BuildContext context, WidgetRef ref, String type) {
    BankCard? selectedCard;
    bool isEditing = false;
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, _) {
                final cards = ref.watch(cardsProvider);
                final filteredCards = cards.where((c) => c.type == type).toList();

                return Container(
                  padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1B29),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                      const Gap(24),
                      Text(
                        isEditing ? 'Edit Card' : 'Select Card to Edit',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                      ),
                      const Gap(24),
                      if (!isEditing)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                          child: filteredCards.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Text('No $type cards found', style: TextStyle(color: Colors.white54, fontSize: 16)),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filteredCards.length,
                                  separatorBuilder: (context, index) => const Gap(12),
                                  itemBuilder: (context, index) {
                                    final card = filteredCards[index];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedCard = card;
                                          isEditing = true;
                                          bankNameController.text = card.bankName;
                                          amountController.text = card.balance.toString();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryNeon.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.credit_card, color: AppColors.primaryNeon, size: 20),
                                            ),
                                            const Gap(16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(card.bankName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                                  Text('Balance: ₹${card.balance}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right, color: Colors.white24),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        )
                      else ...[
                        CardPreviewWidget(
                          bankName: bankNameController.text,
                          balance: amountController.text,
                          isCredit: selectedCard?.isCredit ?? false,
                        ),
                        const Gap(24),
                        _buildBottomSheetTextField(
                          controller: bankNameController,
                          hint: 'Bank Name',
                          icon: Icons.account_balance_rounded,
                          onChanged: (val) => setState(() {}),
                        ),
                        const Gap(16),
                        _buildBottomSheetTextField(
                          controller: amountController,
                          hint: 'Current Bank Amount',
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() {}),
                        ),
                        const Gap(32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => isEditing = false),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primaryNeon.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text('Back', style: TextStyle(color: AppColors.primaryNeon)),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (selectedCard != null) {
                                    final updatedCard = selectedCard!.copyWith(
                                      bankName: bankNameController.text.trim(),
                                      balance: double.tryParse(amountController.text.trim()) ?? 0.0,
                                    );
                                    await ref.read(cardsProvider.notifier).updateCard(updatedCard);
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryNeon,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                ),
                                child: const Text('Update Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

Widget _buildBottomSheetTextField({required TextEditingController controller, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, Function(String)? onChanged}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      prefixIcon: Icon(icon, color: AppColors.primaryNeon),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primaryNeon.withOpacity(0.5)),
      ),
    ),
  );
}
