import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/card.dart';
import '../../../core/models/category.dart';
import '../../../core/models/payment.dart';
import '../../../core/services/local_db_backup_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/providers.dart';
import '../../main_screen.dart';
import '../../wishlist/screen/add_product_screen.dart';
import '../../wishlist/screen/wishlist_screen.dart';
import 'new_payment_screen.dart';

class WalletHistoryScreen extends ConsumerStatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  ConsumerState<WalletHistoryScreen> createState() =>
      _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends ConsumerState<WalletHistoryScreen> {
  final List<String> _tabs = ['All', 'Wishlist', 'Recurring', 'Recent'];
  final LocalDbBackupService _backupService = LocalDbBackupService();
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);
    final cardsState = ref.watch(cardsProvider);

    // Compute the correct payment list for the current tab
    final Map<String, List<Payment>> paymentsByDate;
    switch (_selectedTabIndex) {
      case 2: // Recurring – only recurring transactions, search still applies
        final recurringAll = paymentsState.payments.where((p) => p.isRecurring);
        final recurringFiltered = paymentsState.searchQuery.isEmpty
            ? recurringAll
            : recurringAll.where((p) {
                final query = paymentsState.searchQuery.toLowerCase();
                final note = p.note?.toLowerCase() ?? '';
                final cat = p.category?.label.toLowerCase() ?? '';
                return note.contains(query) || cat.contains(query);
              });
        paymentsByDate = _groupByDate(recurringFiltered.toList());
        break;
      case 3: // Recent – last 7 days from filtered set
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        final recent = paymentsState.filteredPayments.where((p) {
          final date = AppDateUtils.parseIso(p.date);
          return date != null && date.isAfter(cutoff);
        });
        paymentsByDate = _groupByDate(recent.toList());
        break;
      default: // All
        paymentsByDate = paymentsState.paymentsByDate;
    }

    final sortedDates = paymentsByDate.keys.toList()
      ..sort((a, b) {
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
              child: _selectedTabIndex == 1
                  ? const WishlistScreen(showAppBar: false)
                  : paymentsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryNeon,
                      ),
                    )
                  : sortedDates.isEmpty
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
                        return _buildDateGroup(
                          dateKey,
                          paymentsForDate,
                          cardsState.cards,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              ),
              backgroundColor: AppColors.primaryNeon,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.black,
                size: 32,
              ),
            )
          : null,
    );
  }

  /// Groups a flat list of payments by ISO date key (yyyy-MM-dd).
  Map<String, List<Payment>> _groupByDate(List<Payment> payments) {
    final grouped = <String, List<Payment>>{};
    for (final payment in payments) {
      final date = AppDateUtils.parseIso(payment.date);
      if (date != null) {
        final key = AppDateUtils.formatIso(date);
        grouped.putIfAbsent(key, () => []).add(payment);
      }
    }
    return grouped;
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
                onPressed: () => _showBackupSheet(),
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

  void _showBackupSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local DB Backup',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Text(
                'Export everything as JSON, or import an older JSON backup and remap it to the new categories.',
                style: GoogleFonts.montserrat(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Gap(20),
              _buildBackupAction(
                icon: CupertinoIcons.arrow_down_doc,
                title: 'Export JSON',
                subtitle: 'Creates a backup file and copies JSON to clipboard',
                onTap: () {
                  Navigator.pop(context);
                  _exportBackup();
                },
              ),
              const Gap(12),
              _buildBackupAction(
                icon: CupertinoIcons.arrow_up_doc,
                title: 'Import JSON',
                subtitle: 'Paste a backup JSON and restore it safely',
                onTap: () {
                  Navigator.pop(context);
                  _showImportDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryNeon),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(3),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    try {
      final export = await _backupService.exportToJsonFile();
      await Clipboard.setData(ClipboardData(text: export.json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup exported and copied to clipboard: ${export.path}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export backup: $e')));
    }
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Import Backup JSON?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This replaces the current local database. Old categories like Amazon, Netflix, Swiggy, and Zomato will be remapped to the new broad categories.',
                style: GoogleFonts.montserrat(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Gap(14),
              TextField(
                controller: controller,
                minLines: 6,
                maxLines: 10,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste backup JSON here...',
                  hintStyle: GoogleFonts.montserrat(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              final json = controller.text.trim();
              if (json.isEmpty) return;
              Navigator.pop(context);
              await _importBackup(json);
            },
            child: Text(
              'Import',
              style: GoogleFonts.montserrat(
                color: AppColors.primaryNeon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _importBackup(String json) async {
    try {
      await _backupService.importFromJsonString(json);
      await Future.wait([
        ref.read(categoriesProvider.notifier).loadCategories(),
        ref.read(cardsProvider.notifier).loadCards(),
        ref.read(paymentsProvider.notifier).loadPayments(),
        ref.read(wishlistProvider.notifier).loadWishlist(),
        ref.read(analyticsProvider.notifier).refresh(),
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup imported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import backup: $e')));
    }
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
                  fillColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                  hintText: 'Search for anything...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
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

  Widget _buildDateGroup(
    String dateKey,
    List<Payment> payments,
    List<BankCard> cards,
  ) {
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
        ...payments.map((p) {
          final card = cards.where((c) => c.id == p.cardId).firstOrNull;
          return _buildTransactionTile(p, card);
        }),
        const Gap(8),
      ],
    );
  }

  Widget _buildTransactionTile(Payment payment, BankCard? card) {
    final cat = payment.category;
    final subcat = payment.subcategory;
    final isIncome = payment.isIncome;

    // Income: green, Expense: white/red based
    final amountColor = isIncome ? AppColors.successGreen : Colors.white;
    final amountPrefix = isIncome ? '+ ' : '';

    // Build the payment source label and icon
    final (sourceIcon, sourceLabel, sourceColor) = card == null
        ? (Icons.credit_card_outlined, 'Unknown', Colors.white38)
        : card.isCash
        ? (Icons.money_rounded, 'Cash', const Color(0xFF4CAF50))
        : card.isCredit
        ? (Icons.credit_card_rounded, card.bankName, const Color(0xFF9C27B0))
        : (Icons.account_balance_rounded, card.bankName, AppColors.primaryNeon);

    return Slidable(
      key: ValueKey(payment.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          Gap(8),
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
          Gap(8),
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildPaymentIcon(cat, subcat, AppColors.primaryNeon),
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
                  const Gap(2),
                  Text(
                    subcat != null
                        ? '${cat?.label ?? 'Other'} • ${subcat.label}'
                        : (cat?.label ?? 'Other'),
                    style: GoogleFonts.montserrat(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(4),
                  // Payment source chip
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sourceIcon, size: 10, color: sourceColor),
                      const Gap(4),
                      Flexible(
                        child: Text(
                          sourceLabel,
                          style: GoogleFonts.montserrat(
                            color: sourceColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyUtils.format(payment.amount)}',
                  style: GoogleFonts.montserrat(
                    color: amountColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isIncome)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'INCOME',
                      style: GoogleFonts.montserrat(
                        color: AppColors.successGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildPaymentIcon(Category? cat, SubCategory? subcat, Color fallbackColor) {
    final iconString = subcat != null && subcat.svgIcon.isNotEmpty
        ? subcat.svgIcon
        : cat?.svgIcon;

    if (iconString == null || iconString.isEmpty) {
      return Icon(Icons.payment, color: fallbackColor, size: 24);
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SvgPicture.string(
          iconString,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
