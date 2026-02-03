import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/providers.dart';
import '../widgets/amount_widget.dart';
import '../widgets/custom_chip_widget.dart';
import '../widgets/custom_date_widget.dart';
import '../../cards/widget/card_preview_widget.dart';
import '../widgets/frequency_dropdown.dart';
import '../widgets/reoccuring_payment_widget.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  const NewPaymentScreen({super.key});

  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  int? _selectedCardId;

  bool _isRecurring = false;
  String _selectedFrequency = 'Monthly';
  final bool _isReminderEnabled = false;

  @override
  void initState() {
    super.initState();
    // Pre-select first category if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(categoriesProvider).categories;
      if (categories.isNotEmpty) {
        setState(() => _selectedCategoryId = categories.first.id);
      }

      final cards = ref.read(cardsProvider).cards;
      if (cards.isNotEmpty) {
        final primary =
            cards.where((c) => c.isPrimary).firstOrNull ?? cards.first;
        setState(() => _selectedCardId = primary.id);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (_selectedCardId == null) {
      _showError('Please select a payment source');
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return;
    }

    HapticFeedback.mediumImpact();

    final payment = Payment(
      amount: amount,
      date: AppDateUtils.formatIso(_selectedDate),
      cardId: _selectedCardId!,
      categoryId: _selectedCategoryId!,
      isRecurring: _isRecurring,
      frequency: _isRecurring ? _selectedFrequency : null,
      reminderNotification: _isReminderEnabled,
      note: _descriptionController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    final success = await ref
        .read(paymentsProvider.notifier)
        .addPayment(payment);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction saved!')));

      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      } else {
        ref.read(navigationIndexProvider.notifier).state = 0;
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider).cards;
    final categories = ref.watch(categoriesProvider).categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'New Payment',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else {
              ref.read(navigationIndexProvider.notifier).state = 0;
            }
          },
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(20),
            AmountInput(controller: _amountController),
            const Gap(32),

            _buildSectionTitle('Source'),
            const Gap(16),
            SizedBox(
              height: 180,
              child: cards.isEmpty
                  ? _buildEmptySource()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return CardPreviewWidget(
                          bankName: card.bankName,
                          balance: card.displayBalance.toString(),
                          isCredit: card.isCredit,
                          isSelected: _selectedCardId == card.id,
                          onTap: () =>
                              setState(() => _selectedCardId = card.id),
                        );
                      },
                    ),
            ),

            const Gap(32),
            _buildSectionTitle('What was it for?'),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoTextField(
                controller: _descriptionController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                placeholder: 'e.g. Dinner with friends',
                style: GoogleFonts.montserrat(color: Colors.white),
                placeholderStyle: GoogleFonts.montserrat(color: Colors.white38),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    CupertinoIcons.pencil,
                    color: Colors.white38,
                    size: 20,
                  ),
                ),
              ),
            ),

            const Gap(32),
            _buildSectionTitle('Date'),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DatePickerPill(
                selectedDate: _selectedDate,
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
            ),

            const Gap(32),
            _buildSectionTitle('Category'),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories
                    .map(
                      (cat) => CategoryChip(
                        iconPath: cat.assetPath ?? '',
                        label: cat.label,
                        isSVG: false,
                        isSelected: _selectedCategoryId == cat.id,
                        onTap: () =>
                            setState(() => _selectedCategoryId = cat.id),
                      ),
                    )
                    .toList(),
              ),
            ),

            const Gap(32),
            _buildRecurringSection(),

            const Gap(40),
            _buildSaveButton(),
            const Gap(60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptySource() {
    return Center(
      child: Text(
        'Add a card or cash first',
        style: GoogleFonts.montserrat(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildRecurringSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            RecurringPaymentTile(
              value: _isRecurring,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),
            if (_isRecurring) ...[
              const Gap(8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Frequency',
                      style: GoogleFonts.montserrat(color: Colors.white70),
                    ),
                    FrequencyDropdown(
                      selectedFrequency: _selectedFrequency,
                      onChanged: (freq) =>
                          setState(() => _selectedFrequency = freq),
                    ),
                  ],
                ),
              ),
              const Gap(12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: _saveTransaction,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: AppColors.analyticsGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNeon.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const Gap(12),
              Text(
                'CONFIRM PAYMENT',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
