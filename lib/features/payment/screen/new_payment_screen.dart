import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/errors/failures.dart';
import '../../../core/models/category.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/wishlist_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/notification_service.dart';
import '../../../providers/providers.dart';
import '../../cards/widget/card_preview_widget.dart';
import '../../main_screen.dart';
import '../widgets/add_category_sheet.dart';
import '../widgets/add_subcategory_sheet.dart';
import '../widgets/amount_widget.dart';
import '../widgets/custom_date_widget.dart';
import '../widgets/frequency_dropdown.dart';
import '../widgets/payment_category_section.dart';
import '../widgets/reoccuring_payment_widget.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  final Payment? paymentToEdit;
  final WishlistItem? fromWishlist;
  const NewPaymentScreen({super.key, this.paymentToEdit, this.fromWishlist});

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
  int? _selectedSubcategoryId;
  int? _selectedCardId;

  bool _isRecurring = false;
  String _selectedFrequency = 'Monthly';
  bool _isReminderEnabled = true; // Default to true for scheduled payments
  bool _isExternalTransaction = false;
  bool _showDatePicker = false; // Controls visibility of date picker

  @override
  void initState() {
    super.initState();

    if (widget.paymentToEdit != null) {
      final p = widget.paymentToEdit!;
      _amountController.text = p.amount.toStringAsFixed(2);
      _descriptionController.text = p.note ?? '';
      _selectedDate = AppDateUtils.parseIso(p.date) ?? DateTime.now();
      _selectedCategoryId = p.categoryId;
      _selectedSubcategoryId = p.subcategoryId;
      _selectedCardId = p.cardId;
      _isRecurring = p.isRecurring;
      _selectedFrequency = p.frequency ?? 'Monthly';
      _isReminderEnabled = p.reminderNotification;
      _isExternalTransaction = p.isExternalTransaction;
      // When editing, show date picker since a date was already chosen
      _showDatePicker = true;
    } else if (widget.fromWishlist != null) {
      final item = widget.fromWishlist!;
      if (item.price != null) {
        _amountController.text = item.price!.toStringAsFixed(2);
      }
      _descriptionController.text =
          'Purchased: ${item.title ?? "Wishlist item"}';

      // Pre-select first category and primary card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preSelectDefaults();
        _repairCategoriesIfNeeded();
      });
    } else {
      // Pre-select first category if available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preSelectDefaults();
        _repairCategoriesIfNeeded();
      });
    }
  }

  void _preSelectDefaults() {
    // We do not pre-select category here anymore.
    
    final cards = ref.read(cardsProvider).cards;
    if (cards.isNotEmpty) {
      final primary =
          cards.where((c) => c.isPrimary).firstOrNull ?? cards.first;
      setState(() => _selectedCardId = primary.id);
    }
  }

  Future<void> _repairCategoriesIfNeeded() async {
    final state = ref.read(categoriesProvider);
    if (state.categories.isNotEmpty) return;
    await ref.read(categoriesProvider.notifier).seedDefaultCategories();
  }

  Future<void> _showAddCategorySheet() async {
    final existingCategories = ref.read(categoriesProvider).categories;
    final category = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(existingCategories: existingCategories),
    );

    if (category == null) return;

    final success = await ref
        .read(categoriesProvider.notifier)
        .addCategory(category);

    if (!mounted) return;

    if (!success) {
      _showError(
        ref.read(categoriesProvider).errorMessage ?? 'Failed to add category',
      );
      return;
    }

    final addedCategory = ref
        .read(categoriesProvider)
        .getCategoryByLabel(category.label);
    if (addedCategory != null) {
      setState(() => _selectedCategoryId = addedCategory.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${category.label} added to categories')),
    );
  }

  Future<void> _showAddSubcategorySheet() async {
    if (_selectedCategoryId == null) return;
    
    final category = ref.read(categoriesProvider).getCategoryById(_selectedCategoryId!);
    if (category == null) return;

    final subcategory = await showModalBottomSheet<SubCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSubcategorySheet(categoryId: _selectedCategoryId!, existingSubcategories: category.subcategories),
    );

    if (subcategory == null) return;

    final success = await ref.read(categoriesProvider.notifier).addSubcategory(subcategory);
    
    if (!mounted) return;

    if (!success) {
      _showError(ref.read(categoriesProvider).errorMessage ?? 'Failed to add subcategory');
      return;
    }

    final updatedCat = ref.read(categoriesProvider).getCategoryById(_selectedCategoryId!);
    final addedSub = updatedCat?.subcategories.where((s) => s.label == subcategory.label).firstOrNull;
    if (addedSub != null) {
      setState(() => _selectedSubcategoryId = addedSub.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${subcategory.label} added to subcategories')),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    try {
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

      final isEditing = widget.paymentToEdit != null;
      final payment = Payment(
        id: widget.paymentToEdit?.id,
        amount: amount,
        date: _selectedDate.toIso8601String(), // Use full ISO with time
        cardId: _selectedCardId!,
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _selectedFrequency : null,
        reminderNotification: _isReminderEnabled,
        note: _descriptionController.text.trim(),
        isExternalTransaction: _isExternalTransaction,
        createdAt:
            widget.paymentToEdit?.createdAt ?? DateTime.now().toIso8601String(),
      );

      bool success;
      int? finalId;

      if (isEditing) {
        success = await ref
            .read(paymentsProvider.notifier)
            .updatePayment(payment);
        finalId = payment.id;
        if (!success) {
          _showError('Failed to update transaction');
          return;
        }
      } else {
        // Add and get ID
        final result = await ref
            .read(paymentRepositoryProvider)
            .insertPayment(payment);

        if (result.isLeft()) {
          final failure = result.fold(
            (l) => l,
            (r) => const DatabaseFailure(message: 'Unknown error'),
          );
          _showError('Error: ${failure.message}');
          return;
        }

        success = true;
        finalId = result.getOrElse((_) => -1);

        // Update local state since we used repository directly
        ref.read(paymentsProvider.notifier).loadPayments();
        ref.read(cardsProvider.notifier).loadCards();
        ref.read(analyticsProvider.notifier).refresh();
      }

      if (success && mounted) {
        // Schedule notification if it's in the future
        if (_isReminderEnabled &&
            _selectedDate.isAfter(
              DateTime.now().add(const Duration(seconds: 5)),
            ) &&
            finalId != null) {
          try {
            final category = ref
                .read(categoriesProvider)
                .getCategoryById(_selectedCategoryId!);
            await NotificationService.instance.scheduleNotification(
              id: finalId,
              title: 'Upcoming Payment: ${category?.label ?? "Expense"}',
              body:
                  'Your payment of ${CurrencyUtils.format(amount)} is due now. ${payment.note ?? ""}',
              scheduledDate: _selectedDate,
            );
          } catch (e) {
            print(
              '⚠️ Notification scheduling failed but payment was saved: $e',
            );
            // We don't return here because payment is already saved
          }
        } else if (finalId != null) {
          // Cancel if it was scheduled but now edited to past or disabled
          await NotificationService.instance.cancelNotification(finalId);
        }

        // Finalize wishlist item if originated from wishlist
        if (widget.fromWishlist?.id != null) {
          await ref
              .read(wishlistProvider.notifier)
              .markAsPurchased(widget.fromWishlist!.id!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Transaction updated!' : 'Transaction saved!',
            ),
          ),
        );

        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        } else {
          ref.read(navigationIndexProvider.notifier).state = 0;
        }
      }
    } catch (e, stack) {
      print('❌ Error in _saveTransaction: $e');
      print(stack);
      _showError('Something went wrong. Please try again.');
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
    final categoriesState = ref.watch(categoriesProvider);

    // We do not pre-select category anymore here either.

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.paymentToEdit != null ? 'Edit Payment' : 'New Payment',
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

            _buildSectionTitle('Category'),
            const Gap(16),
            PaymentCategorySection(
              categoriesState: categoriesState,
              selectedCategoryId: _selectedCategoryId,
              selectedSubcategoryId: _selectedSubcategoryId,
              onCategorySelected: (id) => setState(() {
                _selectedCategoryId = id;
                _selectedSubcategoryId = null;
              }),
              onSubcategorySelected: (id) => setState(() => _selectedSubcategoryId = id),
              onAddCategory: _showAddCategorySheet,
              onAddSubcategory: _showAddSubcategorySheet,
              onReloadCategories: _repairCategoriesIfNeeded,
            ),
            const Gap(32),
            _buildSectionTitle('Date'),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _showDatePicker
                  ? DatePickerPill(
                      selectedDate: _selectedDate,
                      onDateChanged: (date) =>
                          setState(() => _selectedDate = date),
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDatePicker = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A1038), Color(0xFF1A0E24)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pick a date',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recurring starts from today',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.calendar,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const Gap(32),
            _buildRecurringSection(),

            const Gap(16),
            _buildExternalTransactionToggle(),

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
                child: Column(
                  children: [
                    Row(
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
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notify me',
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                        CupertinoSwitch(
                          value: _isReminderEnabled,
                          activeColor: AppColors.primaryNeon,
                          onChanged: (val) =>
                              setState(() => _isReminderEnabled = val),
                        ),
                      ],
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

  Widget _buildExternalTransactionToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isExternalTransaction
                ? AppColors.primaryNeon.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'External Transaction',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Record this transaction without\ndeducting from your card balance',
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _isExternalTransaction,
              activeColor: AppColors.primaryNeon,
              onChanged: (val) => setState(() => _isExternalTransaction = val),
            ),
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
                widget.paymentToEdit != null
                    ? 'UPDATE PAYMENT'
                    : 'CONFIRM PAYMENT',
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
