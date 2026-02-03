import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/models/card.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/money_source_card.dart';
import '../widgets/add_account_sheet.dart';
import '../../main_screen.dart';

/// Main onboarding screen with animated multi-step flow
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  final _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pageController = PageController();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);

    if (state.isLastStep) {
      _completeOnboarding();
    } else {
      notifier.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.completeOnboarding();

    // Invalidate the provider so that _AppRouter switches to MainScreen
    ref.invalidate(isOnboardingNeededProvider);

    if (success && mounted) {
      // Navigate to main screen
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Step indicator
                  StepIndicator(
                    currentStep: state.currentStep,
                    totalSteps: state.totalSteps,
                  ),
                  const Gap(16),
                  // Progress text
                  Text(
                    'Step ${state.currentStep + 1} of ${state.totalSteps}',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(),
                  _buildBudgetStep(),
                  _buildMoneySourcesStep(),
                ],
              ),
            ),

            // Bottom buttons
            _buildBottomButtons(state),
          ],
        ),
      ),
    );
  }

  /// Step 1: Welcome
  Widget _buildWelcomeStep() {
    return FadeTransition(
      opacity: _animationController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.analyticsGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const Gap(40),
            // Welcome text
            Text(
              'Welcome to',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.analyticsGradient.createShader(bounds),
              child: Text(
                'GoobleGoblin',
                style: GoogleFonts.montserrat(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Gap(24),
            Text(
              'Your personal finance companion\nwith a touch of magic ✨',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(48),
            // Features list
            _buildFeatureItem(Icons.insights_rounded, 'Smart Analytics'),
            const Gap(16),
            _buildFeatureItem(Icons.category_rounded, 'Easy Categorization'),
            const Gap(16),
            _buildFeatureItem(Icons.notifications_rounded, 'Spending Alerts'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryNeon, size: 20),
        ),
        const Gap(12),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Step 2: Budget Setup
  Widget _buildBudgetStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: AppColors.primaryNeon,
            ),
          ),
          const Gap(32),
          Text(
            "What's your monthly budget?",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Gap(12),
          Text(
            "We'll help you stay on track",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(48),
          // Budget input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryNeon.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '₹',
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNeon,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: '50,000',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0;
                      ref
                          .read(onboardingProvider.notifier)
                          .setMonthlyBudget(amount);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          // Quick amount chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickAmountChip(25000),
              _buildQuickAmountChip(50000),
              _buildQuickAmountChip(75000),
              _buildQuickAmountChip(100000),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount) {
    return GestureDetector(
      onTap: () {
        _budgetController.text = amount.toString();
        ref
            .read(onboardingProvider.notifier)
            .setMonthlyBudget(amount.toDouble());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Text(
          CurrencyUtils.formatCompact(amount.toDouble()),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Step 3: Money Sources
  Widget _buildMoneySourcesStep() {
    final state = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(20),
          Center(
            child: Text(
              "Add your money sources",
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Gap(8),
          Center(
            child: Text(
              "Track all your accounts in one place",
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Gap(32),

          // Cash Section
          _buildSectionHeader('💵 Cash', 'Track your physical cash'),
          const Gap(12),
          if (state.cashBalance != null)
            MoneySourceCard(
              icon: Icons.money_rounded,
              title: 'Cash in Hand',
              subtitle: CurrencyUtils.format(state.cashBalance!),
              color: AppColors.successGreen,
              onDelete: () =>
                  ref.read(onboardingProvider.notifier).setCashBalance(null),
            )
          else
            _buildAddButton(
              'Add Cash',
              Icons.add_rounded,
              () => _showAddCashSheet(),
            ),

          const Gap(24),

          // Debit Cards Section
          _buildSectionHeader(
            '💳 Bank Accounts',
            'Debit cards & savings accounts',
          ),
          const Gap(12),
          ...state.debitCards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MoneySourceCard(
                icon: Icons.account_balance_rounded,
                title: card.bankName,
                subtitle: CurrencyUtils.format(card.balance),
                color: AppColors.accentBlue,
                onDelete: () => ref
                    .read(onboardingProvider.notifier)
                    .removeDebitCard(index),
              ),
            );
          }),
          _buildAddButton(
            'Add Bank Account',
            Icons.add_rounded,
            () => _showAddAccountSheet(AccountType.debit),
          ),

          const Gap(24),

          // Credit Cards Section
          _buildSectionHeader('💎 Credit Cards', 'Track credit limits & usage'),
          const Gap(12),
          ...state.creditCards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MoneySourceCard(
                icon: Icons.credit_card_rounded,
                title: card.bankName,
                subtitle:
                    '${CurrencyUtils.format(card.usedAmount)} / ${CurrencyUtils.format(card.creditLimit)}',
                color: AppColors.accentMagenta,
                progress: card.creditUsagePercentage,
                onDelete: () => ref
                    .read(onboardingProvider.notifier)
                    .removeCreditCard(index),
              ),
            );
          }),
          _buildAddButton(
            'Add Credit Card',
            Icons.add_rounded,
            () => _showAddAccountSheet(AccountType.credit),
          ),

          const Gap(100), // Bottom padding for scroll
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryNeon.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryNeon, size: 20),
            const Gap(8),
            Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.primaryNeon,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCashSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddAccountSheet(
        type: AccountType.cash,
        onSave: (card) {
          ref.read(onboardingProvider.notifier).setCashBalance(card.balance);
        },
      ),
    );
  }

  void _showAddAccountSheet(AccountType type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AddAccountSheet(
        type: type,
        onSave: (card) {
          if (type == AccountType.debit) {
            ref.read(onboardingProvider.notifier).addDebitCard(card);
          } else {
            ref.read(onboardingProvider.notifier).addCreditCard(card);
          }
        },
      ),
    );
  }

  /// Bottom navigation buttons
  Widget _buildBottomButtons(OnboardingState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            if (!state.isFirstStep)
              Expanded(
                child: GestureDetector(
                  onTap: _goToPreviousStep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Back',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!state.isFirstStep) const Gap(16),
            // Next/Finish button
            Expanded(
              flex: state.isFirstStep ? 1 : 2,
              child: GestureDetector(
                onTap: state.canProceed ? _goToNextStep : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: state.canProceed
                        ? AppColors.analyticsGradient
                        : null,
                    color: state.canProceed ? null : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: state.canProceed
                        ? [
                            BoxShadow(
                              color: AppColors.primaryNeon.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            state.isLastStep ? "Let's Go! 🚀" : 'Continue',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: state.canProceed
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
