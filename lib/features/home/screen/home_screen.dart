import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../utils/add_card_bottomsheet.dart';
import '../widget/custom_tab_widget.dart';
import '../widget/monthly_budget_widget.dart';
import '../widget/total_balance_widget.dart';
import '../widget/upcoming_payment_widget.dart';

class HomeScreen extends ConsumerWidget {
  final bool isFirstTime;
  const HomeScreen({super.key, this.isFirstTime = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringPayments = ref.watch(recurringPaymentsProvider);

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
            decoration: const BoxDecoration(
              color: AppColors.primaryNeon,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 24,
              icon: const Icon(CupertinoIcons.chart_bar, color: Colors.black),
              onPressed: () {
                // Potential shortcut to Analytics or hidden Dev Tools
              },
            ),
          ),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gooble Goblin",
              style: GoogleFonts.montserrat(
                color: AppColors.primaryNeon,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Your Personal Finance",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(
              color: AppColors.primaryNeon,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                // Profile or hidden settings shortcut
              },
              icon: const Icon(
                CupertinoIcons.person,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const Gap(20),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(paymentsProvider.notifier).loadPayments();
          await ref.read(cardsProvider.notifier).loadCards();
        },
        color: AppColors.primaryNeon,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.1),
                  ),
                ),
                child: const TotalBalanceWidget(),
              ),
              const Gap(20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryNeon.withValues(alpha: 0.1),
                  ),
                ),
                child: const MonthlyBudgetWidget(),
              ),
              const Gap(24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Payments',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'See All',
                      style: GoogleFonts.montserrat(
                        color: AppColors.primaryNeon,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Upcoming payments with new list-based provider
              if (recurringPayments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      "No upcoming payments",
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: recurringPayments
                        .map((p) => UpcomingPaymentWidget(payment: p))
                        .toList(),
                  ),
                ),

              const Gap(32),
              const CustomTabWidget(),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }
}
