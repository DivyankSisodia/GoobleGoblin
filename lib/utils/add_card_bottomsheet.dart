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
                        final newCard = BankCard(bankName: bankNameController.text.trim(), balance: double.tryParse(amountController.text.trim()) ?? 0.0, date: DateTime.now().toString(), type: selectedTabIndex == 1 ? 'Credit' : 'Debit');
                        // save to db and update state
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
