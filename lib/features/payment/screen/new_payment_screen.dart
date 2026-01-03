import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:gooble_goblin/core/app_images.dart';
import 'package:gooble_goblin/core/colors.dart';
import 'package:gooble_goblin/core/models/payment.dart';
import 'package:gooble_goblin/features/home/provider/cards_provider.dart';
import 'package:gooble_goblin/features/payment/widgets/amount_widget.dart';
import 'package:gooble_goblin/features/payment/widgets/custom_chip_widget.dart';
import 'package:gooble_goblin/features/payment/widgets/custom_date_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../cards/widget/card_preview_widget.dart';
import '../../main_screen.dart';
import '../widgets/frequency_dropdown.dart';
import '../widgets/reoccuring_payment_widget.dart';
import '../../category/provider/category_provider.dart';

import 'package:gooble_goblin/core/models/category.dart';
import '../provider/transcation_provider.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  const NewPaymentScreen({super.key});

  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  final TextEditingController _amountController = TextEditingController(text: "0.00");
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  bool _isRecurring = true;
  String _selectedFrequency = 'Monthly';
  bool _isReminderEnabled = false;
  DateTime _reminderDateTime = DateTime.now().add(const Duration(days: 1));
  final TextEditingController descriptionController = TextEditingController();

  void _showDateTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1B29),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Reminder',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none, fontFamily: GoogleFonts.montserrat().fontFamily),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: GoogleFonts.montserrat().fontFamily),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _reminderDateTime,
                onDateTimeChanged: (dateTime) {
                  setState(() {
                    _reminderDateTime = dateTime;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController labelController = TextEditingController();
    String selectedIcon = AppImages.bagShopping;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final List<String> availableIcons = [AppImages.netflix, AppImages.youtube, AppImages.zomato, AppImages.swiggy, AppImages.bagShopping, AppImages.mobile, AppImages.bike, AppImages.amazon, AppImages.cash, AppImages.food, AppImages.utils];

          return CupertinoAlertDialog(
            title: const Text('Add Category'),
            content: Column(
              children: [
                const Gap(16),
                SizedBox(
                  height: 200, // Limit height for the grid
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0, // Ensures 1:1 ratio, which is close to 20x20 visually if sized right
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = availableIcons[index];
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryNeonDark.withOpacity(0.2) : Colors.transparent,
                            border: isSelected ? Border.all(color: AppColors.primaryNeonDark, width: 2) : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(icon, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),
                CupertinoTextField(
                  controller: labelController,
                  placeholder: 'Category Name',
                  style: const TextStyle(color: AppColors.textPrimary), // Actually textPrimary is white, but need to check if it's visible on dialog
                  placeholderStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: const Text('Add', style: TextStyle(color: AppColors.primaryNeonDark)),
                onPressed: () {
                  if (labelController.text.isNotEmpty) {
                    ref.read(categoryProvider.notifier).addCategory(Category(label: labelController.text, icon: selectedIcon));
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final cardsNotifier = ref.read(cardsProvider.notifier);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'New Payment',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(20),
            AmountInput(controller: _amountController),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Payment Method',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(20),
            SizedBox(
              height: 220,
              child: cards.isEmpty
                  ? Center(
                      child: Text('No cards available', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.5))),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return CardPreviewWidget(
                          bankName: card.bankName,
                          balance: card.balance.toString(),
                          isCredit: card.isCredit,
                          isSelected: card.isSelected,
                          onTap: () {
                            cardsNotifier.toggleCardSelection(card.id);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: cards.length,
                    ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Description',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoTextField(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(CupertinoIcons.pen, color: AppColors.textPrimary),
                ),
                controller: descriptionController,
                placeholder: 'Description',
                style: const TextStyle(color: AppColors.textPrimary), // Actually textPrimary is white, but need to check if it's visible on dialog
                placeholderStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF2A1038), Color(0xFF1A0E24)]),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Date',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DatePickerPill(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Category',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
              ),
            ),
            Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  ...categories.map(
                    (cat) => CategoryChip(
                      iconPath: cat.icon,
                      label: cat.label,
                      isSVG: false,
                      isSelected: _selectedCategoryId == cat.id,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                      },
                    ),
                  ),
                  InkWell(
                    onTap: _showAddCategoryDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryNeonDark, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.add_circled_solid, color: AppColors.primaryNeonDark),
                          const Gap(8),
                          Text(
                            'Add',
                            style: TextStyle(color: AppColors.primaryNeonDark, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppColors.textPrimary.withOpacity(0.5), thickness: 2),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: AppColors.textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    RecurringPaymentTile(
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                    ),
                    Gap(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Frequency',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                          ),
                          Gap(20),
                          FrequencyDropdown(
                            selectedFrequency: _selectedFrequency,
                            onChanged: (freq) {
                              setState(() {
                                _selectedFrequency = freq;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Gap(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                              ),
                              Gap(4),
                              Text(
                                'Remind me 1 day before',
                                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w400, fontFamily: GoogleFonts.montserrat().fontFamily),
                              ),
                            ],
                          ),
                          Gap(20),
                          // FrequencyDropdown(),
                          Switch(
                            value: _isReminderEnabled,
                            activeColor: Colors.white,
                            activeTrackColor: AppColors.primaryNeonDark,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.black26,
                            onChanged: (bool value) {
                              setState(() {
                                _isReminderEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isReminderEnabled) ...[
                      Gap(16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: InkWell(
                          onTap: _showDateTimePicker,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.time, color: AppColors.primaryNeon, size: 20),
                                Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reminder Date & Time',
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: GoogleFonts.montserrat().fontFamily),
                                      ),
                                      Gap(4),
                                      Text(
                                        DateFormat('MMM dd, yyyy - hh:mm a').format(_reminderDateTime),
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.montserrat().fontFamily),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.3), size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    Gap(16),
                  ],
                ),
              ),
            ),
            Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                splashColor: AppColors.textPrimary.withOpacity(0.2),
                highlightColor: AppColors.textPrimary.withOpacity(0.2),
                onTap: () async {
                  HapticFeedback.mediumImpact();

                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  final cards = ref.read(cardsProvider);
                  
                  if (cards.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a payment method first')));
                    return;
                  }

                  final selectedCard = cards.firstWhere((c) => c.isSelected, orElse: () => cards.first);

                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                    return;
                  }

                  if (_selectedCategoryId == null && categories.isNotEmpty) {
                    _selectedCategoryId = categories.first.id;
                  }

                  final payment = Payment(amount: amount, date: DateFormat('yyyy-MM-dd').format(_selectedDate), cardId: selectedCard.id ?? 0, categoryId: _selectedCategoryId ?? 0, isRecurring: _isRecurring, frequency: _isRecurring ? _selectedFrequency : null, reminderNotification: _isReminderEnabled, note: descriptionController.text.trim());

                  try {
                    await ref.read(transactionProvider.notifier).addPayment(payment);
                    print('Transaction Saved to DB and Provider updated: ${payment.toMap()}');

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment saved successfully!')));
                      // we need to naviagte to home screen with bottomnavbar index set to 0

                      ref.watch(navigationIndexProvider);
                      ref.read(navigationIndexProvider.notifier).state = 0;

                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
                    }
                  } catch (e) {
                    print('Error saving transaction: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving payment: $e')));
                    }
                  }
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeonDark, // Neon green background
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNeonDark.withOpacity(0.6), // Neon green glow
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'SAVE TRANSACTION',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Gap(60),
          ],
        ),
      ),
    );
  }
}
