import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/category.dart';
import '../../../core/models/card.dart';
import '../../category/provider/category_provider.dart';
import '../../home/provider/cards_provider.dart';
import '../provider/transcation_provider.dart';
import '../../main_screen.dart';

class WalletHistoryScreen extends ConsumerStatefulWidget {
  const WalletHistoryScreen({super.key});

  @override
  ConsumerState<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends ConsumerState<WalletHistoryScreen> {
  String _searchQuery = '';
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Income', 'Expense', 'Pending'];

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final cards = ref.watch(cardsProvider);

    // Filter payments based on search query and tab
    List<Payment> filteredPayments = payments.where((payment) {
      final category = categories.firstWhere(
        (c) => c.id == payment.categoryId,
        orElse: () => Category(label: 'General', icon: ''),
      );

      final noteMatch = payment.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final categoryMatch = category.label.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty || noteMatch || categoryMatch;

      if (!matchesSearch) return false;

      // Tab filtering logic
      if (_selectedTab == 'All') return true;
      if (_selectedTab == 'Pending') return payment.isRecurring;

      // Heuristic for Income/Expense based on category label or note
      bool isIncome = category.label.toLowerCase().contains('income') || category.label.toLowerCase().contains('salary') || (payment.note?.toLowerCase().contains('salary') ?? false) || (payment.note?.toLowerCase().contains('deposit') ?? false);

      if (_selectedTab == 'Income') return isIncome;
      if (_selectedTab == 'Expense') return !isIncome && !payment.isRecurring;

      return true;
    }).toList();

    // Group by date
    Map<String, List<Payment>> groupedPayments = {};
    for (var payment in filteredPayments) {
      final date = payment.date; // "yyyy-MM-dd"
      if (groupedPayments[date] == null) {
        groupedPayments[date] = [];
      }
      groupedPayments[date]!.add(payment);
    }

    // Sort dates descending
    List<String> sortedDates = groupedPayments.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: filteredPayments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: sortedDates.length,
                      itemBuilder: (context, index) {
                        final date = sortedDates[index];
                        final paymentsForDate = groupedPayments[date]!;
                        return _buildDateGroup(date, paymentsForDate, categories, cards);
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
            'Wallet History',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
          ),
          IconButton(
            onPressed: () {
              
            },
            icon: const Icon(CupertinoIcons.share, color: Color(0xFFFF00FF)),
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
          color: const Color(0xFF1E1B29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.search, color: Colors.grey, size: 22),
            const Gap(12),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: Colors.white, fontFamily: GoogleFonts.montserrat().fontFamily),
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            Icon(Icons.tune, color: Colors.white.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _tabs.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final isSelected = _selectedTab == tab;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF00FF), Color(0xFFE91E63)]) : null,
                  color: isSelected ? null : const Color(0xFF1E1B29),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF00FF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14, fontFamily: GoogleFonts.montserrat().fontFamily),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Payment> payments, List<Category> categories, List<BankCard> cards) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    DateTime parsedDate = DateTime.parse(date);
    String dateLabel;
    if (date == today) {
      dateLabel = 'Today, ${DateFormat('MMM dd').format(parsedDate)}';
    } else if (date == yesterday) {
      dateLabel = 'Yesterday, ${DateFormat('MMM dd').format(parsedDate)}';
    } else {
      dateLabel = DateFormat('EEEE, MMM dd').format(parsedDate);
    }

    double dailyTotal = payments.fold(0, (sum, p) {
      final cat = categories.firstWhere(
        (c) => c.id == p.categoryId,
        orElse: () => Category(label: '', icon: ''),
      );
      bool isIncome = cat.label.toLowerCase().contains('income') || cat.label.toLowerCase().contains('salary') || (p.note?.toLowerCase().contains('salary') ?? false);
      return sum + (isIncome ? p.amount : -p.amount);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
              Text(
                'DAILY TOTAL: ${dailyTotal >= 0 ? '+' : '-'}\$${dailyTotal.abs().toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ],
          ),
        ),
        ...payments.map((p) => _buildTransactionTile(p, categories, cards)),
        const Gap(16),
      ],
    );
  }

  Widget _buildTransactionTile(Payment payment, List<Category> categories, List<BankCard> cards) {
    final category = categories.firstWhere(
      (c) => c.id == payment.categoryId,
      orElse: () => Category(label: 'Unknown', icon: ''),
    );
    final card = cards.firstWhere(
      (c) => c.id == payment.cardId,
      orElse: () => BankCard(bankName: 'Card', balance: 0, date: '', type: 'Debit'),
    );

    bool isIncome = category.label.toLowerCase().contains('income') || category.label.toLowerCase().contains('salary') || (payment.note?.toLowerCase().contains('salary') ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B29),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: const BoxDecoration(color: Color(0xFF2A263D), shape: BoxShape.circle),
                padding: const EdgeInsets.all(12),
                child: category.icon.isNotEmpty ? (category.icon.endsWith('.png') ? Image.asset(category.icon, color: Colors.white, colorBlendMode: BlendMode.srcIn) : const Icon(Icons.category, color: Colors.white)) : const Icon(Icons.category, color: Colors.white),
              ),
              Container(
                height: 12,
                width: 12,
                decoration: BoxDecoration(
                  color: isIncome ? const Color(0xFF00FF9D) : Colors.orangeAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E1B29), width: 2),
                ),
              ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.note != null && payment.note!.isNotEmpty ? payment.note! : category.label,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                ),
                const Gap(4),
                Row(
                  children: [
                    Icon(card.isCredit ? Icons.credit_card : Icons.credit_card_outlined, size: 14, color: Colors.grey),
                    const Gap(6),
                    Text(
                      '${card.bankName} •••• ${card.id.toString().padLeft(4, '0')}',
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: GoogleFonts.montserrat().fontFamily),
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
                '${isIncome ? '+' : '-'}\$${payment.amount.toStringAsFixed(2)}',
                style: TextStyle(color: isIncome ? const Color(0xFF00FF9D) : const Color(0xFFFF4B4B), fontSize: 17, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
              const Gap(4),
              Text(
                payment.createdAt != null ? DateFormat('hh:mm a').format(DateTime.parse(payment.createdAt!)) : DateFormat('hh:mm a').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ],
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
          Icon(CupertinoIcons.doc_text_search, size: 64, color: Colors.white.withOpacity(0.1)),
          const Gap(16),
          Text(
            'No transactions found',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontFamily: GoogleFonts.montserrat().fontFamily),
          ),
        ],
      ),
    );
  }
}
