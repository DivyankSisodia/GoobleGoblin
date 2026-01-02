import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/features/experiment/exp1.dart';
import 'package:gooble_goblin/features/home/widget/custom_tab_widget.dart';
import 'package:gooble_goblin/utils/add_card_bottomsheet.dart';
import 'package:google_fonts/google_fonts.dart';
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
            AppBottomSheet.showAddCardBottomSheet(context, ref);
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
          AppBottomSheet.showAddCardBottomSheet(context, ref);
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
}


