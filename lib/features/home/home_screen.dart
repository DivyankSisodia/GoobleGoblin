import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/core/models/card.dart';
import 'package:gooble_goblin/features/experiment/exp1.dart';
import 'package:gooble_goblin/features/home/widget/custom_tab_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gooble_goblin/features/cards/widget/card_preview_widget.dart';
import 'package:gooble_goblin/features/home/widget/custom_segmented_tab_bar.dart';
import 'provider/cards_provider.dart';
import 'widget/monthly_budget_widget.dart';
import 'widget/total_balance_widget.dart';
import 'widget/upcoming_payment_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;
  const HomeScreen({super.key, this.isFirstTime = false});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showAddCardBottomSheet(context);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: Center(
          child: Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(color: AppColors.primaryNeon, shape: BoxShape.circle),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 24,
              icon: const Icon(CupertinoIcons.chart_bar, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gooble Goblin",
              style: TextStyle(color: AppColors.primaryNeon, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
            Text(
              "Hello Divyank",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
            ),
          ],
        ),
        actions: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(color: AppColors.primaryNeon, shape: BoxShape.circle),
            child: IconButton(
              onPressed: () {
                NotificationService notifi = NotificationService.instance;
                notifi.scheduleNotification(
                  title: 'Notification',
                  body: 'This is a notification',
                  id: 1,
                  scheduledDate: DateTime.now().add(const Duration(seconds: 10)),
                );
              },
              icon: Icon(CupertinoIcons.person, color: Colors.black, size: 24),
            ),
          ),
          Gap(20),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryNeon,
        shape: const CircleBorder(),
        onPressed: () {
          _showAddCardBottomSheet(context);
        },
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      // Matching AppColors.background
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
              child: TotalBalanceWidget(),
            ),
            Gap(20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
              child: MonthlyBudgetWidget(),
            ),
            Gap(24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Payments',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                  ),
                ],
              ),
            ),
            Gap(16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (index) => const UpcomingPaymentWidget(),
                ),
              ),
            ),
            const Gap(32),
            const CustomTabWidget(),
          ],
        ),
      ),
    );
  }

  void _showAddCardBottomSheet(BuildContext context) {
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
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
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
                  CardPreviewWidget(
                    bankName: bankNameController.text,
                    balance: amountController.text,
                    isCredit: selectedTabIndex == 1,
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

  Widget _buildBottomSheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
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
}

