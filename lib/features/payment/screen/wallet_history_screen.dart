import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/category.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/providers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../main_screen.dart';
import 'new_payment_screen.dart';

class WalletHistoryScreen extends ConsumerStatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  ConsumerState<WalletHistoryScreen> createState() =>
      _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends ConsumerState<WalletHistoryScreen> {
  final List<String> _tabs = ['All', 'Recurring', 'Recent'];
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);
    final paymentsByDate = paymentsState.paymentsByDate;
    final sortedDates = paymentsByDate.keys.toList();

    // Sort dates descending
    sortedDates.sort((a, b) {
      final dateA = AppDateUtils.parseIso(a) ?? DateTime.now();
      final dateB = AppDateUtils.parseIso(b) ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: paymentsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryNeon,
                      ),
                    )
                  : paymentsState.payments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final dateKey = sortedDates[index];
                        final paymentsForDate = paymentsByDate[dateKey]!;
                        return _buildDateGroup(dateKey, paymentsForDate);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              ref.read(navigationIndexProvider.notifier).state = 0;
            },
            icon: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
          Text(
            'History',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _confirmDeleteAll(),
                icon: const Icon(
                  CupertinoIcons.trash,
                  color: AppColors.errorRed,
                ),
              ),
              IconButton(
                onPressed: () => _showSeedConfirmation(),
                icon: const Icon(
                  CupertinoIcons.lab_flask,
                  color: AppColors.primaryNeon,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  CupertinoIcons.share,
                  color: AppColors.primaryNeon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSeedConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Seed Test Data?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will clear all current data and replace it with over 40 sample transactions, multiple cards, and a budget for testing. Recommended for first-time walkthroughs.',
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(paymentsProvider.notifier)
                  .seedTestData();
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test data seeded successfully!'),
                  ),
                );
              }
            },
            child: Text(
              'Seed Now',
              style: GoogleFonts.montserrat(
                color: AppColors.primaryNeon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Wipe Everything?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will delete all your cards, payments, and budgets. You\'ll start fresh.',
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Data',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(paymentsProvider.notifier).deleteAllPayments();
              // Re-onboard if needed
            },
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search, color: Colors.grey, size: 22),
            const Gap(12),
            Expanded(
              child: TextField(
                onChanged: (value) =>
                    ref.read(paymentsProvider.notifier).setSearchQuery(value),
                style: GoogleFonts.montserrat(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for anything...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final isSelected = _selectedTabIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryNeon
                      : AppColors.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryNeon.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: GoogleFonts.montserrat(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateGroup(String dateKey, List<Payment> payments) {
    final date = AppDateUtils.parseIso(dateKey) ?? DateTime.now();
    final dateLabel = AppDateUtils.isToday(date)
        ? 'Today'
        : (AppDateUtils.isToday(date.add(const Duration(days: 1)))
              ? 'Yesterday'
              : AppDateUtils.formatDisplay(date));

    final groupTotal = payments.fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'TOTAL: ${CurrencyUtils.format(groupTotal)}',
                style: GoogleFonts.montserrat(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        ...payments.map((p) => _buildTransactionTile(p)),
        const Gap(8),
      ],
    );
  }

  Widget _buildTransactionTile(Payment payment) {
    final cat = payment.category;
    final categoryColor = PredefinedCategories.getColor(cat?.icon);

    return Slidable(
      key: ValueKey(payment.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NewPaymentScreen(paymentToEdit: payment),
                ),
              );
            },
            backgroundColor: AppColors.primaryNeon,
            foregroundColor: Colors.black,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (context) => _confirmDeletePayment(payment),
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: cat?.assetPath != null
                  ? Image.asset(cat!.assetPath!)
                  : Icon(Icons.payment, color: categoryColor, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.note?.isNotEmpty == true
                        ? payment.note!
                        : (cat?.label ?? 'Expense'),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cat?.label ?? 'Other',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyUtils.format(payment.amount),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (payment.isRecurring)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'RECURRING',
                      style: GoogleFonts.montserrat(
                        color: AppColors.primaryNeon,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePayment(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Transaction?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this ${payment.amount} transaction? This cannot be undone.',
          style: GoogleFonts.montserrat(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (payment.id != null) {
                await ref
                    .read(paymentsProvider.notifier)
                    .deletePayment(payment.id!);
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 64, color: AppColors.surfaceLight),
          const Gap(24),
          Text(
            'Nothing found here',
            style: GoogleFonts.montserrat(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
